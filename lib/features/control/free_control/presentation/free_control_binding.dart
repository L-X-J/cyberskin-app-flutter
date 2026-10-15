// 自由控制页面依赖绑定。

import 'package:get/get.dart';

import '../../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import '../../presentation/control_session_controller.dart';
import 'free_control_controller.dart';

final class FreeControlBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FreeControlController>(
      () => FreeControlController(
        catalogRepository: Get.find<DeviceCatalogRepository>(),
        bleCoordinator: Get.find<CyberskinBleRuntimeCoordinator>(),
        sessionController: Get.find<ControlSessionController>(),
      ),
    );
  }
}
