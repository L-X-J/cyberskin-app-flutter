// 主页展示层聚合模型：冻结设备、型号、训练和广告的可渲染数据。
import '../../content/domain/entities/app_content.dart';
import '../../device/domain/device.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../device/domain/repositories/user_device_repository.dart';
import '../../training/domain/entities/training.dart';

/// 主页 Controller 输出的不可变展示快照。
final class HomeDashboard {
  /// 创建主页展示快照。
  HomeDashboard({
    List<Device> connectedDevices = const <Device>[],
    List<UserDevice> boundDevices = const <UserDevice>[],
    List<DeviceModelSummary> deviceModels = const <DeviceModelSummary>[],
    List<TrainingSummary> trainings = const <TrainingSummary>[],
    List<AppAdvertisement> advertisements = const <AppAdvertisement>[],
  }) : connectedDevices = List<Device>.unmodifiable(connectedDevices),
       boundDevices = List<UserDevice>.unmodifiable(boundDevices),
       deviceModels = List<DeviceModelSummary>.unmodifiable(deviceModels),
       trainings = List<TrainingSummary>.unmodifiable(trainings),
       advertisements = List<AppAdvertisement>.unmodifiable(advertisements);

  /// 当前 BLE 会话可识别的设备摘要。
  final List<Device> connectedDevices;

  /// 当前用户绑定记录；项目约束为最多一条。
  final List<UserDevice> boundDevices;

  /// 后台发布的可添加设备型号。
  final List<DeviceModelSummary> deviceModels;

  /// 后台发布的训练课程摘要。
  final List<TrainingSummary> trainings;

  /// 当前有效的运营广告位。
  final List<AppAdvertisement> advertisements;

  /// 连接状态下优先返回实时 BLE 摘要，否则返回绑定设备摘要。
  Device? get currentDevice =>
      connectedDevices.isEmpty ? null : connectedDevices.first;

  /// 当前绑定设备；多设备数据由 Controller 单独报告为错误，不在此处猜测。
  UserDevice? get boundDevice =>
      boundDevices.length == 1 ? boundDevices.first : null;
}
