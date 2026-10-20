// 自由控制伸缩横向无级变速控制卡片组件（Telescopic Horizontal Variable Control）；
// 基于 VariableCapsuleControl 还原 thrust-d.png，采用伸缩专用 SVG 渐变和横向拖拽交互。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'variable_capsule_control.dart';

/// 伸缩横向无级变速控制组件卡片（对应 thrust-d.png，1x2 标准规格 358x135）。
final class TelescopicHorizontalVariableControl extends StatelessWidget {
  /// 创建伸缩横向无级变速卡片组件。
  const TelescopicHorizontalVariableControl({
    super.key,
    required this.config,
    this.initialPercentage,
    this.onGearChanged,
    this.onSpeedChanged,
    this.height = 135.0,
  });

  /// 模块配置（包含后台下发的当前速度、标签等）。
  final FreeControlComponentConfig config;

  /// 初始百分比（0 ~ 100）；未指定时优先从 config 读取，兜底为设计稿的 22%。
  final int? initialPercentage;

  /// 档位变动回调（回传百分比整数 0 ~ 100）。
  final ValueChanged<int>? onGearChanged;

  /// 速度变动回调（回传百分比整数 0 ~ 100）。
  final ValueChanged<int>? onSpeedChanged;

  /// 外部约束的固定高度（默认 135.0 dp）。
  final double? height;

  @override
  Widget build(BuildContext context) {
    return VariableCapsuleControl(
      config: config,
      orientation: Axis.horizontal,
      theme: VariableCapsuleTheme.telescopicHorizontalVariable,
      initialPercentage: initialPercentage,
      fallbackPercentage: 22,
      onValueChanged: (value) {
        onGearChanged?.call(value);
        onSpeedChanged?.call(value);
      },
      height: height ?? 135.0,
    );
  }
}
