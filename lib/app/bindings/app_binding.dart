// 应用级依赖装配：注册全局 Repository、API 客户端和跨页面控制器。
import 'package:get/get.dart';

import '../../core/network/app_api_client.dart';
import '../../features/control/presentation/control_session_controller.dart';
import '../../features/device/domain/device_repository.dart';

/// 注册应用生命周期内共享的 Repository、API 客户端和控制器。
final class AppBinding extends Bindings {
  /// 使用应用入口选择的设备 Repository 创建绑定。
  AppBinding({required this.deviceRepository});

  /// 当前运行环境使用的设备 Repository 具体实现。
  final DeviceRepository deviceRepository;

  @override
  void dependencies() {
    Get.put<DeviceRepository>(deviceRepository, permanent: true);
    Get.put<AppApiClient>(AppApiClient(), permanent: true);
    Get.put<ControlSessionController>(
      ControlSessionController(),
      permanent: true,
    );
  }
}
