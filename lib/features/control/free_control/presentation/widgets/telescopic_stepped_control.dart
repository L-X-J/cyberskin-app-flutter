// 自由控制伸缩分档模块组件（Telescopic Stepped Control）；
// 基于 Canvas 自绘深度还原设计图 thrust-a.png 视觉规范，采用电光蓝流体与深层漫反射光雾，
// 支持从设备能力配置动态解析档位数、触控选档/手势拖拽与平滑物理缓动动画。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'stepped_capsule_control.dart';

/// 伸缩分档控制组件卡片（对应 thrust-a.png）
final class TelescopicSteppedControl extends StatelessWidget {
  /// 创建伸缩分档卡片组件。
  const TelescopicSteppedControl({
    super.key,
    required this.config,
    this.orientation = Axis.vertical,
    this.onGearChanged,
    this.height,
  });

  /// 模块配置（包含后台下发的档位数 gearMax、当前档位 gearCurrent、标签等）
  final FreeControlComponentConfig config;

  /// 胶囊控件方向（竖向 Axis.vertical 对齐 3x1 规格；横向 Axis.horizontal 对齐 1x2 规格）
  final Axis orientation;

  /// 档位变动回调
  final ValueChanged<int>? onGearChanged;

  /// 外部约束的固定高度
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = orientation == Axis.horizontal;
    return SteppedCapsuleControl(
      config: config,
      orientation: orientation,
      theme: isHorizontal
          ? SteppedCapsuleTheme.telescopicHorizontal
          : SteppedCapsuleTheme.telescopic,
      onGearChanged: onGearChanged,
      height: height ?? (isHorizontal ? 135.0 : null),
    );
  }
}
