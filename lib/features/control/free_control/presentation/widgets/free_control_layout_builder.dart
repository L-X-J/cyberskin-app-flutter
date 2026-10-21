// 自由控制页面的网格排列器；支持精准 2 列网格 (row, col) 绝对坐标与跨行/跨列排版。
// 规则完全对齐管理后台 WebAdmin LayoutEditorNew.vue 的 2 列画布逻辑。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'free_control_component_placeholders.dart';
import 'mode_multi_control.dart';
import 'suck_multi_control.dart';

// 可折叠的 2x2 变体（开关关闭时高度自适应）。
const _variableHeight2x2 = {
  'suck_multi_2x2',
  'telescopic_mode_2x2',
  'vibration_mode_2x2',
};

/// 动态 2 列网格布局构建器。
///
/// 使用 StatefulWidget 追踪可折叠卡片（[_variableHeight2x2]）的开关状态，
/// 以便在卡片折叠/展开时正确收缩或扩展画布总高度。
final class FreeControlLayoutBuilder extends StatefulWidget {
  /// 创建按后台网格配置排列并播放首次入场动画的布局器。
  const FreeControlLayoutBuilder({super.key, required this.layout});

  /// 当前设备的模块位置与跨列配置。
  final FreeControlLayout layout;

  @override
  State<FreeControlLayoutBuilder> createState() =>
      _FreeControlLayoutBuilderState();
}

