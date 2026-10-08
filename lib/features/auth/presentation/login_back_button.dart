// 登录流程返回按钮：提供一致的玻璃圆形触控入口与无障碍名称。
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

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
      child: LGButton(
        label: 'Back',
        icon: Icons.arrow_back_ios_new,
        onTap: onPressed,
        width: 44,
        height: 44,
        useOwnLayer: true,
        iconSize: 20,
      ),
    ),
  );
}
