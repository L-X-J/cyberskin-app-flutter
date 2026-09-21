/// 全局设备快捷控制条展示的运行时会话状态。
enum DeviceSessionState {
  /// 当前没有活动设备会话。
  idle,

  /// 正在建立 BLE 连接。
  connecting,

  /// 控制、节奏或训练会话正在运行。
  running,

  /// 活动会话已暂停，可以继续执行。
  paused,
}

/// [DeviceSessionState] 的界面文案映射。
extension DeviceSessionStateLabel on DeviceSessionState {
  /// 全局控制条的主状态文案。
  String get label => switch (this) {
    DeviceSessionState.idle => 'No active session',
    DeviceSessionState.connecting => 'Connecting',
    DeviceSessionState.running => 'Running',
    DeviceSessionState.paused => 'Paused',
  };

  /// 全局控制条的辅助操作提示。
  String get subtitle => switch (this) {
    DeviceSessionState.idle => 'Connect a device to begin',
    DeviceSessionState.connecting => 'Keep the device nearby',
    DeviceSessionState.running => 'Tap to pause',
    DeviceSessionState.paused => 'Tap to resume',
  };
}
