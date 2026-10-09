import 'package:get/get.dart';

import '../../../app/session_controller.dart';
import '../../content/domain/repositories/content_repository.dart';
import '../../device/domain/device_repository.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../device/domain/repositories/user_device_repository.dart';
import '../../training/domain/repositories/training_repository.dart';
import 'home_controller.dart';

/// 注册主页生命周期内的展示层控制器。
final class HomeBinding extends Bindings {
  /// 创建主页绑定。
  HomeBinding();

  @override
  void dependencies() {
    Get.put<HomeController>(
      HomeController(
        Get.find<SessionController>(),
        deviceRepository: Get.find<DeviceRepository>(),
        userDeviceRepository: Get.find<UserDeviceRepository>(),
        deviceCatalogRepository: Get.find<DeviceCatalogRepository>(),
        trainingRepository: Get.find<TrainingRepository>(),
        contentRepository: Get.find<ContentRepository>(),
      ),
    );
  }
}
