// 主页面共享壳层：统一顶部区域、全局控制条和底部主导航。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_device_control_style.dart';
import '../app_routes.dart';
import '../floating_control_controller.dart';

/// 产品主导航中的两个一级目的地。
enum AppTab {
  /// 设备控制与设备管理。
  home,

  /// 视频内容体验。
  video,
}

/// 带 GetX 导航和全局设备控制条的共享页面壳层。
final class AppScaffold extends StatefulWidget {
  /// 创建统一页面壳层。
  const AppScaffold({
    required this.currentTab,
    required this.appBar,
    required this.body,
    this.showBottomNavigation = true,
    super.key,
  });

  /// 当前选中的一级目的地。
  final AppTab currentTab;

  /// 当前页面的顶部栏。
  final PreferredSizeWidget appBar;

  /// 当前页面内容；只有该子树应当订阅 Feature 状态。
  final Widget body;

  /// 是否显示一级 Device / Video 导航；个人中心和未连接首页不显示。
  final bool showBottomNavigation;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

final class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey _bodyKey = GlobalKey();
  Route<dynamic>? _route;
  Animation<double>? _routeAnimation;
  Animation<double>? _routeSecondaryAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    final secondaryAnimation = route?.secondaryAnimation;
    if (_routeAnimation != animation) {
      _routeAnimation?.removeListener(_reportBoundsAfterLayout);
      _routeAnimation = animation;
      _routeAnimation?.addListener(_reportBoundsAfterLayout);
    }
    if (_routeSecondaryAnimation != secondaryAnimation) {
      _routeSecondaryAnimation?.removeListener(_reportBoundsAfterLayout);
      _routeSecondaryAnimation = secondaryAnimation;
      _routeSecondaryAnimation?.addListener(_reportBoundsAfterLayout);
    }
    _route = route;
  }

  /// 几何随页面生命周期注册；旧页面在转场期间不覆盖活动页面。
  @override
  void dispose() {
    _routeAnimation?.removeListener(_reportBoundsAfterLayout);
    _routeSecondaryAnimation?.removeListener(_reportBoundsAfterLayout);
    if (_route != null && Get.isRegistered<FloatingControlController>()) {
      Get.find<FloatingControlController>().forgetPage(_route!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _reportBoundsAfterLayout();
            final size = AppDeviceControlStyle.sizeFor(
              textScaler: MediaQuery.textScalerOf(context),
              maxWidth: constraints.maxWidth - 48,
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
            );
            return SizedBox.expand(
              key: _bodyKey,
              child: Padding(
                // 控件虽在根悬浮层绘制，末项仍必须能够滚动到无遮挡位置。
                padding: EdgeInsets.only(bottom: size.height + 24),
                child: widget.body,
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: widget.showBottomNavigation
          ? NavigationBar(
              selectedIndex: widget.currentTab.index,
              onDestinationSelected: (index) {
                final route = switch (AppTab.values[index]) {
                  AppTab.home => AppRoutes.home,
                  AppTab.video => AppRoutes.video,
                };
                unawaited(Get.offNamed<void>(route));
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Device',
                ),
                NavigationDestination(
                  icon: Icon(Icons.play_circle_outline),
                  selectedIcon: Icon(Icons.play_circle),
                  label: 'Video',
                ),
              ],
            )
          : null,
    );
  }

  /// 布局完成后采集真实内容区域，包含安全区、AppBar、导航和键盘的影响。
  void _reportBoundsAfterLayout() {
    final route = _route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          route == null ||
          !Get.isRegistered<FloatingControlController>()) {
        return;
      }
      final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      Get.find<FloatingControlController>().reportPageBounds(
        route,
        box.localToGlobal(Offset.zero) & box.size,
      );
    });
  }
}
