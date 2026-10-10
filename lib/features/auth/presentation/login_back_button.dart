// 登录流程返回按钮：提供一致的玻璃圆形触控入口与无障碍名称。
import 'package:flutter/material.dart';

import '../../../core/widgets/app_liquid_glass_button.dart';

/// 登录步骤的返回入口，回调只改变前景步骤。
final class LoginBackButton extends StatelessWidget {
  /// 创建返回按钮。
  const LoginBackButton({super.key, required this.onPressed});

  /// 返回上一登录步骤。
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Tooltip(
      message: 'Back',
      child: AppLiquidGlassButton(
        label: 'Back',
        icon: Icons.arrow_back_ios_new,
        onPressed: onPressed,
        width: 44,
        height: 44,
        iconSize: 20,
        variant: AppLiquidGlassButtonVariant.translucent,
      ),
    ),
  );
}
