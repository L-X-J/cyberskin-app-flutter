// 自由控制震动横向无级变速控制卡片组件（Vibration Horizontal Variable Control）；
// 基于 Canvas 自绘深度还原设计图 vibration-d.png 视觉规范，采用电光紫线性流体底色与深度漫反射内阴影，
// 右侧展示动态 Gear XX % 连续百分比指示，支持从设备能力配置动态解析速度、水平手势拖拽选值与平滑物理缓动动画。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'variable_capsule_control.dart';

/// 震动横向无级变速控制组件卡片（对应 vibration-d.png，1x2 全宽标准规格 358x135）
final class VibrationHorizontalVariableControl extends StatelessWidget {
  /// 创建震动横向无级变速卡片组件（标准默认高度 135.0 dp）。
  const VibrationHorizontalVariableControl({
    super.key,
    required this.config,
    this.initialPercentage,
    this.onGearChanged,
    this.onSpeedChanged,
    this.height = 135.0,
  });

  /// 模块配置（包含后台下发的当前档位/速度、标签等）
  final FreeControlComponentConfig config;

  /// 初始百分比（0 ~ 100）；未指定时优先从 config.gearCurrent 获取，兜底默认 62（对齐设计稿 vibration-d.png 62%）
  final int? initialPercentage;

  /// 档位变动回调（回传百分比整数 0 ~ 100）
  final ValueChanged<int>? onGearChanged;

  /// 速度变动回调（回传百分比整数 0 ~ 100，与 onGearChanged 兼容）
  final ValueChanged<int>? onSpeedChanged;

  /// 外部约束的固定高度（默认 135.0 dp）
  final double? height;

  @override
  Widget build(BuildContext context) {
    return VariableCapsuleControl(
      config: config,
      theme: VariableCapsuleTheme.vibration,
      initialPercentage: initialPercentage,
      onValueChanged: (val) {
        onGearChanged?.call(val);
        onSpeedChanged?.call(val);
      },
      height: height ?? 135.0,
    );
  }
}
