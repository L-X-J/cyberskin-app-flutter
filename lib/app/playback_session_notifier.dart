// 将公共播放快照桥接到 iOS Live Activity 和 Android MediaStyle 通知。
//
// iOS：通过 cyberskin/now_playing 驱动 ActivityKit（不需要音频会话，支持灵动岛）。
// Android：向已运行的 RhythmForegroundService 推送标题和进度，升级为 MediaStyle 通知。
// 本类只订阅快照并调用平台通道，不持有任何设备或业务状态。
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../features/control/domain/services/device_program_playback.dart';

/// 平台 Now Playing / Live Activity 的应用级驱动器；由 AppBinding 创建并持有。
final class PlaybackSessionNotifier {
  /// 创建实例；调用 [start] 后才开始订阅。
  PlaybackSessionNotifier(this._playback);

  static const _channel = MethodChannel('cyberskin/now_playing');

  final DeviceProgramPlayback _playback;
  StreamSubscription<DeviceProgramPlaybackSnapshot>? _sub;

  /// 已发送给平台层的上一帧关键字段，用于过滤冗余调用。
  _SentState? _last;

  /// 开始订阅快照流；幂等，重复调用无副作用。
  void start() {
    _sub ??= _playback.changes.listen(_onSnapshot);
  }

  Future<void> _onSnapshot(DeviceProgramPlaybackSnapshot snapshot) async {
    if (kIsWeb) return;

    final isActive =
        snapshot.phase != DeviceProgramPlaybackPhase.idle &&
        snapshot.phase != DeviceProgramPlaybackPhase.completed;

    // 会话结束 → 通知平台层关闭 Live Activity / 停止 MediaStyle。
    if (!isActive) {
      if (_last != null) {
        _last = null;
        try {
          await _channel.invokeMethod<void>('end');
        } catch (_) {}
      }
      return;
    }

    final program = snapshot.program;
    final title = program?.name ?? 'Cyberskin';
    final totalSeconds =
        program?.steps.fold(0, (n, s) => n + s.duration.inSeconds) ?? 0;
    final remaining = snapshot.totalRemainingSeconds;
    final phase = _phaseKey(snapshot.phase);

    final next = _SentState(
      title: title,
      totalSeconds: totalSeconds,
      remainingSeconds: remaining,
      phase: phase,
    );

    // 首次激活 → 发送 start；后续只在有实质变化时发送 update。
    if (_last == null) {
      _last = next;
      try {
        await _channel.invokeMethod<void>('start', {
          'title': title,
          'source': program?.source ?? '',
          'totalSeconds': totalSeconds,
          'remainingSeconds': remaining,
          'phase': phase,
        });
      } catch (_) {}
    } else if (next != _last) {
      _last = next;
      try {
        await _channel.invokeMethod<void>('update', {
          'title': title,
          'totalSeconds': totalSeconds,
          'remainingSeconds': remaining,
          'phase': phase,
        });
      } catch (_) {}
    }
  }

  static String _phaseKey(DeviceProgramPlaybackPhase phase) => switch (phase) {
    DeviceProgramPlaybackPhase.running => 'running',
    DeviceProgramPlaybackPhase.paused => 'paused',
    DeviceProgramPlaybackPhase.interrupted => 'interrupted',
    DeviceProgramPlaybackPhase.completed => 'completed',
    DeviceProgramPlaybackPhase.idle => 'idle',
  };

  /// 取消订阅，不影响正在运行的 Live Activity（由平台层跟随服务生命周期）。
  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}

/// 上一次已发送到平台层的状态快照，用于去重。
final class _SentState {
  const _SentState({
    required this.title,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.phase,
  });

  final String title;
  final int totalSeconds;
  final int remainingSeconds;
  final String phase;

  @override
  bool operator ==(Object other) =>
      other is _SentState &&
      title == other.title &&
      totalSeconds == other.totalSeconds &&
      remainingSeconds == other.remainingSeconds &&
      phase == other.phase;

  @override
  int get hashCode => Object.hash(title, totalSeconds, remainingSeconds, phase);
}
