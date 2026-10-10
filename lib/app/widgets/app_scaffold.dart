// 主页面共享壳层：统一顶部区域、全局控制条和底部主导航。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_device_control_style.dart';
import '../app_routes.dart';
import '../floating_control_controller.dart';
import 'app_primary_tab_navigation.dart';

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
    this.onTabSelected,
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

  /// 一级标签事件；为空时保留独立路由页面的兼容跳转。
  final ValueChanged<AppTab>? onTabSelected;

  /// 计算页面滚动内容应预留的底部空间。
  ///
  /// 壳层的背景必须铺满整个 viewport，不能通过缩短 [body] 的约束来给导航
  /// 让位。因此页面的 ListView/ScrollView 应把这个值加入自身 bottom padding，
  /// 这样最后一项可达，同时渐变和玻璃背景不会出现黑色断层。
  static double contentBottomPaddingOf(
    BuildContext context, {
    required bool showBottomNavigation,
    bool reserveFloatingControl = true,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final maxWidth = MediaQuery.sizeOf(context).width - 48;
    final controlSize = AppDeviceControlStyle.sizeFor(
      textScaler: textScaler,
      maxWidth: maxWidth,
      fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
    );
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    if (!showBottomNavigation) {
      return reserveFloatingControl
          ? controlSize.height + 24 + bottomSafeArea
          : 0;
    }

    final navigationWidth = AppPrimaryTabNavigation.widthFor(
      MediaQuery.sizeOf(context).width,
    );
    final docksOverlap = _docksOverlap(
      viewportWidth: MediaQuery.sizeOf(context).width,
      navigationWidth: navigationWidth,
      controlWidth: controlSize.width,
    );
    final dockHeight = docksOverlap
        ? AppPrimaryTabNavigation.height + 12 + controlSize.height
        : math.max(AppPrimaryTabNavigation.height, controlSize.height);
    // 12px 留给 Dock 到屏幕边缘，另 12px 留给滚动内容与 Dock 的呼吸空间。
    return dockHeight + 24 + bottomSafeArea;
  }

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
      backgroundColor: AppColors.surfaceDark,
      extendBody: true,
      appBar: widget.appBar,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _reportBoundsAfterLayout();
            final metrics = _DockMetrics.from(
              viewportWidth: constraints.maxWidth,
              bottomSafeArea: MediaQuery.paddingOf(context).bottom,
              textScaler: MediaQuery.textScalerOf(context),
              fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
              showBottomNavigation: widget.showBottomNavigation,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                SizedBox.expand(
                  key: _bodyKey,
                  // 背景必须拿到完整 viewport；滚动内容的底部余量由页面自身
                  // 通过 contentBottomPaddingOf 添加，避免形成黑色底部空洞。
                  child: widget.body,
                ),
                if (widget.showBottomNavigation)
                  Positioned(
                    left: 24,
                    bottom: metrics.navigationBottom,
                    child: AppPrimaryTabNavigation(
                      selectedTab: widget.currentTab,
                      onSelected: _selectTab,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 首页同页切换优先交由调用方处理；独立路由仍保持原有跳转契约。
  void _selectTab(AppTab tab) {
    final callback = widget.onTabSelected;
    if (callback != null) {
      callback(tab);
      return;
    }
    final route = switch (tab) {
      AppTab.home => AppRoutes.home,
      AppTab.video => AppRoutes.video,
    };
    Get.offNamed<void>(route);
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
      final rawBounds = box.localToGlobal(Offset.zero) & box.size;
      final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
      // 悬浮控件的可拖动区域消费系统底部安全区，避免它停在 Home Indicator 上。
      final safeBounds = Rect.fromLTRB(
        rawBounds.left,
        rawBounds.top,
        rawBounds.right,
        math.max(rawBounds.top, rawBounds.bottom - bottomSafeArea),
      );
      Get.find<FloatingControlController>().reportPageBounds(route, safeBounds);
    });
  }
}

/// 壳层底部 Dock 的几何结果；导航和悬浮控件共享同一套安全区计算。
final class _DockMetrics {
  /// 计算导航的底部位置；横向不足时将其放到快捷控件上方。
  factory _DockMetrics.from({
    required double viewportWidth,
    required double bottomSafeArea,
    required TextScaler textScaler,
    required String? fontFamily,
    required bool showBottomNavigation,
  }) {
    if (!showBottomNavigation) return const _DockMetrics(navigationBottom: 0);
    final controlSize = AppDeviceControlStyle.sizeFor(
      textScaler: textScaler,
      maxWidth: viewportWidth - 48,
      fontFamily: fontFamily,
    );
    final navigationWidth = AppPrimaryTabNavigation.widthFor(viewportWidth);
    final overlap = _docksOverlap(
      viewportWidth: viewportWidth,
      navigationWidth: navigationWidth,
      controlWidth: controlSize.width,
    );
    return _DockMetrics(
      navigationBottom:
          bottomSafeArea + 12 + (overlap ? controlSize.height + 12 : 0),
    );
  }

  const _DockMetrics({required this.navigationBottom});

  final double navigationBottom;
}

/// 左右 Dock 之间不足 12px 时将导航上移到快捷控件上方。
bool _docksOverlap({
  required double viewportWidth,
  required double navigationWidth,
  required double controlWidth,
}) {
  final navigationRight = 24 + navigationWidth;
  final controlLeft = viewportWidth - controlWidth - 24;
  return navigationRight + 12 > controlLeft;
}
