// 应用初始化页面：在配置前置条件满足前阻止进入主应用。
import 'dart:async';

import 'package:cyberskin_app/core/extensions/string_extensions.dart';
import 'package:cyberskin_app/core/theme/app_colors.dart';
import 'package:cyberskin_app/core/widgets/app_image.dart';
import 'package:cyberskin_app/core/widgets/app_lottie_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'init_controller.dart';

/// 初始化页入口，负责展示阻塞等待、错误重试和后台刷新状态。
final class InitPage extends GetView<InitController> {
  /// 创建初始化页。
  const InitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          const AppLottieBackground(playbackSpeed: 1.5),

          Positioned.fill(
            child: Obx(() {
              final status = controller.status.value;
              if (status == InitStatus.failed) {
                return Center(
                  child: _InitFailureState(
                    message: controller.failure.value?.message ?? '无法加载应用配置。',
                    onRetry: controller.retry,
                  ),
                );
              }
              return const _InitLoadingState();
            }),
          ),
        ],
      ),
    );
  }
}

/// 正在读取缓存或等待远端配置时的加载状态。
///
/// Logo 的流光持续循环，提示启动仍在进行；底部进度指示器只在等待超过两秒后
/// 出现，避免正常快速启动时产生多余视觉噪音。
final class _InitLoadingState extends StatefulWidget {
  const _InitLoadingState();

  @override
  State<_InitLoadingState> createState() => _InitLoadingStateState();
}

final class _InitLoadingStateState extends State<_InitLoadingState>
    with SingleTickerProviderStateMixin {
  static const Duration _progressIndicatorDelay = Duration(seconds: 2);

  /// 流光每轮从慢速起步并逐渐加速，避免匀速扫过显得生硬。
  static const Curve _shimmerCurve = Curves.easeInOutQuad;

  late final AnimationController _shimmerController;
  late final CurvedAnimation _shimmerAnimation;
  Timer? _progressIndicatorTimer;
  bool _showProgressIndicator = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: _shimmerCurve,
    );
    _progressIndicatorTimer = Timer(_progressIndicatorDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _showProgressIndicator = true);
    });
  }

  @override
  void dispose() {
    _progressIndicatorTimer?.cancel();
    _shimmerAnimation.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(child: _buildShimmerLogo()),
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _showProgressIndicator
                ? const Row(
                    key: ValueKey('init_loading_progress_indicator'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Loading···'),
                    ],
                  )
                : const SizedBox.shrink(
                    key: ValueKey('init_loading_progress_placeholder'),
                  ),
          ),
        ),
      ],
    );
  }

  /// 用 Logo 自身透明度裁切移动渐变，只让高光扫过图形，不覆盖透明画布区域。
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
              return ShaderMask(
                key: const ValueKey('init_loading_shimmer'),
                // 以 PNG alpha 作为遮罩，只把主题色高光绘制在 Logo 轮廓内。
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  final center = (_shimmerAnimation.value * 3) - 1.5;
                  return LinearGradient(
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
                  ).createShader(bounds);
                },
                child: child,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 首次配置不可用时提供的阻塞错误状态。
final class _InitFailureState extends StatelessWidget {
  const _InitFailureState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
