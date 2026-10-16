// 自由控制震动横向分档模块组件（Vibration Horizontal Stepped Control）；
// 基于 Canvas 自绘深度还原设计图 vibration-b.png 视觉规范，采用电光青靛流体与深层漫反射光雾，
// 右侧展示动态 Gear 档位指示，支持从设备能力配置动态解析档位数、横向手势拖拽选档与平滑物理缓动动画。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'stepped_capsule_control.dart';

/// 震动横向分档控制组件卡片（对应 vibration-b.png，1x2 全宽标准规格 358x135）
final class VibrationHorizontalSteppedControl extends StatelessWidget {
  /// 创建震动横向分档卡片组件（标准默认高度 135.0 dp）。
  const VibrationHorizontalSteppedControl({
    super.key,
    required this.config,
    this.onGearChanged,
    this.height = 135.0,
  });

  /// 模块配置（包含后台下发的档位数 gearMax、当前档位 gearCurrent、标签等）
  final FreeControlComponentConfig config;

  /// 档位变动回调
  final ValueChanged<int>? onGearChanged;

  /// 外部约束的固定高度（默认 135.0 dp）
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SteppedCapsuleControl(
      config: config,
      orientation: Axis.horizontal,
      theme: SteppedCapsuleTheme.vibrationHorizontal,
      onGearChanged: onGearChanged,
      height: height ?? 135.0,
    );
  }
}
