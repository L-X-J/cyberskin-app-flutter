// 登录方式首页：展示品牌素材、第三方登录和邮箱流程入口。
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_image.dart';
import 'login_controller.dart';
import 'login_failure_message.dart';
import 'login_terms_text.dart';

/// 登录首页的前景内容，不创建路由或背景。
final class LoginHomeStep extends StatefulWidget {
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
  State<LoginHomeStep> createState() => _LoginHomeStepState();
}

/// 登录首页的入场动画和 Logo 流光只在该前景挂载期间运行。
final class _LoginHomeStepState extends State<LoginHomeStep>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _shimmerController;
  late final CurvedAnimation _shimmerAnimation;
  late final CurvedAnimation _logoAnimation;
  late final List<CurvedAnimation> _buttonAnimations;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutQuad,
    );
    _logoAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.5, curve: Curves.easeInToLinear),
    );
    _buttonAnimations = List<CurvedAnimation>.generate(3, (index) {
      final start = 0.28 + (index * 0.16);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          start,
          (start + 0.48).clamp(0, 1),
          curve: Curves.easeOutCubic,
        ),
      );
    });
    // 首屏动画只播放一次；流光循环提示 Logo 仍是当前可交互入口。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _entranceController.value = 1;
        _shimmerController.value = 0;
      } else {
        _entranceController.forward();
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _shimmerAnimation.dispose();
    _logoAnimation.dispose();
    _shimmerController.dispose();
    for (final animation in _buttonAnimations) {
      animation.dispose();
    }
    _entranceController.dispose();
    super.dispose();
  }

  /// 构建带透明度裁切的 Logo 流光，避免高光覆盖透明画布。
  Widget _buildShimmerLogo() {
    return SizedBox(
      width: 267,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          AppImage.load('icons_logo.png'.assetsPng, width: 267),
          AnimatedBuilder(
            animation: _shimmerController,
            child: AppImage.load('icons_logo.png'.assetsPng, width: 267),
            builder: (context, child) {
              final center = (_shimmerAnimation.value * 3) - 1.5;
              return ShaderMask(
                key: const ValueKey('login_home_shimmer'),
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(center - 0.7, 0),
                  end: Alignment(center + 0.7, 0),
                  colors: [
                    Colors.transparent,
                    AppColors.primaryVariant.withValues(alpha: 0.2),
                    AppColors.primaryGlow,
                    AppColors.secondary,
                    AppColors.primaryLight,
                    Colors.transparent,
                  ],
                  stops: const [0, 0.3, 0.43, 0.52, 0.62, 1],
                ).createShader(bounds),
                child: child,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 为单个登录入口提供有界的交错入场区间。
  Widget _buildAnimatedButton({
    required int index,
    required String assetName,
    required String semanticLabel,
    required VoidCallback onPressed,
  }) {
    final animation = _buttonAnimations[index];
    return FadeTransition(
      opacity: animation,
      alwaysIncludeSemantics: true,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(animation),
        child: _LoginActionButton(
          assetName: assetName,
          semanticLabel: semanticLabel,
          onPressed: onPressed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          children: [
            const SizedBox(height: 179),
            FadeTransition(opacity: _logoAnimation, child: _buildShimmerLogo()),
            const SizedBox(height: 113),
            _buildAnimatedButton(
              index: 0,
              assetName: 'auth/login_apple_button.png',
              semanticLabel: 'Sign up with Apple',
              onPressed: () => unawaited(widget.controller.signInWithApple()),
            ),
            const SizedBox(height: 23),
            _buildAnimatedButton(
              index: 1,
              assetName: 'auth/login_google_button.png',
              semanticLabel: 'Sign up with Google',
              onPressed: () => unawaited(widget.controller.signInWithGoogle()),
            ),
            const SizedBox(height: 23),
            _buildAnimatedButton(
              index: 2,
              assetName: 'auth/login_email_button.png',
              semanticLabel: 'Continue with email',
              onPressed: widget.onEmail,
            ),
            const SizedBox(height: 61),
            LoginTermsText(controller: widget.controller),
            const SizedBox(height: 20),
            LoginFailureMessage(controller: widget.controller),
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
