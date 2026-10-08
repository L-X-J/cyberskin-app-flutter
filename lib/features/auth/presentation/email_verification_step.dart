// 邮箱验证码步骤：展示收码邮箱、六位分组输入、重发倒计时和提交操作。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'auth_submit_button.dart';
import 'login_back_button.dart';
import 'login_controller.dart';
import 'login_failure_message.dart';
import 'verification_code_input.dart';

/// 邮箱流程第二步，只使用发码成功后确认的邮箱。
final class EmailVerificationStep extends StatelessWidget {
  /// 创建验证码步骤。
  const EmailVerificationStep({
    super.key,
    required this.controller,
    required this.onBack,
  });

  /// 验证码状态与提交事件入口。
  final LoginController controller;

  /// 返回邮箱地址步骤。
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(27, 12, 27, 32),
    children: [
      LoginBackButton(onPressed: onBack),
      const SizedBox(height: 52),
      const Text('6-digit code', style: AppTypography.pageTitle),
      const SizedBox(height: 8),
      Text(
        'Enter the code sent to ${controller.verificationEmail.value}',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textOnAccent),
      ),
      const SizedBox(height: 26),
      Obx(
        () => VerificationCodeInput(
          value: controller.code.value,
          enabled: !controller.signingIn.value && !controller.sendingCode.value,
          onChanged: (value) => controller.code.value = value,
          onSubmitted: () => unawaited(controller.signInWithEmail()),
        ),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: Obx(() {
          final remaining = controller.resendSecondsRemaining.value;
          final sending = controller.sendingCode.value;
          return TextButton(
            onPressed: remaining > 0 || sending || controller.signingIn.value
                ? null
                : () => unawaited(controller.resendCode()),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              foregroundColor: AppColors.textOnAccent,
              disabledForegroundColor: AppColors.textOnAccent,
            ),
            child: Text(
              sending
                  ? 'Sending'
                  : remaining > 0
                  ? 'Resend code in ${(remaining ~/ 60).toString().padLeft(2, '0')}:${(remaining % 60).toString().padLeft(2, '0')}'
                  : 'Resend code',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textOnAccent,
                fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 17),
      Obx(
        () => AuthSubmitButton(
          label: 'Sign in',
          isLoading: controller.signingIn.value,
          onPressed: controller.signingIn.value || controller.sendingCode.value
              ? null
              : () => unawaited(controller.signInWithEmail()),
        ),
      ),
      const SizedBox(height: 20),
      LoginFailureMessage(controller: controller),
    ],
  );
}
