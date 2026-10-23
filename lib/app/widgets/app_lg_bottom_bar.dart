// 本地玻璃导航：从 flutter_liquid_glass_plus 0.0.7 的标签配置及等宽分段结构适配为横向内容。
// 来源：lib/surfaces/liquid_glass_bottom_bar.dart；保留玻璃渲染，不复制搜索和拖动指示器。
//
// MIT License
// Copyright (c) 2024 flutter_liquid_glass contributors
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../core/theme/app_device_control_style.dart';

/// 本地标签配置；文案也是紧凑图标模式下的无障碍名称。
@immutable
final class AppLGBottomBarTab {
  /// 创建图标在左、文字在右的标签。
  const AppLGBottomBarTab({required this.label, required this.icon});

  /// 可见文案与无障碍名称。
  final String label;

  /// 标签图标。
  final IconData icon;
}

/// 应用专用玻璃分段导航；点击只发出事件，选中值由外部控制。
///
/// 将原库私有标签的 Column 改为真实 Row，使用同一按钮处理指针、
/// 键盘及语义操作，不依靠溢出布局或覆盖层扩展交互区域。
final class AppLGBottomBar extends StatelessWidget {
  /// 创建等宽标签栏；尺寸由父级约束决定。
  const AppLGBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.showLabel = true,
    this.quality = LGQuality.standard,
  }) : assert(tabs.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < tabs.length);

  /// 等宽分段的有序配置。
  final List<AppLGBottomBarTab> tabs;

  /// 当前选中位置。
  final int selectedIndex;

  /// 触控、键盘和辅助技术共用的选择事件。
  final ValueChanged<int> onTabSelected;

  /// 紧凑模式仅隐藏可见文字，保留完整语义名称。
  final bool showLabel;

  /// 沿用原库的玻璃质量选择。
  final LGQuality quality;

  @override
  Widget build(BuildContext context) {
    return LGContainer(
      useOwnLayer: true,
      quality: quality,
      settings: AppDeviceControlStyle.glass,
      shape: const LiquidRoundedRectangle(borderRadius: 34),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppDeviceControlStyle.surface,
          borderRadius: BorderRadius.all(Radius.circular(34)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 指示器独立于按钮，切换时连续移动，按钮命中区与语义保持固定。
              IgnorePointer(
                child: AnimatedAlign(
                  alignment: Alignment(
                    tabs.length == 1
                        ? 0
                        : -1 + 2 * selectedIndex / (tabs.length - 1),
                    0,
                  ),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  child: FractionallySizedBox(
                    widthFactor: 1 / tabs.length,
                    heightFactor: 1,
                    child: const DecoratedBox(
                      decoration: ShapeDecoration(
                        color: Colors.black,
                        shape: StadiumBorder(),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < tabs.length; index++)
                    Expanded(
                      child: _AppBottomBarTab(
                        tab: tabs[index],
                        selected: index == selectedIndex,
                        showLabel: showLabel,
                        onTap: () => onTabSelected(index),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 标签绘制与按钮命中区域一致，默认按钮焦点高亮供键盘定位。
final class _AppBottomBarTab extends StatelessWidget {
  const _AppBottomBarTab({
    required this.tab,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final AppLGBottomBarTab tab;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFFB9AFC0);
    return MergeSemantics(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const StadiumBorder(),
          animationDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
        ),
        child: Semantics(
          selected: selected,
          label: tab.label,
          excludeSemantics: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab.icon, size: showLabel ? 32 : 26, color: color),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
