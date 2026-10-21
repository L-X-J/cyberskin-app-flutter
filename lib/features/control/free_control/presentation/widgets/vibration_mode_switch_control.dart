// 震动 2x2 模式切换卡片；品红主题，薄封装 ModeMultiControl。

import 'package:flutter/material.dart';

import '../../domain/entities/free_control_layout.dart';
import 'mode_multi_control.dart';

/// 震动 2x2 模式切换卡片（对应 vibration_mode_2x2，标准规格 358x231+）。
final class VibrationModeSwitchControl extends StatelessWidget {
  const VibrationModeSwitchControl({
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
      // 品红：与 VibrationSteppedControl / VibrationVariableControl 保持一致
      accentColor: const Color(0xFFE447D0),
      glowColor: const Color(0xFFE447D0),
      initialValue: initialValue,
      initialGear: initialGear,
      onChanged: onChanged,
      onGearChanged: onGearChanged,
    );
  }
}
