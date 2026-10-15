// 主页运营位与新品推荐广告卡片组件。
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_layered_gradient_card.dart';

/// 运营位与广告卡片；展示新品发布横幅与特性介绍。
final class HomeAdvertisementCard extends StatelessWidget {
  /// 创建运营位广告卡片。
  const HomeAdvertisementCard({super.key, required this.fadeAnimation});

  /// 淡入动画（0 -> 1）。
  final Animation<double> fadeAnimation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: AppLayeredGradientCard(
        height: 124,
        baseColor: const Color(0xFF2A2932),
        topGradientColors: const [Colors.black, Color(0xFF443149)],
        child: Stack(
          children: [
            Positioned.fill(
              child: AppImage.load(
                'assets/images/home/banner_device.png',
                fit: BoxFit.cover,
                radius: AppRadius.radiusCard,
                errorWidget: const ColoredBox(color: AppColors.surface),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.card,
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 24, 100, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The GalaxyVoy1', style: TextStyle(fontSize: 17)),
                  SizedBox(height: 4),
                  Text('New product launch', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 6),
                  Text(
                    '12 modes of vibration heating',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
