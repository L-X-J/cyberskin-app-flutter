// 用户绑定设备的领域模型与远端访问抽象。
import '../../../../core/result/result.dart';

/// 用户已绑定的一台设备。
final class UserDevice {
  /// 创建用户绑定设备。
  const UserDevice({
    this.id,
    this.deviceModelId,
    this.customName,
    this.boundAt,
    this.modelName,
    this.iconUrl,
    this.hardwareUid,
  });

  /// 绑定记录主键。
  final int? id;

  /// 对应的设备型号主键。
  final int? deviceModelId;

  /// 用户自定义名称；未设置时为 `null`。
  final String? customName;

  /// 绑定时间。
  final DateTime? boundAt;

  /// 设备型号展示名称。
  final String? modelName;

  /// 型号图标地址。
  final String? iconUrl;

  /// 设备硬件标识。
  final String? hardwareUid;
}

/// 新增用户设备绑定的输入值对象。
final class UserDeviceBindRequest {
  /// 创建绑定请求。
  const UserDeviceBindRequest({
    required this.deviceModelId,
    required this.deviceUid,
    this.customName,
  });

  /// 要绑定的设备型号主键。
  final int deviceModelId;

  /// BLE 设备硬件标识，对应 remoteId（服务端必填）。
  final String deviceUid;

  /// 可选自定义设备名称。
  final String? customName;
}

/// 用户绑定设备的领域访问入口。
abstract interface class UserDeviceRepository {
  /// 获取当前用户的设备绑定记录。
  Future<Result<List<UserDevice>>> listUserDevices();

  /// 创建一条用户设备绑定记录。
  Future<Result<UserDevice>> bind(UserDeviceBindRequest request);

  /// 更新绑定设备的显示名称；空字符串表示清除自定义名称。
  Future<Result<void>> rename(int id, String customName);

  /// 解绑一条用户设备记录。
  Future<Result<void>> unbind(int id);
}
