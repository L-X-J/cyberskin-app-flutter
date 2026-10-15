// 设备领域模型与连接状态定义。
import 'device_capability.dart';

/// 产品需求定义的设备连接与会话状态。
enum DeviceConnectionStatus {
  /// 当前不存在活动连接。
  disconnected,

  /// 手动连接请求正在执行。
  connecting,

  /// 设备已连接，可以进行控制。
  connected,

  /// 扫描结束但未发现目标设备。
  notFound,

  /// 连接尝试失败或超时。
  connectionFailed,

  /// 设备上报低电量状态。
  lowBattery,

  /// 宿主设备的蓝牙未开启。
  bluetoothOff,

  /// 缺少连接设备所需的蓝牙权限。
  bluetoothPermissionMissing,

  /// 活动会话丢失了连接。
  sessionLost,
}

/// 为设备连接状态提供可直接展示的界面文案。
extension DeviceConnectionStatusLabel on DeviceConnectionStatus {
  /// 产品定义的当前状态用户指引。
  String get guidance => switch (this) {
    DeviceConnectionStatus.disconnected => 'Tap to connect',
    DeviceConnectionStatus.connecting => 'Keep the device nearby',
    DeviceConnectionStatus.connected => 'Ready to control',
    DeviceConnectionStatus.notFound => 'Check that the device is powered on',
    DeviceConnectionStatus.connectionFailed => 'Try connecting again',
    DeviceConnectionStatus.lowBattery => 'Please charge the device',
    DeviceConnectionStatus.bluetoothOff => 'Turn on Bluetooth in Settings',
    DeviceConnectionStatus.bluetoothPermissionMissing =>
      'Bluetooth permission is required',
    DeviceConnectionStatus.sessionLost => 'Reconnect to continue',
  };
}

/// 设备 Repository 返回的不可变设备摘要。
final class Device {
  /// 创建设备摘要，并校验电量范围。
  const Device({
    required this.id,
    required this.model,
    required this.name,
    required this.status,
    required this.capabilities,
    this.batteryPercent,
    this.cardColor,
    this.tags,
  }) : assert(
         batteryPercent == null ||
             (batteryPercent >= 0 && batteryPercent <= 100),
       );

  /// 后端或设备提供的稳定标识。
  final String id;

  /// 用于解析能力模型的硬件型号键。
  final String model;

  /// 面向用户展示的设备名称。
  final String name;

  /// 当前连接状态。
  final DeviceConnectionStatus status;

  /// 后台下发的设备能力模型。
  final DeviceCapabilities capabilities;

  /// 最近一次获知的电量百分比。
  final int? batteryPercent;

  /// 卡片色值（如 #FF5733）；未配置时为 null。
  final String? cardColor;

  /// 标签，多个用英文逗号拼接；未配置时为 null。
  final String? tags;
}
