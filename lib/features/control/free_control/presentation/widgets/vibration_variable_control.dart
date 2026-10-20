// 自由控制震动竖向无级变速控制卡片组件（Vibration Vertical Variable Control）；
// 基于 Canvas 自绘深度还原设计图 vibration-c.png 视觉规范，采用电光紫至浅紫罗兰竖向流体底色与高保真内发光漫反射，
// 左侧提供 100% ~ 0% 刻度指示条，右侧上方居中展示大号动态 XX % 百分比，下方提供竖向滑动调速发光胶囊，
// 支持从设备能力配置动态解析速度、垂直手势拖拽选值与平滑物理缓动动画。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'variable_capsule_control.dart';

/// 震动竖向无级变速控制组件卡片（对应 vibration-c.png，3x1 标准规格 172x355）
final class VibrationVariableControl extends StatelessWidget {
  /// 创建震动竖向无级变速卡片组件。
  const VibrationVariableControl({
    super.key,
    required this.config,
    this.initialPercentage,
    this.onGearChanged,
    this.onSpeedChanged,
    this.height,
  });

  /// 模块配置（包含后台下发的当前速度、标签等）
  final FreeControlComponentConfig config;

  /// 初始百分比（0 ~ 100）；未指定时优先从 config.gearCurrent 获取，兜底默认 12（对齐设计稿 vibration-c.png 12%）
  final int? initialPercentage;

  /// 档位变动回调（回传百分比整数 0 ~ 100）
  final ValueChanged<int>? onGearChanged;

  /// 速度变动回调（回传百分比整数 0 ~ 100，与 onGearChanged 保持兼容）
  final ValueChanged<int>? onSpeedChanged;

  /// 外部约束的固定高度（未指定时保持 172:355 纵向标准宽高比）
  final double? height;

  @override
  Widget build(BuildContext context) {
    return VariableCapsuleControl(
      config: config,
      orientation: Axis.vertical,
      theme: VariableCapsuleTheme.vibrationVertical,
      initialPercentage: initialPercentage,
      onValueChanged: (val) {
        onGearChanged?.call(val);
        onSpeedChanged?.call(val);
      },
      height: height,
    );
  }
}
