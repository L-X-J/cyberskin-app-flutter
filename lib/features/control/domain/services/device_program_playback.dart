// 公共设备播放状态机：统一串行发令、单调计时、编辑互斥和异常恢复。
import 'dart:async';

import '../../../../core/error/app_failure.dart';
import '../../../../core/protocol/common_business_command.dart';
import '../../../../core/result/result.dart';
import '../entities/device_program.dart';
import '../repositories/device_playback_port.dart';

/// 执行状态不由瞬时设备功率推断，休息段也属于运行中。
enum DeviceProgramPlaybackPhase {
  /// 没有活动序列。
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
final class DeviceProgramPlaybackSnapshot {
  /// 创建实例；依赖及初始状态由调用方提供。
  const DeviceProgramPlaybackSnapshot({
    required this.phase,
    this.program,
    this.index = 0,
    this.remainingSeconds = 0,
    this.totalRemainingSeconds = 0,
    this.message,
    this.busy = false,
  });

  /// 执行器确认的当前状态。
  final DeviceProgramPlaybackPhase phase;

  /// 当前会话绑定的不可变协议序列。
  final DeviceProgram? program;

  /// 当前片段的零基索引。
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
final class DeviceProgramPlayback {
  /// 创建实例；依赖及初始状态由调用方提供。
  DeviceProgramPlayback(this.port) {
    _clock.start();
    _subscription = port.events.listen(_deviceEvent);
    _timer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _scheduleTick(),
    );
  }

  /// 设备及后台服务领域端口。
  final DevicePlaybackPort port;
  final Stopwatch _clock = Stopwatch();
  final _changes = StreamController<DeviceProgramPlaybackSnapshot>.broadcast(
    sync: true,
  );
  late final StreamSubscription<DevicePlaybackEvent> _subscription;
  Timer? _timer;

  Future<void> _queue = Future.value();
  DeviceProgramPlaybackPhase _phase = DeviceProgramPlaybackPhase.idle;
  DeviceProgram? _program;
  DevicePlaybackTarget? _target;
  List<DeviceProgramStep> get _steps => _program?.steps ?? const [];
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
  Stream<DeviceProgramPlaybackSnapshot> get changes => _changes.stream;

  /// 编辑器是否持有暂停锁。
  bool get editing => _editing;

  /// 是否仍有活动序列需要结束或恢复。
  bool get active =>
      _program != null && _phase != DeviceProgramPlaybackPhase.completed;
  int get _now => _clock.elapsedMilliseconds;
  int get _left =>
      (_remainingMs -
              (_phase == DeviceProgramPlaybackPhase.running
                  ? _now - _startedAt
                  : 0))
          .clamp(0, _remainingMs);

