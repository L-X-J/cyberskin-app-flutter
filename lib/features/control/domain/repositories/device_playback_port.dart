// 通用序列播放所需的设备及后台能力边界；展示层不接触 BLE 协调器。
import '../../../../core/result/result.dart';

/// 一次运行绑定的物理设备身份，恢复时必须同时匹配型号和地址。
final class DevicePlaybackTarget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const DevicePlaybackTarget({
    required this.modelId,
    required this.remoteId,
    required this.name,
  });

  /// 后台设备型号主键。
  final int modelId;

  /// BLE 物理设备地址，防止恢复到另一台同型号设备。
  final String remoteId;

  /// 用户可见名称。
  final String name;
}

/// 设备连接、通知心跳或账号失效事件。
final class DevicePlaybackEvent {
  /// 创建实例；依赖及初始状态由调用方提供。
  const DevicePlaybackEvent(
    this.target, {
    this.heartbeat = false,
    this.sessionExpired = false,
  });

  /// 当前可用设备；断开时为空。
  final DevicePlaybackTarget? target;

  /// 每次有效状态上报为 true，即使状态数值没有改变。
  final bool heartbeat;

  /// 账号失效时通知执行器终止会话。
  final bool sessionExpired;
}

/// 播放领域与 BLE、平台后台服务之间的边界。
abstract interface class DevicePlaybackPort {
  /// 当前可用设备；断开时为空。
  DevicePlaybackTarget? get target;

  /// 不去重的设备事件流。
  Stream<DevicePlaybackEvent> get events;

  /// 向指定物理设备发送一条语义指令并返回实际结果。
  Future<Result<void>> send(String command, DevicePlaybackTarget target);

  /// 运行开始前申请平台后台执行资源。
  Future<void> startBackground();

  /// 会话结束后释放后台执行资源。
  Future<void> stopBackground();
}
