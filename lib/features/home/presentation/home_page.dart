// 主页页面：按设备连接状态渲染可复用的设备、内容和广告卡片。
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layered_gradient_style.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_layered_gradient_card.dart';
import '../../content/domain/entities/app_content.dart';
import '../../device/domain/device.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../training/domain/entities/training.dart';
import 'home_controller.dart';
import 'home_dashboard.dart';

part 'home_widgets.dart';

/// 匿名可浏览的应用主页。
final class HomePage extends GetView<HomeController> {
  /// 创建主页。
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.deviceStatus.value;
      final connected =
          status == DeviceConnectionStatus.connected ||
          status == DeviceConnectionStatus.lowBattery;
      return AppScaffold(
        currentTab: AppTab.home,
        showBottomNavigation: connected,
        appBar: const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        ),
        body: Obx(
          () => _HomeBody(
            status: status,
            isAuthenticated: controller.isAuthenticated,
            dashboard: controller.dashboard.value,
            isLoading: controller.isLoading.value,
            failureMessage: controller.failure.value?.message,
            onPrimaryAction: controller.requestConnection,
            onDeviceDetails: controller.openDevice,
            onLogin: controller.openLogin,
            onProfile: controller.openProfile,
            onReload: controller.reload,
          ),
        ),
      );
    });
  }
}

/// 根据设备连接状态渲染主页主体，壳层只订阅导航所需的状态。
final class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.status,
    required this.isAuthenticated,
    required this.dashboard,
    required this.isLoading,
    required this.failureMessage,
    required this.onPrimaryAction,
    required this.onDeviceDetails,
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
  final VoidCallback onDeviceDetails;
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
            onProfile: onProfile,
            onReload: onReload,
          )
        : _DisconnectedHome(
            dashboard: dashboard,
            isLoading: isLoading,
            isAuthenticated: isAuthenticated,
            onPrimaryAction: onPrimaryAction,
            onLogin: onLogin,
            onProfile: onProfile,
          );
  }
}
