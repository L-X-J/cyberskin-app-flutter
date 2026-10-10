// 应用级小型玻璃表面：供多个一级页面复用，不承载业务状态。
import 'package:flutter/material.dart';

import '../../core/widgets/app_liquid_glass_button.dart';

/// 应用内重复卡片使用的轻量玻璃容器。
final class AppGlassCard extends StatelessWidget {
  /// 创建玻璃卡片。
  const AppGlassCard({required this.child, this.height, super.key});

  /// 卡片内容。
  final Widget child;

  /// 可选固定高度。
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: child,
      ),
    );
  }
}

/// 应用内统一的小型玻璃文字按钮。
final class AppTextButtonSurface extends StatelessWidget {
  /// 创建小型文字操作。
  const AppTextButtonSurface({
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 32,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.textStyle = const TextStyle(fontSize: 12, color: Colors.white),
    super.key,
  });

  /// 按钮文案。
  final String label;

  /// 点击回调。
  final VoidCallback onPressed;

  /// 可选固定宽度。
  final double? width;

  /// 按钮高度。
  final double height;

  /// 文案水平留白。
  final EdgeInsetsGeometry contentPadding;

  /// 文案样式。
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return AppLiquidGlassButton(
      label: label,
      onPressed: onPressed,
      variant: AppLiquidGlassButtonVariant.translucent,
      width: width,
      height: height,
      borderRadius: height / 2.6,
      contentPadding: contentPadding,
      textStyle: textStyle,
    );
  }
}

/// 应用内统一的小型玻璃图标按钮。
final class AppIconButtonSurface extends StatelessWidget {
  /// 创建小型图标操作。
  const AppIconButtonSurface({
    required this.icon,
    required this.onPressed,
    this.label = 'Action',
    this.size = 38,
    this.iconSize = 20,
    super.key,
  });

  /// 图标。
  final IconData icon;

  /// 点击回调。
  final VoidCallback onPressed;

  /// 无障碍语义名称。
  final String label;

  /// 方形按钮边长。
  final double size;

  /// 图标边长。
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AppLiquidGlassButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      variant: AppLiquidGlassButtonVariant.translucent,
      width: size,
      height: size,
      borderRadius: size / 3.2,
      iconSize: iconSize,
      textStyle: const TextStyle(color: Colors.white),
    );
  }
}

/// 应用内轻量空态或错误提示。
final class AppInlineHint extends StatelessWidget {
  /// 创建提示表面。
  const AppInlineHint({
    required this.icon,
    required this.text,
    this.onTap,
    super.key,
  });

  /// 提示图标。
  final IconData icon;

  /// 提示文本。
  final String text;

  /// 可选点击回调。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
