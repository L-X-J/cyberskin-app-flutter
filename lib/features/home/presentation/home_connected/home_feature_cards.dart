// 主页功能模式入口网格与卡片组件。
import 'dart:async';
import 'dart:math' as math;

import 'package:cyberskin_app/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_img_group_80_card.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../control/free_control/presentation/widgets/free_control_title.dart';

/// 功能入口网格；平铺展示自由控制与自定义节奏模式入口卡片。
final class HomeFeatureGrid extends StatelessWidget {
  /// 创建功能模式入口网格。
  const HomeFeatureGrid({
    super.key,
    required this.fadeAnimation,
    this.onFreeControl,
    this.onCustomRhythm,
  });

  /// 淡入动画（0 -> 1）。
  final Animation<double> fadeAnimation;

  /// 打开自由控制模式回调；为空时采用默认路由导航。
  final VoidCallback? onFreeControl;

  /// 打开自定义节奏模式回调。
  final VoidCallback? onCustomRhythm;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Row(
        children: [
          Expanded(
            child: HomeFeatureCard(
              title: 'Free control\nmode',
              titleChild: const FreeControlTitle(
                compact: true,
                style: AppTypography.bodyMedium,
              ),
              flipOnNavigation: true,
              colors: const [Color(0xFFE4472A), Color(0xFF8E171A)],
              onTap:
                  onFreeControl ??
                  () => unawaited(Get.toNamed(AppRoutes.freeControl)),
              preview: AppImage.load('control/img_group_15'.assetsSvg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HomeFeatureCard(
              title: 'Customrhythm',
              colors: const [Color(0xFFBEF77A), Color(0xFF4B9C58)],
              onTap: onCustomRhythm,
              preview: AppImage.load('control/Group_5'.assetsSvg),
            ),
          ),
        ],
      ),
    );
  }
}

/// 功能入口卡片；提供带背景微光质感与右侧跳转按钮的原子卡片。
final class HomeFeatureCard extends StatefulWidget {
  /// 创建功能入口卡片。
  const HomeFeatureCard({
    super.key,
    required this.title,
    required this.colors,
    this.preview,
    this.onTap,
    this.titleChild,
    this.flipOnNavigation = false,
  });

  /// 卡片标题。
  final String title;

  /// 可选的共享元素标题；与卡片表面分离以保持 Hero 的轴对齐边界。
  final Widget? titleChild;

  /// 是否跟随下一路由的进度翻转卡片表面。
  final bool flipOnNavigation;

  /// 卡片主题渐变/背景色。
  final List<Color> colors;

  /// 卡片底部预览部件。
  final Widget? preview;

  /// 点击回调。
  final VoidCallback? onTap;

  @override
  State<HomeFeatureCard> createState() => _HomeFeatureCardState();
}

final class _HomeFeatureCardState extends State<HomeFeatureCard> {
  Animation<double>? _routeAnimation;
  bool _flipRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.secondaryAnimation;
    if (animation == _routeAnimation) return;
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _routeAnimation = animation;
    _routeAnimation?.addStatusListener(_onRouteStatus);
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _flipRequested) {
      setState(() => _flipRequested = false);
    }
  }

  void _onTap() {
    if (widget.onTap == null) return;
    if (widget.flipOnNavigation && !MediaQuery.disableAnimationsOf(context)) {
      setState(() => _flipRequested = true);
    }
    widget.onTap!();
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppImgGroup80Card(
      height: 170,
      backgroundColor: widget.colors.first,
      accentColor: widget.colors.first,
      child: Stack(
        children: [
          if (widget.preview != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              height: 66,
              child: widget.preview!,
            ),
          Positioned(
            right: 20,
            top: 24,
            child: AppLiquidGlassButton(
              label: 'Open model',
              icon: Icons.chevron_right,
              onPressed: widget.onTap == null ? null : _onTap,
              variant: AppLiquidGlassButtonVariant.translucent,
              iconSize: 16,
              height: 20,
              width: 20,
              borderRadius: 10,
            ),
          ),
        ],
      ),
    );
    final routeAnimation = _routeAnimation;
    final animateSurface =
        _flipRequested &&
        !MediaQuery.disableAnimationsOf(context) &&
        routeAnimation != null;

    return GestureDetector(
      onTap: widget.onTap == null ? null : _onTap,
      child: SizedBox(
        height: 170,
        child: Stack(
          children: [
            if (animateSurface)
              AnimatedBuilder(
                animation: routeAnimation,
                child: surface,
                builder: (context, child) {
                  final t = const Interval(
                    0,
                    0.65,
                    curve: Curves.easeInOutCubic,
                  ).transform(routeAnimation.value);
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(-math.pi / 2 * t),
                    child: Opacity(opacity: 1 - t, child: child),
                  );
                },
              )
            else
              surface,
            Positioned(
              left: 20,
              right: 50,
              top: 24,
              child:
                  widget.titleChild ??
                  Text(widget.title, style: AppTypography.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
