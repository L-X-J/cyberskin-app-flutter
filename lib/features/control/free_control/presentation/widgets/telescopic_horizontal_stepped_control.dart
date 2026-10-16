// 自由控制伸缩横向分档模块组件（Telescopic Horizontal Stepped Control）；
// 基于 Canvas 自绘深度还原设计图 thrust-b.png 视觉规范，采用电光紫罗兰流体与深层漫反射光雾，
// 右侧展示动态 Gear 档位指示，支持从设备能力配置动态解析档位数、横向手势拖拽选档与平滑物理缓动动画。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'stepped_capsule_control.dart';

/// 伸缩横向分档控制组件卡片（对应 thrust-b.png，1x2 全宽标准规格 358x135）
final class TelescopicHorizontalSteppedControl extends StatelessWidget {
  /// 创建伸缩横向分档卡片组件（标准默认高度 135.0 dp）。
  const TelescopicHorizontalSteppedControl({
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
      theme: SteppedCapsuleTheme.telescopicHorizontal,
      onGearChanged: onGearChanged,
      height: height ?? 135.0,
    );
  }
}
