// 跨页面节奏执行状态机：串行指令、单调计时、通知驱动及断点恢复。
import 'dart:async';

import '../../../../core/error/app_failure.dart';
import '../../../../core/result/result.dart';
import '../entities/rhythm.dart';
import '../entities/rhythm_program.dart';
import '../repositories/rhythm_device_port.dart';

/// 执行状态不由瞬时设备功率推断，休息段也属于运行中。
enum RhythmPlaybackPhase {
  /// 没有活动节奏。
  idle,

  /// 按当前片段计时执行。
  running,

  /// 已确认暂停，保留剩余时间。
  paused,

  /// 连接、心跳或指令异常，等待用户恢复。
  interrupted,

  /// 所有片段完成且设备已停止。
  completed,
}

/// 一份不可变运行快照；UI 将其拆成独立 Rx 字段。
final class RhythmPlaybackSnapshot {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmPlaybackSnapshot({
    required this.phase,
    this.rhythm,
    this.index = 0,
    this.remainingSeconds = 0,
    this.totalRemainingSeconds = 0,
    this.message,
    this.busy = false,
  });

  /// 执行器确认的当前状态。
  final RhythmPlaybackPhase phase;

  /// 当前会话绑定的不可变节奏快照。
  final Rhythm? rhythm;

  /// 当前片段索引；编辑弹层为空表示新增。
  final int index;

  /// 当前片段剩余秒数，向上取整以免提前显示结束。
  final int remainingSeconds;

  /// 当前和后续片段的总剩余秒数。
  final int totalRemainingSeconds;

  /// 用户可见状态说明；为空时不展示提示。
  final String? message;

  /// 设备操作在途状态，防止界面重复操作。
  final bool busy;
}

