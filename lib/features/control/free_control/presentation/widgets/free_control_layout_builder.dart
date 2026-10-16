// 自由控制页面的网格排列器；支持精准 2 列网格 (row, col) 绝对坐标与跨行/跨列排版。
// 规则完全对齐管理后台 WebAdmin LayoutEditorNew.vue 的 2 列画布逻辑。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'free_control_component_placeholders.dart';

/// 动态 2 列网格布局构建器
final class FreeControlLayoutBuilder extends StatelessWidget {
  const FreeControlLayoutBuilder({super.key, required this.layout});

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
        // 单行基准高度：按 1x1 比例 172:105 计算
        final unitRowHeight = colWidth * (105 / 172);

        // 计算最大网格占用行数
        int maxRow = 0;
        for (final comp in components) {
          maxRow = math.max(maxRow, comp.row + comp.rows);
        }

        // 计算画布总高度
        final totalHeight =
            maxRow * unitRowHeight + (maxRow > 0 ? (maxRow - 1) * gap : 0);

        return SizedBox(
          width: availableWidth,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: components.map((comp) {
              final left = comp.col == 0 ? 0.0 : (colWidth + gap);
              final width = comp.cols >= 2 ? availableWidth : colWidth;
              final top = comp.row * (unitRowHeight + gap);
              final height = comp.rows * unitRowHeight + (comp.rows - 1) * gap;

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
