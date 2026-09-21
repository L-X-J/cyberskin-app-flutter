// 设备路由的局部依赖装配：只在设备页生命周期内注册对应控制器。
import 'package:get/get.dart';

import '../../features/device/domain/device_repository.dart';
import '../../features/device/presentation/device_home_controller.dart';

/// 设备标签页的路由级依赖绑定。
final class DeviceBinding extends Bindings {
  /// 创建设备路由绑定。
  DeviceBinding();

  @override
  void dependencies() {
    Get.put<DeviceHomeController>(
      DeviceHomeController(Get.find<DeviceRepository>()),
    );
  }
}
