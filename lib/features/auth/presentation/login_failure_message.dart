// 登录内联错误：只订阅错误状态，在三个登录步骤中复用。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'login_controller.dart';

/// 登录错误展示，不解析底层异常或触发业务请求。
final class LoginFailureMessage extends StatelessWidget {
  /// 创建内联错误展示。
  const LoginFailureMessage({super.key, required this.controller});

  /// 可展示认证状态来源。
  final LoginController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final failure = controller.failure.value;
    if (failure == null) return const SizedBox.shrink();
    return Text(
      failure.message,
      textAlign: TextAlign.center,
      style: AppTypography.bodySmall.copyWith(color: AppColors.errorLight),
    );
  });
}
