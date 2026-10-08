// 邮箱地址步骤：收集邮箱并触发首次发码，不在本步骤展示验证码。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import 'auth_submit_button.dart';
import 'login_back_button.dart';
import 'login_controller.dart';
import 'login_failure_message.dart';
import 'login_terms_text.dart';

/// 邮箱流程第一步，发送成功后的步骤切换由页面壳负责。
final class EmailAddressStep extends StatefulWidget {
  /// 创建邮箱地址步骤。
  const EmailAddressStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onNext,
  });

  /// 登录状态与认证事件入口。
  final LoginController controller;

  /// 返回登录方式首页。
  final VoidCallback onBack;

  /// 请求验证码并在成功后切换步骤。
  final VoidCallback onNext;

  @override
  State<EmailAddressStep> createState() => _EmailAddressStepState();
}

final class _EmailAddressStepState extends State<EmailAddressStep> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.controller.email.value,
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(27, 12, 27, 32),
    children: [
      LoginBackButton(onPressed: widget.onBack),
      const SizedBox(height: 52),
      const Text('Your Email', style: AppTypography.pageTitle),
      const SizedBox(height: 48),
      Container(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.pill,
          color: AppColors.primaryLight,
        ),
        alignment: Alignment.centerLeft,
        constraints: const BoxConstraints(minHeight: 65),
        child: Obx(
          () => TextField(
            controller: _textController,
            // 每次挂载邮箱步骤自动进入输入；退出前景由页面壳排除焦点。
            autofocus: true,
            enabled: !widget.controller.sendingCode.value,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onSubmitted: (_) => widget.onNext(),
            onChanged: (value) => widget.controller.email.value = value,
            decoration: const InputDecoration(
              hintText: 'Please enter your email',
              hintStyle: TextStyle(
                color: AppColors.textOnAccent,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 18,
              ),
              border: InputBorder.none,
              fillColor: Colors.transparent,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.surfaceDark,
            ),
          ),
        ),
      ),
      const SizedBox(height: 71),
      Obx(
        () => AuthSubmitButton(
          label: 'Next',
          isLoading: widget.controller.sendingCode.value,
          onPressed: widget.controller.sendingCode.value ? null : widget.onNext,
        ),
      ),
      const SizedBox(height: 27),
      LoginTermsText(controller: widget.controller, emailStep: true),
      const SizedBox(height: 20),
      LoginFailureMessage(controller: widget.controller),
    ],
  );
}
