// 主页页面：按设备连接状态渲染可复用的设备、内容和广告卡片。
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_flower_loading_indicator.dart';
import '../../../app/widgets/app_glass_surfaces.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layered_gradient_style.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_layered_gradient_card.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';
import '../../content/domain/entities/app_content.dart';
import '../../device/domain/device.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../training/domain/entities/training.dart';
import '../../video/domain/repositories/video_repository.dart';
import '../../video/presentation/video_controller.dart';
import '../../video/presentation/video_page.dart';
import 'home_controller.dart';
import 'home_dashboard.dart';

part 'home_disconnected_view.dart';
part 'home_connected_view.dart';

/// 匿名可浏览的应用主页。
final class HomePage extends GetView<HomeController> {
  /// 创建主页。
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController();
    return Obx(() {
      final status = controller.deviceStatus.value;
      final connected =
          status == DeviceConnectionStatus.connected ||
          status == DeviceConnectionStatus.lowBattery;
      return AppScaffold(
        currentTab: controller.selectedTab.value,
        showBottomNavigation: connected,
        onTabSelected: controller.selectTab,
        appBar: const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        ),
        body: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: controller.selectedTab.value == AppTab.video
              ? VideoTabContent(
                  key: const ValueKey('home-video-content'),
                  controller: videoController,
                )
              : _HomeBody(
                  key: const ValueKey('home-device-content'),
                  status: status,
                  isAuthenticated: controller.isAuthenticated,
                  dashboard: controller.dashboard.value,
                  isLoading: controller.isLoading.value,
                  failureMessage: controller.failure.value?.message,
                  onPrimaryAction: controller.requestConnection,
                  onDeviceModelDetails: controller.openDeviceModelDetails,
                  onDeviceDetails: controller.openDevice,
                  onDeviceManual: () => controller.openDeviceManual(
                    controller.dashboard.value.boundDevice?.deviceModelId,
                    productName:
                        controller.dashboard.value.currentDevice?.name ??
                        controller.dashboard.value.boundDevice?.customName ??
                        controller.dashboard.value.boundDevice?.modelName,
                  ),
                  onLogin: controller.openLogin,
                  onProfile: controller.openProfile,
                  onReload: controller.reload,
                ),
        ),
      );
    });
  }

  /// 主页测试可只注册 HomeController；此时以无远端 Repository 的视频壳层补齐展示依赖。
  VideoController _videoController() {
    if (Get.isRegistered<VideoController>()) {
      return Get.find<VideoController>();
    }
    final repository = Get.isRegistered<VideoRepository>()
        ? Get.find<VideoRepository>()
        : null;
    return Get.put<VideoController>(VideoController(repository));
  }
}

/// 根据设备连接状态渲染主页主体，壳层只订阅导航所需的状态。
final class _HomeBody extends StatelessWidget {
  const _HomeBody({
    super.key,
    required this.status,
    required this.isAuthenticated,
    required this.dashboard,
    required this.isLoading,
    required this.failureMessage,
    required this.onPrimaryAction,
    required this.onDeviceModelDetails,
    required this.onDeviceDetails,
    required this.onDeviceManual,
    required this.onLogin,
    required this.onProfile,
    required this.onReload,
  });

  final DeviceConnectionStatus status;
  final bool isAuthenticated;
  final HomeDashboard dashboard;
  final bool isLoading;
  final String? failureMessage;
  final VoidCallback onPrimaryAction;
  final ValueChanged<DeviceModelSummary> onDeviceModelDetails;
  final VoidCallback onDeviceDetails;
  final VoidCallback onDeviceManual;
  final VoidCallback onLogin;
  final VoidCallback onProfile;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final connected =
        status == DeviceConnectionStatus.connected ||
        status == DeviceConnectionStatus.lowBattery;
    return connected
        ? _ConnectedHome(
            dashboard: dashboard,
            isLoading: isLoading,
            failureMessage: failureMessage,
            onDeviceDetails: onDeviceDetails,
            onDeviceManual: onDeviceManual,
            onProfile: onProfile,
            onReload: onReload,
          )
        : _DisconnectedHome(
            dashboard: dashboard,
            isLoading: isLoading,
            isAuthenticated: isAuthenticated,
            onPrimaryAction: onPrimaryAction,
            onDeviceModelDetails: onDeviceModelDetails,
            onLogin: onLogin,
            onProfile: onProfile,
          );
  }
}