  /// 使用单调时间计算剩余时长的当前快照。
  DeviceProgramPlaybackSnapshot get snapshot => DeviceProgramPlaybackSnapshot(
    phase: _phase,
    program: _program,
    index: _index,
    remainingSeconds: (_left / 1000).ceil(),
    totalRemainingSeconds:
        ((_left +
                    _steps
                        .skip(_index + 1)
                        .fold(0, (n, s) => n + s.duration.inMilliseconds)) /
                1000)
            .ceil(),
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
        _phase = DeviceProgramPlaybackPhase.interrupted;
        if (_sameDevice && _target != null && _program != null) {
          try {
            await port.send(_program!.stopCommand.toString(), _target!);
          } catch (_) {}
        }
        _message = error is FormatException
            ? error.message
            : 'Unable to control the device. Please try again.';
        result.complete(false);
      } finally {
        // 中断保留进度，但无需继续持有 Android 通知及唤醒锁。
        if (_phase != DeviceProgramPlaybackPhase.running) {
          await _releaseBackground();
        }
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

  /// 启动业务层已转换完成的时间序列，所有来源共享一条命令队列。
  Future<bool> start(DeviceProgram program) => prepareAndStart(() => program);

  /// 在队列内完成业务转换；无效输入不会停止正在播放的其他会话。
  Future<bool> prepareAndStart(
    DeviceProgram Function() prepare,
  ) => _serial(() async {
    if (_editing) {
      _message = 'Finish editing before starting playback.';
      return false;
    }
    final DeviceProgram program;
    try {
      program = prepare();
    } on FormatException catch (error) {
      _message = error.message;
      return false;
    }
    if (active && _program!.matches(program)) return true;
    final target = port.target;
    if (target == null) {
      _message = 'Connect your device to start playback.';
      return false;
    }
    if (target.modelId != program.deviceModelId) {
      _message =
          'This program is for ${program.deviceModelName ?? 'another device'}. Switch device to run.';
      return false;
    }
    final sessionEpoch = _sessionEpoch;
    if (active && !await _stop()) return false;
    if (sessionEpoch != _sessionEpoch) return false;
    // 新来源接管前停止其拥有的通道，避免继承手动输出。
    final stopped = await port.send(program.stopCommand.toString(), target);
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
    _program = program;
    _target = target;
    _index = 0;
    _phase = DeviceProgramPlaybackPhase.paused;
    _message = null;
    _remainingMs = _steps.first.duration.inMilliseconds;
    _heartbeatAt = _now;
    return _applyCurrent();
  });

  Future<bool> _applyCurrent({bool resuming = false}) async {
    if (!_sameDevice) {
      _interrupt('Device disconnected. Reconnect the same device to continue.');
      return false;
    }
    final epoch = _epoch;
    final step = _steps[_index];
    for (final command in resuming ? step.resumeCommands : step.commands) {
      final result = await port.send(command.toString(), _target!);
      if (epoch != _epoch || !_sameDevice) return false;
      if (result.isFailure) {
        _interrupt(result.failureOrNull!.message);
        await port.send(_program!.stopCommand.toString(), _target!);
        return false;
      }
    }
    _startedAt = _now;
    _phase = DeviceProgramPlaybackPhase.running;
    _message = null;
    return true;
  }

  void _freeze({int? at}) {
    _remainingMs = at != null && _phase == DeviceProgramPlaybackPhase.running
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
    _phase = DeviceProgramPlaybackPhase.interrupted;
    _message = message;
    _emit();
  }

  /// 串行停止输出并保留进度；expectedProgram 防止旧页面操作后来启动的会话。
  Future<bool> pause({DeviceProgram? expectedProgram}) => _serial(() async {
    if (expectedProgram != null && !identical(_program, expectedProgram)) {
      return false;
    }
    return _pause();
  });

  Future<bool> _pause() async {
    if (!active || _phase == DeviceProgramPlaybackPhase.paused) return true;
    _freeze();
    _phase = DeviceProgramPlaybackPhase.paused;
    if (!_sameDevice) {
      _interrupt('Device disconnected. Reconnect to continue.');
      return false;
    }

    final result = await port.send(_program!.stopCommand.toString(), _target!);
    if (result.isFailure) {
      _interrupt(result.failureOrNull!.message);
      return false;
    }
    await _releaseBackground();
    return true;
  }

  /// 仅恢复到原物理设备；重发恢复指令，不重复进入片段时的相对增减。
  Future<bool> resume({DeviceProgram? expectedProgram}) => _serial(() async {
    if (expectedProgram != null && !identical(_program, expectedProgram)) {
      return false;
    }
    if (_editing || !active) return false;
    if (_phase == DeviceProgramPlaybackPhase.running) return true;
    if (!_sameDevice) {
      _message = 'Reconnect the same device to continue.';
      return false;
    }
    if (_remainingMs > 0 && !_steps[_index].resumable) {
      _message = 'This relative command cannot safely resume. End playback and restart.';
      return false;
    }
    final epoch = _epoch;
    await _startBackground();
    if (epoch != _epoch || !_sameDevice) return false;
    _heartbeatAt = _now;
    if (_remainingMs == 0) {
      if (_index + 1 == _steps.length) return _finish();
      _index++;
      _remainingMs = _steps[_index].duration.inMilliseconds;
      return _applyCurrent();
    }
    return _applyCurrent(resuming: true);
  });

  /// 确认停止指令成功后释放会话，不把失败报告为结束。
  Future<bool> stop({DeviceProgram? expectedProgram}) => _serial(() async {
    if (expectedProgram != null && !identical(_program, expectedProgram)) {
      return false;
    }
    return _stop();
  });
  Future<bool> _stop() async {
    if (_program == null) return true;
    _freeze();
    _phase = DeviceProgramPlaybackPhase.paused;
    _epoch++;
    if (!_sameDevice) {
      _interrupt('Reconnect the device before ending playback.');
      return false;
    }

    final result = await port.send(_program!.stopCommand.toString(), _target!);
    if (result.isFailure) {
      _interrupt(result.failureOrNull!.message);
      return false;
    }
    _program = null;
    _phase = DeviceProgramPlaybackPhase.idle;
    _remainingMs = 0;
    _message = null;
    await _releaseBackground();
    return true;
  }

  Future<bool> _finish() async {
    if (!await _stop()) return false;
    _phase = DeviceProgramPlaybackPhase.completed;
    return true;
  }

  /// 编辑锁在异步暂停前获取，防止全局控件在页面跳转间隙恢复设备。
  Future<bool> beginEditing(Iterable<CommonModule> modules) async {
    final ownedModules = Set<CommonModule>.unmodifiable(modules);
    if (_editing) return false;
    _editing = true;
    final ok = await _serial(() async {
      if (active) return _pause();

      final target = port.target;
      if (target == null) return true;
      if (ownedModules.isEmpty) return false;
      return (await port.send(
        DeviceProgram.stopFor(ownedModules).toString(),
        target,
      )).isSuccess;
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

  /// 手动控制需先结束当前序列；编辑期间不允许下发其他控制命令。
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
            message: 'Finish editing before controlling the device.',
          ),
        );
        return false;
      }
      if (active && !await _stop()) {
        result = Result.failure(
          AppFailure(
            code: FailureCode.sessionLost,
            message: _message ?? 'Unable to stop the current program.',
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

  void _deviceEvent(DevicePlaybackEvent event) {
    if (event.sessionExpired) {
      // 即使首条指令仍在等待，也必须作废旧账号的排队操作。
      _sessionEpoch++;
      if (!active && !_editing && !_busy) return;
      _freeze();
      _epoch++;
      _phase = DeviceProgramPlaybackPhase.interrupted;
      _editing = true;
      unawaited(
        _serial(() async {
          // 账号退出时尽力停止输出，然后清除账号数据；不对新账号续跑。
          try {
            if (_sameDevice && _target != null && _program != null) {
              await port.send(_program!.stopCommand.toString(), _target!);
            }
          } finally {
            _program = null;
            _target = null;
            _remainingMs = 0;
            _phase = DeviceProgramPlaybackPhase.idle;
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
      if (_phase != DeviceProgramPlaybackPhase.interrupted) {
        _interrupt(
          'Device disconnected. Reconnect the same device to continue.',
        );
        unawaited(_serial(() async => false, notifyBusy: false));
      }
      return;
    }
    if (event.heartbeat && event.target?.remoteId == _target?.remoteId) {
      // 先检查缺失间隔，再刷新心跳；不可掩盖系统挂起期间的丢失通知。
      if (_phase == DeviceProgramPlaybackPhase.running &&
          _now - _heartbeatAt > 5000) {
        _interrupt(
          'Device updates stopped. Check the device, then resume.',
          heartbeatLost: true,
        );
        _stopInterruptedProgram();
      }
      _heartbeatAt = _now;
      _scheduleTick();
    }
  }

  // 心跳异常后的停止排队时绑定原会话，不能停止排在它前面新启动的序列。
  void _stopInterruptedProgram() {
    final program = _program;
    final target = _target;
    final epoch = _epoch;
    unawaited(
      _serial(() async {
        if (program != null &&
            target != null &&
            epoch == _epoch &&
            identical(program, _program) &&
            _sameDevice &&
            _phase == DeviceProgramPlaybackPhase.interrupted) {
          await port.send(program.stopCommand.toString(), target);
        }
        return false;
      }),
    );
  }

  void _scheduleTick() {
    if (_disposed ||
        _tickQueued ||
        _busy ||
        _phase != DeviceProgramPlaybackPhase.running) {
      return;
    }
    _tickQueued = true;
    unawaited(
      _serial(() async {
        if (_phase != DeviceProgramPlaybackPhase.running) return true;
        if (_now - _heartbeatAt > 5000) {
          _interrupt(
            'Device updates stopped. Check the device, then resume.',
            heartbeatLost: true,
          );
          if (_sameDevice) {
            await port.send(_program!.stopCommand.toString(), _target!);
          }
          return false;
        }
        if (_left > 0) return true;
        _remainingMs = 0;
        _phase = DeviceProgramPlaybackPhase.paused;
        if (_index + 1 == _steps.length) return _finish();
        _index++;
        _remainingMs = _steps[_index].duration.inMilliseconds;
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
