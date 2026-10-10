// 应用一级 Device / Video 导航：固定在页面左下，不持有路由或业务状态。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import 'app_scaffold.dart';

/// 一级页面标签的液态玻璃分段导航。
///
/// 组件只发出 [onSelected] 事件，页面决定同页切换或路由跳转，避免导航外观
/// 隐式绑定 GetX 路由。外框保留右侧悬浮设备控件的位置。
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

  /// 根据窗口宽度计算导航外框宽度，保持两侧安全边距不参与导航压缩。
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
    final width = widthFor(MediaQuery.sizeOf(context).width);
    final compact = isCompactWidth(width);
    return SizedBox(
      width: width,
      height: height,
      child: LiquidGlassLayer(
        fake: true,
        useBackdropGroup: true,
        child: LGContainer(
          width: width,
          height: height,
          useOwnLayer: true,
          quality: LGQuality.standard,
          settings: const LiquidGlassSettings(
            glassColor: Colors.transparent,
            lightIntensity: 0,
            ambientStrength: 0,
            saturation: 1,
          ),
          shape: const LiquidRoundedRectangle(borderRadius: 34),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF343039), Color(0xFF6B3A70)],
              ),
              border: Border.all(color: const Color(0x66FFFFFF)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _TabSegment(
                    tab: AppTab.home,
                    selectedTab: selectedTab,
                    label: 'Device',
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_outlined,
                    compact: compact,
                    onSelected: onSelected,
                  ),
                  _TabSegment(
                    tab: AppTab.video,
                    selectedTab: selectedTab,
                    label: 'Video',
                    icon: Icons.play_circle_outline,
                    selectedIcon: Icons.play_circle_outline,
                    compact: compact,
                    onSelected: onSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单个一级导航入口，选中态只动画表面与文字，不改变导航容器几何。
final class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.tab,
    required this.selectedTab,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onSelected,
    required this.compact,
  });

  final AppTab tab;
  final AppTab selectedTab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final ValueChanged<AppTab> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final selected = selectedTab == tab;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: () => onSelected(tab),
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: selected
                  ? Border.all(color: const Color(0xFF00DB6B), width: 2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: compact ? 22 : 28,
                  color: selected ? Colors.white : const Color(0xFFB9AFC0),
                ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFFB9AFC0),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
