// 自由控制页面的网格排列器；支持精准 2 列网格 (row, col) 绝对坐标与跨行/跨列排版。
// 规则完全对齐管理后台 WebAdmin LayoutEditorNew.vue 的 2 列画布逻辑。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'free_control_component_placeholders.dart';

/// 动态 2 列网格布局构建器
final class FreeControlLayoutBuilder extends StatelessWidget {
  /// 创建自由控制网格布局构建器实例。
  const FreeControlLayoutBuilder({super.key, required this.layout});

  /// 当前自由控制布局实体
  final FreeControlLayout layout;

  @override
  Widget build(BuildContext context) {
    final components = layout.components;
    if (components.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 画布总可用宽度
        final availableWidth = constraints.maxWidth;
        const gap = 12.0; // 与 webadmin gap: 10px 相仿，保留呼吸感
        // 单列宽度
        final colWidth = (availableWidth - gap) / 2;
        // 单行单列基准高度：按 1x1 比例 172:105 计算（约 105.6 dp）
        final unitRowHeight = colWidth * (105 / 172);

        // 1. 计算最大网格占用行数
        var maxRow = 0;
        for (final comp in components) {
          maxRow = math.max(maxRow, comp.row + comp.rows);
        }

        // 2. 计算各行的自适应基准高度（1x1、加热横向条形保持 105 dp，伸缩/震动 1x2 横向条形对齐 358:135 即 135 dp）
        final rowHeights = List<double>.filled(maxRow, unitRowHeight);
        for (final comp in components) {
          if (comp.rows == 1) {
            final double naturalHeight;
            if (comp.cols >= 2) {
              if (comp.type == FreeControlComponentType.heat ||
                  comp.variant == 'heat_bar_1x2') {
                // 加热横向条形（heat-b.png）规格为 358x105，高度保持 105 dp
                naturalHeight = unitRowHeight;
              } else {
                // 伸缩与震动横向条形（thrust-b.png, vibration-b.png）规格为 358x135，高度为 135 dp
                naturalHeight = availableWidth * (135.0 / 358.0);
              }
            } else {
              // 1x1 单格（heat-a.png, suck-a.png）规格为 172x105，高度为 105 dp
              naturalHeight = unitRowHeight;
            }
            rowHeights[comp.row] = math.max(
              rowHeights[comp.row],
              naturalHeight,
            );
          }
        }

        // 3. 计算各行顶部的累积 Y 坐标
        final rowTops = List<double>.filled(maxRow + 1, 0.0);
        for (var r = 0; r < maxRow; r++) {
          rowTops[r + 1] = rowTops[r] + rowHeights[r] + gap;
        }

        // 4. 计算画布总高度
        final totalHeight = maxRow > 0 ? (rowTops[maxRow] - gap) : 0.0;

        return SizedBox(
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
                  if (comp.type == FreeControlComponentType.heat ||
                      comp.variant == 'heat_bar_1x2') {
                    // 加热横向条形（heat-b.png，358x105）高度为 105 dp
                    height = unitRowHeight;
                  } else {
                    // 伸缩/震动横向模式条形（对齐 358:135，严格保持 135 dp）
                    height = availableWidth * (135.0 / 358.0);
                  }
                } else if (comp.rows == 2) {
                  // 2x2 复合控制面板（对齐 358:231，保持 231 dp）
                  height = availableWidth * (231.0 / 358.0);
                } else {
                  height = rowTops[comp.row + comp.rows] - top - gap;
                }
              } else {
                if (comp.rows == 1) {
                  // 1x1 单格（heat-a.png, suck-a.png 等，对齐 172:105，高度为 105 dp）
                  height = unitRowHeight;
                } else if (comp.rows == 3) {
                  // 3x1 纵向全高胶囊（对齐 172:312 或 172:355）
                  final ratio = comp.variant.contains('variable')
                      ? (355.0 / 172.0)
                      : (312.0 / 172.0);
                  height = colWidth * ratio;
                } else {
                  height = rowTops[comp.row + comp.rows] - top - gap;
                }
              }

              return Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: FreeControlComponentPlaceholder(
                  config: comp,
                  height: height,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
