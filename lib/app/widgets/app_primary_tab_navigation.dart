// 应用一级 Device / Video 导航：使用本地横向玻璃标签，不持有路由或业务状态。
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_lg_bottom_bar.dart';
import 'app_scaffold.dart';

/// 一级页面标签的液态玻璃分段导航。
///
/// 组件只发出 [onSelected] 事件，页面决定同页切换或路由跳转。
final class AppPrimaryTabNavigation extends StatelessWidget {
  /// 创建一级标签导航。
  const AppPrimaryTabNavigation({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  /// 设计稿中的分段导航高度。
  static const double height = 68;

  /// 设计稿中的最大导航宽度。
  static const double maxWidth = 211;

  /// 根据窗口宽度计算导航外框宽度。
  static double widthFor(double viewportWidth) =>
      math.min(math.max(0.0, viewportWidth - 48), maxWidth);

  /// 窄到无法稳定容纳文案时切换到图标模式。
  static bool isCompactWidth(double width) => width < 176;

  /// 当前选中标签。
  final AppTab selectedTab;

  /// 用户选择标签时的回调。
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          widthFor(MediaQuery.sizeOf(context).width),
          constraints.maxWidth,
        );
        final compact =
            isCompactWidth(width) ||
            MediaQuery.textScalerOf(context).scale(16) > 20;
        return SizedBox(
          width: width,
          height: height,
          child: AppLGBottomBar(
            tabs: const [
              AppLGBottomBarTab(label: 'Device', icon: Icons.home_outlined),
              AppLGBottomBarTab(
                label: 'Video',
                icon: Icons.play_circle_outline,
              ),
            ],
            selectedIndex: AppTab.values.indexOf(selectedTab),
            onTabSelected: (index) => onSelected(AppTab.values[index]),

            showLabel: !compact,
          ),
        );
      },
    );
  }
}
