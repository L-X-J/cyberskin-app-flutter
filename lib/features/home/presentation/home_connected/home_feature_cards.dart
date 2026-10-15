// 主页功能模式入口网格与卡片组件。
import 'dart:async';

import 'package:cyberskin_app/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_img_group_80_card.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';

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
final class HomeFeatureCard extends StatelessWidget {
  /// 创建功能入口卡片。
  const HomeFeatureCard({
    super.key,
    required this.title,
    required this.colors,
    this.preview,
    this.onTap,
  });

  /// 卡片标题。
  final String title;

  /// 卡片主题渐变/背景色。
  final List<Color> colors;

  /// 卡片底部预览部件。
  final Widget? preview;

  /// 点击回调。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppImgGroup80Card(
        height: 170,
        backgroundColor: colors.first,
        accentColor: colors.first,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsGeometry.only(right: 30),
                    child: Text(title, style: AppTypography.bodyMedium),
                  ),
                  const Spacer(),
                  if (preview != null)
                    SizedBox(
                      height: 66,
                      width: double.infinity,
                      child: preview,
                    ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              top: 24,
              child: AppLiquidGlassButton(
                label: 'Open model',
                icon: Icons.chevron_right,
                onPressed: onTap,
                variant: AppLiquidGlassButtonVariant.translucent,
                iconSize: 16,
                height: 20,
                width: 20,
                borderRadius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