/// 执行器生命周期由应用绑定管理，而非详情页管理。
final class RhythmPlayback {
  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmPlayback(this.port) {
    _clock.start();
    _subscription = port.events.listen(_deviceEvent);
    _timer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _scheduleTick(),
    );
  }

  /// 设备及后台服务领域端口。
  final RhythmDevicePort port;
  final Stopwatch _clock = Stopwatch();
  final _changes = StreamController<RhythmPlaybackSnapshot>.broadcast(
    sync: true,
  );
  late final StreamSubscription<RhythmDeviceEvent> _subscription;
  Timer? _timer;

  Future<void> _queue = Future.value();
  RhythmPlaybackPhase _phase = RhythmPlaybackPhase.idle;
  Rhythm? _rhythm;
  RhythmDeviceTarget? _target;
  List<RhythmStep> _steps = const [];
  List<RhythmChannelCapability> _capabilities = const [];
  int _index = 0,
      _remainingMs = 0,
      _startedAt = 0,
      _heartbeatAt = 0,
      _epoch = 0,
      _sessionEpoch = 0;
  bool _busy = false,
      _tickQueued = false,
      _editing = false,
      _disposed = false,
      _backgroundStarted = false;
  String? _message;

  /// 独立于页面生命周期的运行快照广播。
  Stream<RhythmPlaybackSnapshot> get changes => _changes.stream;

  /// 编辑器是否持有暂停锁。
  bool get editing => _editing;

  /// 是否仍有活动节奏需要结束或恢复。
  bool get active => _rhythm != null && _phase != RhythmPlaybackPhase.completed;
  int get _now => _clock.elapsedMilliseconds;
  int get _left =>
      (_remainingMs -
              (_phase == RhythmPlaybackPhase.running ? _now - _startedAt : 0))
          .clamp(0, _remainingMs);

  /// 使用单调时间计算剩余时长的当前快照。
  RhythmPlaybackSnapshot get snapshot => RhythmPlaybackSnapshot(
    phase: _phase,
    rhythm: _rhythm,
    index: _index,
    remainingSeconds: (_left / 1000).ceil(),
    totalRemainingSeconds:
        (_left / 1000).ceil() +
        _steps.skip(_index + 1).fold(0, (n, s) => n + s.durationSec),
    message: _message,
    busy: _busy,
  );

  void _emit() {
    if (!_disposed) _changes.add(snapshot);
  }

  bool get _sameDevice =>
      port.target?.remoteId == _target?.remoteId &&
      port.target?.modelId == _target?.modelId &&
      port.target != null;

  Future<bool> _serial(
    Future<bool> Function() action, {
    bool notifyBusy = true,
  }) {
    final result = Completer<bool>();
    final sessionEpoch = _sessionEpoch;
    _queue = _queue.then((_) async {
      if (_disposed || sessionEpoch != _sessionEpoch) {
        result.complete(false);
        return;
      }
      _busy = true;
      if (notifyBusy) _emit();
      try {
        final ok = await action();
        result.complete(ok && sessionEpoch == _sessionEpoch);
      } catch (error) {
        _freeze();
        _phase = RhythmPlaybackPhase.interrupted;
        if (_sameDevice && _target != null && _capabilities.isNotEmpty) {
          try {
            await port.send(_stopCommand(_capabilities), _target!);
          } catch (_) {}
        }
        _message = error is FormatException
            ? error.message
            : 'Unable to control the device. Please try again.';
        result.complete(false);
      } finally {
        // 中断保留进度，但无需继续持有 Android 通知及唤醒锁。
        if (_phase != RhythmPlaybackPhase.running) await _releaseBackground();
        _busy = false;
        _emit();
      }
    });
    return result.future;
  }

  Future<void> _startBackground() async {
    _backgroundStarted = true;
    await port.startBackground();
  }

  Future<void> _releaseBackground() async {
    if (!_backgroundStarted) return;
    try {
      await port.stopBackground();
      _backgroundStarted = false;
    } catch (_) {
      // 已停止/中断的会话不因平台资源清理失败重新进入运行态。
    }
  }

  /// 校验型号和片段后启动，当前同一节奏只返回现有会话。
  Future<bool> start(
    Rhythm rhythm,
    List<RhythmChannelCapability> capabilities,
  ) => _serial(() async {
    if (_editing) {
      _message = 'Finish editing before starting a rhythm.';
      return false;
    }
    if (active && _rhythm?.id == rhythm.id) return true;

    final target = port.target;
    if (target == null) {
      _message = 'Connect your device to run this rhythm.';
      return false;
    }
    if (target.modelId != rhythm.deviceModelId) {
      _message =
          'This rhythm is for ${rhythm.deviceModelName ?? 'another device'}. Switch device to run.';
      return false;
    }
    if (rhythm.segments.isEmpty || rhythm.segments.length > 30) {
      throw const FormatException('A rhythm needs 1–30 segments.');
    }
    final steps = rhythm.segments.map(RhythmStep.decode).toList();
    for (final step in steps) {
      step.validate(capabilities);
    }
    final sessionEpoch = _sessionEpoch;
    if (active && !await _stop()) return false;
    if (sessionEpoch != _sessionEpoch) return false;
    // 确认停止任何残留手动输出，再建立新会话。
    final stopped = await port.send(_stopCommand(capabilities), target);
    if (stopped.isFailure) {
      _message = stopped.failureOrNull!.message;
      return false;
    }
    if (sessionEpoch != _sessionEpoch ||
        port.target?.remoteId != target.remoteId ||
        port.target?.modelId != target.modelId) {
      return false;
    }
    await _startBackground();
    if (sessionEpoch != _sessionEpoch ||
        port.target?.remoteId != target.remoteId ||
        port.target?.modelId != target.modelId) {
      return false;
    }
    _rhythm = rhythm;
    _target = target;
    _steps = steps;
    _capabilities = capabilities;
    _index = 0;
    _phase = RhythmPlaybackPhase.paused;
    _message = null;
    _remainingMs = steps.first.durationSec * 1000;
    _heartbeatAt = _now;
    return _applyCurrent();
  });

  static String _stopCommand(List<RhythmChannelCapability> caps) =>
      caps.map((c) => '${c.channel.module.key}:s').join('|');

  Future<bool> _applyCurrent() async {
    if (!_sameDevice) {
      _interrupt('Device disconnected. Reconnect the same device to continue.');
      return false;
    }
    final epoch = _epoch;
    for (final command in _steps[_index].commands(_capabilities)) {
      final result = await port.send(command.toString(), _target!);
      if (epoch != _epoch || !_sameDevice) return false;
      if (result.isFailure) {
        _interrupt(result.failureOrNull!.message);
        await port.send(_stopCommand(_capabilities), _target!);
        return false;
      }
    }
    _startedAt = _now;
    _phase = RhythmPlaybackPhase.running;
    _message = null;
    return true;
  }

  void _freeze({int? at}) {
    _remainingMs = at != null && _phase == RhythmPlaybackPhase.running
        ? (_remainingMs - (at - _startedAt).clamp(0, _remainingMs)).clamp(
            0,
            _remainingMs,
          )
        : _left;
    _startedAt = _now;
  }

  void _interrupt(String message, {bool heartbeatLost = false}) {
    _freeze(at: heartbeatLost ? _heartbeatAt : null);
    _epoch++;
    _phase = RhythmPlaybackPhase.interrupted;
    _message = message;
    _emit();
  }

  /// 串行停止运动输出并保留当前片段剩余时间。
  Future<bool> pause() => _serial(_pause);

  Future<bool> _pause() async {
    if (!active || _phase == RhythmPlaybackPhase.paused) return true;
    _freeze();
    _phase = RhythmPlaybackPhase.paused;
    if (!_sameDevice) {
      _interrupt('Device disconnected. Reconnect to continue.');
      return false;
    }

    final result = await port.send(_stopCommand(_capabilities), _target!);
    if (result.isFailure) {
      _interrupt(result.failureOrNull!.message);
      return false;
    }
    await _releaseBackground();
    return true;
  }

  /// 仅恢复到原物理设备，并重新应用当前片段参数。
  Future<bool> resume() => _serial(() async {
    if (_editing || !active) return false;
    if (_phase == RhythmPlaybackPhase.running) return true;
    if (!_sameDevice) {
      _message = 'Reconnect the same device to continue.';
      return false;
    }
    final epoch = _epoch;
    await _startBackground();
    if (epoch != _epoch || !_sameDevice) return false;
    _heartbeatAt = _now;
    if (_remainingMs == 0) {
      if (_index + 1 == _steps.length) return _finish();
      _index++;
      _remainingMs = _steps[_index].durationSec * 1000;
    }
    return _applyCurrent();
  });

  /// 确认停止指令成功后释放会话，不把失败报告为结束。
  Future<bool> stop() => _serial(_stop);
  Future<bool> _stop() async {
    if (_rhythm == null) return true;
    _freeze();
    _phase = RhythmPlaybackPhase.paused;
    _epoch++;
    if (!_sameDevice) {
      _interrupt('Reconnect the device before ending this rhythm.');
      return false;
    }

    final result = await port.send(_stopCommand(_capabilities), _target!);
    if (result.isFailure) {
      _interrupt(result.failureOrNull!.message);
      return false;
    }
    _rhythm = null;
    _steps = const [];
    _phase = RhythmPlaybackPhase.idle;
    _remainingMs = 0;
    _message = null;
    await _releaseBackground();
    return true;
  }

  Future<bool> _finish() async {
    if (!await _stop()) return false;
    _phase = RhythmPlaybackPhase.completed;
    return true;
  }

  /// 编辑锁在异步暂停前获取，防止全局控件在页面跳转间隙恢复设备。
  Future<bool> beginEditing(List<RhythmChannelCapability> capabilities) async {
    if (_editing) return false;
    _editing = true;
    final ok = await _serial(() async {
      if (active) return _pause();

      final target = port.target;
      if (target == null) return true;
      if (capabilities.isEmpty) return false;
      return (await port.send(_stopCommand(capabilities), target)).isSuccess;
    });
    if (!ok) _editing = false;
    _emit();
    return ok;
  }

  /// 释放编辑暂停锁，但不自动恢复设备。
  void finishEditing() {
    _editing = false;
    _emit();
  }

  /// 手动控制需先结束节奏；编辑期间不允许下发其他控制命令。
  Future<Result<void>> runManualCommand(
    Future<Result<void>> Function() command,
  ) async {
    var result = const Result<void>.failure(
      AppFailure(
        code: FailureCode.sessionLost,
        message: 'Unable to take control of the device.',
      ),
    );
    final sessionEpoch = _sessionEpoch;
    await _serial(() async {
      if (_editing) {
        result = const Result.failure(
          AppFailure(
            code: FailureCode.business,
            message: 'Finish rhythm editing before controlling the device.',
          ),
        );
        return false;
      }
      if (active && !await _stop()) {
        result = Result.failure(
          AppFailure(
            code: FailureCode.sessionLost,
            message: _message ?? 'Unable to stop the current rhythm.',
          ),
        );
        return false;
      }
      if (sessionEpoch != _sessionEpoch) return false;
      result = await command();
      return result.isSuccess;
    }, notifyBusy: false);
    return result;
  }

  void _deviceEvent(RhythmDeviceEvent event) {
    if (event.sessionExpired) {
      // 即使首条指令仍在等待，也必须作废旧账号的排队操作。
      _sessionEpoch++;
      if (!active && !_editing && !_busy) return;
      _freeze();
      _epoch++;
      _phase = RhythmPlaybackPhase.interrupted;
      _editing = true;
      unawaited(
        _serial(() async {
          // 账号退出时尽力停止输出，然后清除账号数据；不对新账号续跑。
          try {
            if (_sameDevice && _target != null && _capabilities.isNotEmpty) {
              await port.send(_stopCommand(_capabilities), _target!);
            }
          } finally {
            _rhythm = null;
            _steps = const [];
            _capabilities = const [];
            _target = null;
            _remainingMs = 0;
            _phase = RhythmPlaybackPhase.idle;
            _message = null;
            _editing = false;
            await _releaseBackground();
          }
          return true;
        }),
      );
      return;
    }
    if (!active) return;
    if (!_sameDevice) {
      if (_phase != RhythmPlaybackPhase.interrupted) {
        _interrupt(
          'Device disconnected. Reconnect the same device to continue.',
        );
        unawaited(_serial(() async => false, notifyBusy: false));
      }
      return;
    }
    if (event.heartbeat && event.target?.remoteId == _target?.remoteId) {
      // 先检查缺失间隔，再刷新心跳；不可掩盖系统挂起期间的丢失通知。
      if (_phase == RhythmPlaybackPhase.running && _now - _heartbeatAt > 5000) {
        _interrupt(
          'Device updates stopped. Check the device, then resume.',
          heartbeatLost: true,
        );
        unawaited(
          _serial(() async {
            if (_sameDevice) {
              await port.send(_stopCommand(_capabilities), _target!);
            }
            return false;
          }),
        );
      }
      _heartbeatAt = _now;
      _scheduleTick();
    }
  }

  void _scheduleTick() {
    if (_disposed ||
        _tickQueued ||
        _busy ||
        _phase != RhythmPlaybackPhase.running) {
      return;
    }
    _tickQueued = true;
    unawaited(
      _serial(() async {
        if (_phase != RhythmPlaybackPhase.running) return true;
        if (_now - _heartbeatAt > 5000) {
          _interrupt(
            'Device updates stopped. Check the device, then resume.',
            heartbeatLost: true,
          );
          if (_sameDevice) {
            await port.send(_stopCommand(_capabilities), _target!);
          }
          return false;
        }
        if (_left > 0) return true;
        _remainingMs = 0;
        _phase = RhythmPlaybackPhase.paused;
        if (_index + 1 == _steps.length) return _finish();
        _index++;
        _remainingMs = _steps[_index].durationSec * 1000;
        return _applyCurrent();
      }, notifyBusy: false).whenComplete(() {
        _tickQueued = false;
      }),
    );
  }

  /// 取消订阅并释放本实例拥有的资源。
  Future<void> dispose() async {
    _disposed = true;
    _timer?.cancel();
    await _subscription.cancel();
    await _queue;
    await _releaseBackground();
    await _changes.close();
  }
}
