// 首页真实训练推荐；只展示第一条摘要，More 进入完整列表。
import 'package:flutter/material.dart';

import '../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../training/domain/entities/training.dart';
import '../../../training/presentation/training_route_arguments.dart';
import '../../../training/presentation/widgets/training_title.dart';
import 'compact_glass_button.dart';
import 'home_training_background.dart';

/// 首页训练推荐，空列表不展示示例课程。
final class HomeTrainingCard extends StatelessWidget {
  /// 创建当前组件的实例。
  const HomeTrainingCard({
    super.key,
    required this.fadeAnimation,
    this.training,
    this.onMore,
    this.onTraining,
    this.entry = 'home',
  });

  /// 父级首次入场淡入进度。
  final Animation<double> fadeAnimation;

  /// 首页首条真实课程摘要；为空时展示空态。
  final TrainingSummary? training;

  /// 进入推荐课程预览的回调。
  final VoidCallback? onMore, onTraining;

  /// 推荐卡片的路由入口身份。
  final String entry;
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: fadeAnimation,
    child: HomeTrainingBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: TrainingTitle(
                    title: 'Training mode',
                    tag: TrainingRouteArguments.headingHeroTag,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(width: 8),
                CompactGlassButton(
                  label: 'More',
                  icon: Icons.grid_view_rounded,
                  onPressed: onMore,
                  width: 80,
                  height: 23,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (training case final course?)
              AppGlassCard(
                child: InkWell(
                  onTap: onTraining,
                  borderRadius: BorderRadius.circular(26),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        AppImage.load(
                          course.coverUrl,
                          width: 44,
                          height: 44,
                          radius: 10,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(
                            Icons.fitness_center,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 创建共享元素转场的训练标题；入口和课程共同定义 tag。的实例。
                              TrainingTitle(
                                title: course.nameEn ?? 'Training',
                                tag: TrainingRouteArguments.titleTag(
                                  entry,
                                  course.id,
                                ),
                                fontSize: 12,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${course.minutesLabel} minutes · ${course.stageCount ?? 0} stages · Intensity ${course.intensity ?? '—'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFC9C6D7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Text(
                'No training courses available.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
      ),
    ),
  );
}
