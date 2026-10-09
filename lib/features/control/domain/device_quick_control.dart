// 将连接状态与运行会话映射为快捷控制状态，不包含 Flutter 或导航依赖。
import '../../device/domain/device.dart';
import 'device_session.dart';

/// 快捷控制的四个主状态及连接中过渡态。
enum DeviceQuickControlState {
  /// 无可控制的连接；残留会话状态不能覆盖断连。
  disconnected,

  /// 连接未完成，不能重复提交操作。
  connecting,

  /// 当前会话运行中。
  running,

  /// 会话运行中且设备上报低电量。
  runningLowBattery,

  /// 已暂停，或设备已连接但尚未开始会话。
  paused,
}

/// 连接状态优先于运行状态；低电量仅覆盖运行态，不推断电量阈值。
DeviceQuickControlState resolveQuickControlState(
  DeviceConnectionStatus connection,
  DeviceSessionState session,
) {
  if (connection == DeviceConnectionStatus.connecting) {
    return DeviceQuickControlState.connecting;
  }
  if (connection != DeviceConnectionStatus.connected &&
      connection != DeviceConnectionStatus.lowBattery) {
    return DeviceQuickControlState.disconnected;
  }
  return switch (session) {
    DeviceSessionState.connecting => DeviceQuickControlState.connecting,
    DeviceSessionState.running =>
      connection == DeviceConnectionStatus.lowBattery
          ? DeviceQuickControlState.runningLowBattery
          : DeviceQuickControlState.running,
    DeviceSessionState.paused ||
    DeviceSessionState.idle => DeviceQuickControlState.paused,
  };
}
