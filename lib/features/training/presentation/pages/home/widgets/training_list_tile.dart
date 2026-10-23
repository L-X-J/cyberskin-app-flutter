// 训练摘要玻璃条目，封面和强度均使用发布数据。
import 'package:flutter/material.dart';

import '../../../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../../../core/widgets/app_image.dart';
import '../../../../domain/entities/training.dart';
import '../../../widgets/training_title.dart';

/// 展示服务端课程封面、名称、时长和强度的玻璃列表项。
final class TrainingListTile extends StatelessWidget {
  /// 创建展示服务端课程封面、名称、时长和强度的玻璃列表项。
  const TrainingListTile({
    super.key,
    required this.training,
    required this.heroTag,
    required this.onTap,
  });

  /// 首页首条真实课程摘要；为空时展示空态。
  final TrainingSummary training;

  /// 课程标题的共享元素身份。
  final String heroTag;

  /// 用户点击课程后的路由回调。
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppGlassCard(
    child: InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AppImage.load(
              training.coverUrl,
              width: 40,
              height: 40,
              radius: 9,
              fit: BoxFit.cover,
              errorWidget: const Icon(
                Icons.fitness_center,
                color: Colors.white54,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 创建共享元素转场的训练标题；入口和课程共同定义 tag。
                  TrainingTitle(
                    title: training.nameEn ?? 'Training',
                    tag: heroTag,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${training.minutesLabel} minutes · ${training.stageCount ?? 0} stages · Intensity ${training.intensity ?? '—'}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFC5C3D4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
