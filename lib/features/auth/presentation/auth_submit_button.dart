// 认证提交按钮：把邮箱流程状态传给应用统一的液态玻璃按钮。
import 'package:flutter/material.dart';

import '../../../core/widgets/app_liquid_glass_button.dart';

/// 邮箱流程的提交按钮，支持加载、禁用、键盘焦点和无障碍点击。
final class AuthSubmitButton extends StatelessWidget {
  /// 创建提交按钮；加载时自动禁用点击且保持布局尺寸。
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  /// 当前步骤文案。
  final String label;

  /// 是否展示加载状态。
  final bool isLoading;

  /// 提交操作；为空时按钮不可点击。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => AppLiquidGlassButton(
    label: label,
    isLoading: isLoading,
    onPressed: onPressed,
  );
}
