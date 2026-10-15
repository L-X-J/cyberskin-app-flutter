// 自由控制页面的网格排列器；支持单列占位、跨双列以及按组自动成行。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'free_control_component_placeholders.dart';

/// 动态布局网格构建器：根据后端配置自动将组件按网格单元和整行进行排版
final class FreeControlLayoutBuilder extends StatelessWidget {
  const FreeControlLayoutBuilder({
    super.key,
    required this.layout,
  });

  final FreeControlLayout layout;

  @override
  Widget build(BuildContext context) {
    final components = layout.components;
    if (components.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    int index = 0;

    while (index < components.length) {
      final current = components[index];

      // 如果是全宽组件（cols >= 2）
      if (current.isFullWidth) {
        children.add(FreeControlComponentPlaceholder(config: current));
        children.add(const SizedBox(height: 14));
        index++;
        continue;
      }

      // 如果是单列组件（cols == 1），检查下一个是否也是单列组件可以并排成一行
      if (index + 1 < components.length && !components[index + 1].isFullWidth) {
        final next = components[index + 1];
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FreeControlComponentPlaceholder(config: current),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FreeControlComponentPlaceholder(config: next),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: 14));
        index += 2;
      } else {
        // 单个单列组件占半边或放左侧
        children.add(
          Row(
            children: [
              Expanded(
                child: FreeControlComponentPlaceholder(config: current),
              ),
              const SizedBox(width: 14),
              const Expanded(child: SizedBox()),
            ],
          ),
        );
        children.add(const SizedBox(height: 14));
        index++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
