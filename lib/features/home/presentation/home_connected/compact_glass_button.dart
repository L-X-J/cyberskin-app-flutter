// 设备主页跨卡片复用的紧凑型液态玻璃操作按钮。
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';

/// 设备页已连接状态下跨组件复用的紧凑液态玻璃操作按钮。
///
/// 支持纯图标按钮或带图标和文字的操作标签，高度固定为 32，视觉与整体玻璃拟物风格保持一致。
final class CompactGlassButton extends StatelessWidget {
  /// 创建紧凑液态玻璃按钮。
  const CompactGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    this.width,
    this.height,
    this.iconOnly = false,
  });

  /// 按钮文案或无障碍提示。
  final String label;

  /// 点击回调；为空时按钮置灰禁用。
  final VoidCallback? onPressed;

  /// 系统图标；与 [iconWidget] 互斥，优先使用 [iconWidget]。
  final IconData? icon;

  /// 替代 [icon] 的自定义图标 Widget。
  final Widget? iconWidget;

  /// 按钮固定宽度；为空时根据内容自适应。
  final double? width;
  final double? height;

  /// 是否仅展示图标内容。
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return AppLiquidGlassButton(
      label: label,
      leadingWidget: iconOnly ? null : iconWidget,
      leadingIcon: iconOnly ? null : icon,
      icon: iconOnly ? icon : null,
      onPressed: onPressed,
      variant: AppLiquidGlassButtonVariant.translucent,
      width: width,
      height: height ?? 32,
      borderRadius: 90,
      iconSize: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(
        fontSize: AppTypography.size12,
        color: AppColors.textPrimary,
      ),
      child: (iconOnly && iconWidget != null) ? iconWidget : null,
    );
  }
}
