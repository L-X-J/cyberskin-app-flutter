// 伸缩 2x2 模式切换卡片；电蓝主题，薄封装 ModeMultiControl。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'mode_multi_control.dart';

/// 伸缩 2x2 模式切换卡片（对应 telescopic_mode_2x2，标准规格 358x231+）。
final class TelescopicModeSwitchControl extends StatelessWidget {
  const TelescopicModeSwitchControl({
    super.key,
    required this.config,
    this.height,
    this.initialValue = true,
    this.initialGear,
    this.onChanged,
    this.onGearChanged,
  });

  final FreeControlComponentConfig config;
  final double? height;
  final bool initialValue;
  final int? initialGear;
  final ValueChanged<bool>? onChanged;
  final ValueChanged<int>? onGearChanged;

  @override
  Widget build(BuildContext context) {
    return ModeMultiControl(
      config: config,
      height: height,
      // 电蓝：与 TelescopicSteppedControl / TelescopicVariableControl 保持一致
      accentColor: const Color(0xFF00A3FF),
      glowColor: const Color(0xFF00A3FF),
      initialValue: initialValue,
      initialGear: initialGear,
      onChanged: onChanged,
      onGearChanged: onGearChanged,
    );
  }
}
