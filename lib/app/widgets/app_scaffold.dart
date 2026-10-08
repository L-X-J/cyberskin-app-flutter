// 主页面共享壳层：统一顶部区域、全局控制条和底部主导航。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/control/presentation/widgets/device_control_pill.dart';
import '../app_routes.dart';
import '../session_controller.dart';

/// 产品主导航中的两个一级目的地。
enum AppTab {
  /// 设备控制与设备管理。
  home,

  /// 视频内容体验。
  video,

  /// 用户账户与个人资料。
  profile,
}

/// 带 GetX 导航和全局设备控制条的共享页面壳层。
final class AppScaffold extends StatelessWidget {
  /// 创建统一页面壳层。
  const AppScaffold({
    required this.currentTab,
    required this.appBar,
    required this.body,
    super.key,
  });

  /// 当前选中的一级目的地。
  final AppTab currentTab;

  /// 当前页面的顶部栏。
  final PreferredSizeWidget appBar;

  /// 当前页面内容；只有该子树应当订阅 Feature 状态。
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.center,
              child: DeviceControlPill(),
            ),
          ),
          NavigationBar(
            selectedIndex: currentTab.index,
            onDestinationSelected: (index) {
              final route = switch (AppTab.values[index]) {
                AppTab.home => AppRoutes.home,
                AppTab.video => AppRoutes.video,
                AppTab.profile => _profileRoute(),
              };
              unawaited(Get.offNamed<void>(route));
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.video_library_outlined),
                selectedIcon: Icon(Icons.video_library),
                label: 'Video',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _profileRoute() {
    if (!Get.isRegistered<SessionController>()) {
      return AppRoutes.login;
    }
    final session = Get.find<SessionController>();
    return session.state.value == SessionState.authenticated
        ? AppRoutes.profile
        : AppRoutes.login;
  }
}
