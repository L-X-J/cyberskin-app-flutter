// 自定义节奏到公共设备播放引擎的兼容门面；执行状态机位于 control/domain。
import 'dart:async';

import '../../../../core/result/result.dart';
import '../../../control/domain/entities/device_program.dart';
import '../../../control/domain/services/common_program_compiler.dart';
import '../../../control/domain/services/device_program_playback.dart';
import '../entities/rhythm.dart';
import '../entities/rhythm_program.dart';
import '../repositories/rhythm_device_port.dart';

/// 节奏页面沿用的播放阶段名称，实际状态由公共引擎维护。
typedef RhythmPlaybackPhase = DeviceProgramPlaybackPhase;

/// 节奏页面使用的不可变快照；公共引擎快照会映射回节奏实体。
final class RhythmPlaybackSnapshot {
  /// 创建节奏快照。
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

  /// 当前节奏；训练等其他来源不会暴露为节奏。
  final Rhythm? rhythm;

  /// 当前片段索引。
  final int index;

  /// 当前片段剩余秒数。
  final int remainingSeconds;

  /// 当前和后续片段的总剩余秒数。
  final int totalRemainingSeconds;

  /// 用户可见状态说明。
  final String? message;

  /// 设备操作是否在途。
  final bool busy;
}

/// 节奏专属适配门面；后续 Training 直接使用 [DeviceProgramPlayback]。
final class RhythmPlayback {
  /// 为测试或独立使用创建并拥有公共引擎。
  RhythmPlayback(RhythmDevicePort port)
    : this._(DeviceProgramPlayback(port), true);

  /// 使用应用级公共引擎，保证节奏和 Training 共用同一个设备会话。
  RhythmPlayback.fromEngine(DeviceProgramPlayback engine)
    : this._(engine, false);

  RhythmPlayback._(this.engine, this._ownsEngine);

  /// 公共设备播放引擎；不依赖 Rhythm 或 Training。
  final DeviceProgramPlayback engine;
  final bool _ownsEngine;
  final _rhythms = Expando<Rhythm>();

  DeviceProgram? get _current {
    final program = engine.snapshot.program;
    return program != null && _rhythms[program] != null ? program : null;
  }

  /// 公共设备端口，供页面读取设备身份。
  RhythmDevicePort get port => engine.port;

  /// 节奏快照流。
  Stream<RhythmPlaybackSnapshot> get changes => engine.changes.map(_snapshot);

  /// 编辑器是否持有暂停锁。
  bool get editing => engine.editing;

  /// 是否有活动节奏。
  bool get active => engine.active && _current != null;

  /// 当前节奏快照。
  RhythmPlaybackSnapshot get snapshot => _snapshot(engine.snapshot);

  RhythmPlaybackSnapshot _snapshot(DeviceProgramPlaybackSnapshot value) {
    final program = value.program;
    final rhythm = program == null ? null : _rhythms[program];
    final otherSource = program != null && rhythm == null;
    return RhythmPlaybackSnapshot(
      phase: otherSource ? RhythmPlaybackPhase.idle : value.phase,
      rhythm: rhythm,
      index: otherSource ? 0 : value.index,
      remainingSeconds: otherSource ? 0 : value.remainingSeconds,
      totalRemainingSeconds: otherSource ? 0 : value.totalRemainingSeconds,
      message: otherSource ? null : value.message,
      busy: value.busy,
    );
  }

  /// 将结构化节奏片段转换为通用业务协议时间序列。
  DeviceProgram _programFor(
    Rhythm rhythm,
    List<RhythmChannelCapability> capabilities,
  ) {
    if (!rhythm.hasCompleteProgram || rhythm.segments.length > 30) {
      throw const FormatException('A rhythm needs 1–30 segments.');
    }
    var cursor = 0;
    for (final segment in rhythm.segments) {
      final cue = segment.program;
      if (cue.startSeconds != cursor ||
          !RhythmStep.isValidDuration(cue.durationSeconds)) {
        throw const FormatException(
          'Rhythm segments must be contiguous from 00:00, each lasting 1–1200 seconds.',
        );
      }
      cursor = cue.endSeconds;
      // 自定义节奏的型号能力仍由业务层核对，播放不再反解通道编辑草稿。
      for (final instruction in cue.command.instructions) {
        final matches = capabilities.where(
          (cap) => cap.channel.module == instruction.module,
        );
        if (matches.isEmpty) {
          throw const FormatException('Unsupported device module.');
        }
        if (instruction.isMode &&
            int.parse(instruction.value) > matches.first.modes.length) {
          throw const FormatException('A saved mode is no longer available.');
        }
      }
    }
    return CommonProgramCompiler.compile(
      source: 'rhythm',
      id: rhythm.id?.toString(),
      name: rhythm.name,
      deviceModelId: rhythm.deviceModelId ?? -1,
      deviceModelName: rhythm.deviceModelName,
      segments: rhythm.segments.map((segment) => segment.program),
      modules: capabilities.map((capability) => capability.channel.module),
    );
  }

  /// 校验型号和片段后启动节奏。
  Future<bool> start(
    Rhythm rhythm,
    List<RhythmChannelCapability> capabilities,
  ) => engine.prepareAndStart(() {
    final program = _programFor(rhythm, capabilities);
    _rhythms[program] = rhythm;
    return program;
  });

  /// 暂停当前节奏，保留剩余时间。
  Future<bool> pause() {
    final program = _current;
    return program == null
        ? Future.value(true)
        : engine.pause(expectedProgram: program);
  }

  /// 恢复当前节奏到原物理设备。
  Future<bool> resume() {
    final program = _current;
    return program == null
        ? Future.value(false)
        : engine.resume(expectedProgram: program);
  }

  /// 停止当前节奏并清理会话。
  Future<bool> stop() {
    final program = _current;
    return program == null
        ? Future.value(true)
        : engine.stop(expectedProgram: program);
  }

  /// 获取编辑锁；没有活动节奏时停止编辑相关通道。
  Future<bool> beginEditing(List<RhythmChannelCapability> capabilities) =>
      engine.beginEditing(
        capabilities.map((capability) => capability.channel.module),
      );

  /// 释放编辑锁但不自动恢复设备。
  void finishEditing() => engine.finishEditing();

  /// 手动控制先结束当前节奏，再执行命令。
  Future<Result<void>> runManualCommand(
    Future<Result<void>> Function() command,
  ) => engine.runManualCommand(command);

  /// 独立实例释放其引擎；注入的应用级引擎不随门面释放。
  Future<void> dispose() async {
    if (_ownsEngine) await engine.dispose();
  }
}
