// 主页训练模式推荐入口卡片组件。
import 'package:flutter/material.dart';

import '../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_layered_gradient_card.dart';
import 'compact_glass_button.dart';

/// 训练模式入口卡片；展示训练推荐内容与进入训练库入口。
final class HomeTrainingCard extends StatelessWidget {
  /// 创建训练模式卡片。
  const HomeTrainingCard({super.key, required this.fadeAnimation, this.onMore});

  /// 淡入动画（0 -> 1）。
  final Animation<double> fadeAnimation;

  /// 点击“查看更多”训练回调。
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: AppLayeredGradientCard(
        height: 136,
        baseColor: const Color(0xFF3A427D),
        topGradientColors: const [Colors.black, Color(0xFF46529D)],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Training mode', style: TextStyle(fontSize: 17)),
                  const Spacer(),
                  CompactGlassButton(
                    label: 'More',
                    icon: Icons.grid_view_rounded,
                    onPressed: onMore ?? () {},
                    width: 66,
                  ),
                ],
              ),
              const Spacer(),
              AppGlassCard(
                height: 62,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: AppImage.load(
                        'assets/images/home/training_thumb.png',
                        width: 44,
                        height: 44,
                        radius: 22,
                      ),
                    ),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rhythm Adaptation · Beginner's Guide",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '12 minutes · 4 stages · Low intensity',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