final class _FreeControlLayoutBuilderState
    extends State<FreeControlLayoutBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
      _entranceStarted = true;
    } else if (!_entranceStarted) {
      _entranceStarted = true;
      _entranceController.forward();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  // variant → on/off 状态；仅追踪可折叠变体。
  final Map<String, bool> _cardOnState = {};

  /// 返回指定 variant 的卡片当前是否开启。
  bool _isCardOn(FreeControlComponentConfig comp) {
    if (!_variableHeight2x2.contains(comp.variant)) return true;
    return _cardOnState[_cardKey(comp)] ?? true;
  }

  String _cardKey(FreeControlComponentConfig comp) =>
      '${comp.variant}_${comp.row}_${comp.col}';

  void _onCardToggle(FreeControlComponentConfig comp, bool isOn) {
    setState(() {
      _cardOnState[_cardKey(comp)] = isOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final components = widget.layout.components;
    if (components.isEmpty) return const SizedBox.shrink();

    // 用视觉行顺序错开入场；稀疏 row 和后台列表顺序不影响总时长。
    final rows = components.map((comp) => comp.row).toSet().toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const gap = 12.0;
        final colWidth = (availableWidth - gap) / 2;
        final unitRowHeight = colWidth * (105 / 172);

        // 1. 最大网格行数
        var maxRow = 0;
        for (final comp in components) {
          maxRow = math.max(maxRow, comp.row + comp.rows);
        }

        // 2. 各行基准高度
        final rowHeights = List<double>.filled(maxRow, unitRowHeight);
        for (final comp in components) {
          if (comp.rows == 1) {
            final double naturalHeight;
            if (comp.cols >= 2) {
              naturalHeight =
                  (comp.type == FreeControlComponentType.heat ||
                      comp.variant == 'heat_bar_1x2')
                  ? unitRowHeight
                  : availableWidth * (135.0 / 358.0);
            } else {
              naturalHeight = unitRowHeight;
            }
            rowHeights[comp.row] = math.max(
              rowHeights[comp.row],
              naturalHeight,
            );
          }
        }

        // 3. 可折叠 2x2 卡片：按当前开关状态调整行高。
        //    展开时：将卡片所需总高度回填到首行（原有逻辑）。
        //    折叠时：首行收缩到折叠高度，同时将卡片独占的尾行压缩到 0，
        //            消除两行合计高度大于折叠卡片高度时产生的空白间隙。
        for (final comp in components) {
          if (_variableHeight2x2.contains(comp.variant) && comp.rows >= 2) {
            final isOn = _isCardOn(comp);
            final desiredHeight = comp.variant == 'suck_multi_2x2'
                ? SuckMultiControl.estimatedHeight(
                    comp,
                    availableWidth: availableWidth,
                    isOn: isOn,
                  )
                : ModeMultiControl.estimatedHeight(
                    comp,
                    availableWidth: availableWidth,
                    isOn: isOn,
                  );

            if (isOn) {
              // 展开：把总高度回填到首行，尾行保持其他组件决定的基准高度。
              final trailingRowHeight = rowHeights[comp.row + 1];
              rowHeights[comp.row] = math.max(
                rowHeights[comp.row],
                desiredHeight - trailingRowHeight + gap,
              );
            } else {
              // 折叠：检查尾行是否被其他组件独占。
              // 若尾行只属于本卡片（全宽 2 列），则将尾行高度压缩为 0，
              // 并把首行设为折叠卡片高度，从而消除空白行。
              final trailingRow = comp.row + 1;
              final trailingExclusive = components.every((other) {
                if (other == comp) return true; // 自身跳过
                // 其他组件是否占用了尾行？
                return other.row > trailingRow ||
                    other.row + other.rows <= trailingRow;
              });
              if (trailingExclusive) {
                rowHeights[comp.row] = math.max(
                  rowHeights[comp.row],
                  desiredHeight,
                );
                rowHeights[trailingRow] = 0;
              } else {
                // 尾行被其他组件共用，不能压缩；仅调整首行。
                final trailingRowHeight = rowHeights[trailingRow];
                rowHeights[comp.row] = math.max(
                  rowHeights[comp.row],
                  (desiredHeight - trailingRowHeight + gap).clamp(
                    0,
                    double.infinity,
                  ),
                );
              }
            }
          }
        }

        // 4. 累积行顶部坐标
        final rowTops = List<double>.filled(maxRow + 1, 0.0);
        for (var r = 0; r < maxRow; r++) {
          rowTops[r + 1] = rowTops[r] + rowHeights[r] + gap;
        }

        final totalHeight = maxRow > 0 ? (rowTops[maxRow] - gap) : 0.0;

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: availableWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: components.map((comp) {
                final left = comp.col == 0 ? 0.0 : (colWidth + gap);
                final width = comp.cols >= 2 ? availableWidth : colWidth;
                final top = rowTops[comp.row];

                final double height;
                if (comp.cols >= 2) {
                  if (comp.rows == 1) {
                    height =
                        (comp.type == FreeControlComponentType.heat ||
                            comp.variant == 'heat_bar_1x2')
                        ? unitRowHeight
                        : availableWidth * (135.0 / 358.0);
                  } else if (comp.variant == 'suck_multi_2x2') {
                    height = SuckMultiControl.estimatedHeight(
                      comp,
                      availableWidth: availableWidth,
                      isOn: _isCardOn(comp),
                    );
                  } else if (comp.variant == 'telescopic_mode_2x2' ||
                      comp.variant == 'vibration_mode_2x2') {
                    height = ModeMultiControl.estimatedHeight(
                      comp,
                      availableWidth: availableWidth,
                      isOn: _isCardOn(comp),
                    );
                  } else if (comp.rows == 2) {
                    height = availableWidth * (231.0 / 358.0);
                  } else {
                    height = rowTops[comp.row + comp.rows] - top - gap;
                  }
                } else {
                  if (comp.rows == 1) {
                    height = unitRowHeight;
                  } else if (comp.rows == 3) {
                    height = colWidth * (312.0 / 172.0);
                  } else {
                    height = rowTops[comp.row + comp.rows] - top - gap;
                  }
                }

                return Positioned(
                  key: ValueKey(_cardKey(comp)),
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: _animateEntrance(
                    comp: comp,
                    rowIndex: rows.indexOf(comp.row),
                    width: width,
                    child: FreeControlComponentPlaceholder(
                      config: comp,
                      height: height,
                      onToggle: _variableHeight2x2.contains(comp.variant)
                          ? (isOn) => _onCardToggle(comp, isOn)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// 动画只改变绘制位置与透明度，不修改网格几何或触发控制回调。
  Widget _animateEntrance({
    required FreeControlComponentConfig comp,
    required int rowIndex,
    required double width,
    required Widget child,
  }) {
    final start = 0.12 + math.min(rowIndex, 4) * 0.055;
    final progress = _entranceController.drive(
      CurveTween(
        curve: Interval(start, start + 0.65, curve: Curves.easeOutCubic),
      ),
    );
    final begin = comp.isFullWidth
        ? const Offset(0, 0.22)
        : Offset((comp.col == 0 ? -1 : 1) * (width + 16) / width, 0);
    final slide = SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(progress),
      child: child,
    );
    return comp.isFullWidth
        ? FadeTransition(opacity: progress, child: slide)
        : slide;
  }
}
