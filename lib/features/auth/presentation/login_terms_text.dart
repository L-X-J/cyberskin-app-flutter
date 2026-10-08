// 登录协议文案：展示配置中的法律链接并管理点击识别器生命周期。
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'login_controller.dart';

/// 登录首页与邮箱步骤共享的协议说明。
final class LoginTermsText extends StatefulWidget {
  /// 创建协议文案，邮箱步骤使用 Continue 提示。
  const LoginTermsText({
    super.key,
    required this.controller,
    this.emailStep = false,
  });

  /// 配置链接和打开事件来源。
  final LoginController controller;

  /// 是否使用邮箱步骤文案。
  final bool emailStep;

  @override
  State<LoginTermsText> createState() => _LoginTermsTextState();
}

final class _LoginTermsTextState extends State<LoginTermsText> {
  late final TapGestureRecognizer _tosTap = TapGestureRecognizer()
    ..onTap = () => unawaited(widget.controller.openAgreement('tos'));
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () =>
        unawaited(widget.controller.openAgreement('privacy_policy'));

  @override
  void dispose() {
    _tosTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final hasTos = widget.controller.agreementUrls.containsKey('tos');
    final hasPrivacy = widget.controller.agreementUrls.containsKey(
      'privacy_policy',
    );
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: Color(0xFFE4E4E4),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 19 / 14,
        ),
        children: [
          TextSpan(
            text: widget.emailStep
                ? 'By tapping Continue, you are agreeing to\nour '
                : 'By continuing, you agree to our\n',
          ),
          TextSpan(
            text: 'Terms of Service',
            recognizer: hasTos ? _tosTap : null,
            style: TextStyle(
              decoration: hasTos
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: const Color(0xFFE4E4E4),
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            recognizer: hasPrivacy ? _privacyTap : null,
            style: TextStyle(
              decoration: hasPrivacy
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: const Color(0xFFE4E4E4),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  });
}
