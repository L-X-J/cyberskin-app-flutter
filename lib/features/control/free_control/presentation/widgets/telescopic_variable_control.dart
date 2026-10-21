// 自由控制伸缩竖向无级变速控制卡片组件（Telescopic Vertical Variable Control）；
// 基于 VariableCapsuleControl 还原 thrust-c.png，复用统一的纵向刻度、百分比和拖拽交互。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'variable_capsule_control.dart';

/// 伸缩竖向无级变速控制组件卡片（对应 thrust-c.png，3x1 标准规格 172x312）。
final class TelescopicVariableControl extends StatelessWidget {
  /// 创建伸缩竖向无级变速卡片组件。
  const TelescopicVariableControl({
    super.key,
    required this.config,
    this.initialPercentage,
    this.onGearChanged,
    this.onSpeedChanged,
    this.height,
  });

  /// 模块配置（包含后台下发的当前速度、标签等）。
  final FreeControlComponentConfig config;

  /// 初始百分比（0 ~ 100）；未指定时优先从 config 读取，兜底为设计稿的 82%。
  final int? initialPercentage;

  /// 档位变动回调（回传百分比整数 0 ~ 100）。
  final ValueChanged<int>? onGearChanged;

  /// 速度变动回调（回传百分比整数 0 ~ 100）。
  final ValueChanged<int>? onSpeedChanged;

  /// 外部约束的固定高度；未指定时保持 172:355 纵向标准宽高比。
  final double? height;

  @override
  Widget build(BuildContext context) {
    return VariableCapsuleControl(
      config: config,
      orientation: Axis.vertical,
      theme: VariableCapsuleTheme.telescopicVertical,
      initialPercentage: initialPercentage,
      fallbackPercentage: 82,
      onValueChanged: (value) {
        onGearChanged?.call(value);
        onSpeedChanged?.call(value);
      },
      height: height,
    );
  }
}
