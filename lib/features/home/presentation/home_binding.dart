// 首页、设备标签及视频的局部依赖绑定，内容经 HomeRepository 聚合。
import 'package:get/get.dart';

import '../../../app/session_controller.dart';
import '../../../core/storage/seen_ad_store.dart';
import '../../ad/domain/repositories/ad_repository.dart';
import '../../control/domain/device_command_repository.dart';
import '../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../device/domain/device_repository.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../device/domain/repositories/user_device_repository.dart';
import '../../device/presentation/device_home_controller.dart';
import '../../video/domain/repositories/local_video_repository.dart';
import '../../video/domain/repositories/video_repository.dart';
import '../../video/presentation/video_controller.dart';
import '../domain/repositories/home_repository.dart';
import 'home_controller.dart';

/// 注册主页生命周期内的展示层控制器。
final class HomeBinding extends Bindings {
  /// 创建主页绑定。
  HomeBinding();

  @override
  void dependencies() {
    // offAllNamed 导航时 GetX 先执行新路由的 binding、再清理旧路由。
    // 若用 isRegistered 守卫跳过创建，旧路由清理时会把这些控制器一并删掉，
    // 新路由就找不到它们了。因此必须强制重建，确保实例归属于当前路由。
    Get.delete<VideoController>(force: true);
    Get.put<VideoController>(
      VideoController(
        Get.find<VideoRepository>(),
        localRepository: Get.isRegistered<LocalVideoRepository>()
            ? Get.find<LocalVideoRepository>()
            : null,
      ),
    );

    Get.delete<DeviceHomeController>(force: true);
    Get.put<DeviceHomeController>(
      DeviceHomeController(
        Get.find<DeviceRepository>(),
        Get.find<CyberskinBleRuntimeCoordinator>(),
      ),
    );

    Get.put<HomeController>(
      HomeController(
        Get.find<SessionController>(),
        deviceRepository: Get.find<DeviceRepository>(),
        userDeviceRepository: Get.find<UserDeviceRepository>(),
        deviceCatalogRepository: Get.find<DeviceCatalogRepository>(),
        homeRepository: Get.find<HomeRepository>(),
        bleCoordinator: Get.find<CyberskinBleRuntimeCoordinator>(),
        deviceCommandRepository: Get.find<DeviceCommandRepository>(),
        adRepository: Get.find<AdRepository>(),
        seenAdStore: Get.find<SeenAdStore>(),
      ),
    );
  }
}
