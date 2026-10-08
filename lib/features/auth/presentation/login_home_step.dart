// 登录方式首页：展示品牌素材、第三方登录和邮箱流程入口。
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_image.dart';
import 'login_controller.dart';
import 'login_failure_message.dart';
import 'login_terms_text.dart';

/// 登录首页的前景内容，不创建路由或背景。
final class LoginHomeStep extends StatelessWidget {
  /// 创建登录方式首页。
  const LoginHomeStep({
    super.key,
    required this.controller,
    required this.onEmail,
  });

  /// 登录与协议事件入口。
  final LoginController controller;

  /// 进入邮箱地址步骤。
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          children: [
            const SizedBox(height: 179),
            AppImage.load('icons_logo.png'.assetsPng, width: 267),
            const SizedBox(height: 113),
            _LoginActionButton(
              assetName: 'auth/login_apple_button.png',
              semanticLabel: 'Sign up with Apple',
              onPressed: () => unawaited(controller.signInWithApple()),
            ),
            const SizedBox(height: 23),
            _LoginActionButton(
              assetName: 'auth/login_google_button.png',
              semanticLabel: 'Sign up with Google',
              onPressed: () => unawaited(controller.signInWithGoogle()),
            ),
            const SizedBox(height: 23),
            _LoginActionButton(
              assetName: 'auth/login_email_button.png',
              semanticLabel: 'Continue with email',
              onPressed: onEmail,
            ),
            const SizedBox(height: 61),
            LoginTermsText(controller: controller),
            const SizedBox(height: 20),
            LoginFailureMessage(controller: controller),
          ],
        ),
      ),
    ),
  );
}

/// 首页登录入口保留 Ardot 导出的正式 PNG。
final class _LoginActionButton extends StatelessWidget {
  const _LoginActionButton({
    required this.assetName,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String assetName;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: SizedBox(
      width: 293,
      height: 66,
      child: ClipRRect(
        borderRadius: AppRadius.pill,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Image.asset(
              assetName.assetsPng,
              width: 293,
              height: 66,
              fit: BoxFit.fill,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ),
  );
}
