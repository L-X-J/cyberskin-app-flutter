// 主页页面：按设备连接状态渲染可复用的设备、内容和广告卡片。
import 'dart:async';

import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../device/domain/device.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../video/domain/repositories/video_repository.dart';
import '../../video/presentation/video_controller.dart';
import '../../video/presentation/video_page.dart';
import 'home_connected/home_connected_view.dart';
import 'home_controller.dart';
import 'home_dashboard.dart';
import 'home_disconnected/home_disconnected_view.dart';

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
      final pendingDiscovery = controller.pendingDiscovery?.value;
      final isScanning = controller.isScanning?.value ?? false;
      final bleCardState = controller.bleCardState.value;
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
                  bleCardState: bleCardState,
                  onPrimaryAction: () =>
                      unawaited(controller.handleBlePrimaryAction()),
                  onStopDiscovery: () => unawaited(controller.stopDiscovery()),
                  pendingDiscovery: pendingDiscovery,
                  onConfirmDiscovery: () =>
                      unawaited(controller.confirmDiscovery()),
                  onDismissDiscovery: () =>
                      unawaited(controller.dismissDiscovery()),
                  isScanning: isScanning,
                  onDeviceModelDetails: (model) =>
                      controller.openDeviceManual(model.id, summary: model),
                  onDeviceDetails: controller.openDevice,
                  onDeviceManual: () => controller.openDeviceManual(
                    controller.dashboard.value.boundDevice?.deviceModelId,
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
    required this.bleCardState,
    required this.onPrimaryAction,
    required this.onStopDiscovery,
    required this.pendingDiscovery,
    required this.onConfirmDiscovery,
    required this.onDismissDiscovery,
    required this.isScanning,
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
  final HomeBleCardState bleCardState;
  final VoidCallback onPrimaryAction;
  final VoidCallback onStopDiscovery;
  final BleDiscoveredDevice? pendingDiscovery;
  final VoidCallback onConfirmDiscovery;
  final VoidCallback onDismissDiscovery;
  final bool isScanning;
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
        ? HomeConnectedView(
            dashboard: dashboard,
            isLoading: isLoading,
            failureMessage: failureMessage,
            onDeviceDetails: onDeviceDetails,
            onDeviceManual: onDeviceManual,
            onProfile: onProfile,
            onReload: onReload,
          )
        : HomeDisconnectedView(
            dashboard: dashboard,
            isLoading: isLoading,
            failureMessage: failureMessage,
            isAuthenticated: isAuthenticated,
            bleCardState: bleCardState,
            onPrimaryAction: onPrimaryAction,
            onStopDiscovery: onStopDiscovery,
            pendingDiscovery: pendingDiscovery,
            onConfirmDiscovery: onConfirmDiscovery,
            onDismissDiscovery: onDismissDiscovery,
            isScanning: isScanning,
            onDeviceModelDetails: onDeviceModelDetails,
            onDeviceManual: onDeviceManual,
            onLogin: onLogin,
            onProfile: onProfile,
            onReload: onReload,
          );
  }
}
