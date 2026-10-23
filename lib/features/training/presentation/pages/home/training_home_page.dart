// 训练列表页：刷新保留旧内容、首次错峰入场及列表到详情 Hero。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../app/app_routes.dart';
import '../../../../../core/widgets/app_list_entrance.dart';
import '../../training_route_arguments.dart';
import '../../widgets/training_page_frame.dart';
import '../../widgets/training_title.dart';
import 'training_home_controller.dart';
import 'widgets/training_list_tile.dart';

/// 已发布训练目录，列表返回时保留运行会话。
final class TrainingHomePage extends StatefulWidget {
  /// 创建已发布训练目录，列表返回时保留运行会话。
  const TrainingHomePage({super.key});
  @override
  State<TrainingHomePage> createState() => _TrainingHomePageState();
}

final class _TrainingHomePageState extends State<TrainingHomePage> {
  final controller = Get.find<TrainingHomeController>();
  final _seen = <int>{};
  @override
  Widget build(BuildContext context) => TrainingPageFrame(
    body: RefreshIndicator(
      onRefresh: controller.load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: TrainingTitle(
              title: 'Training mode',
              tag: TrainingRouteArguments.headingHeroTag,
              fontSize: 28,
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(
              () => Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 18),
                child: Text(
                  '${controller.target.value?.name ?? 'Device'} · ${controller.target.value == null ? 'Disconnected' : 'Connected'}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFCBC8D6),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(
              () => controller.loading.value
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: Obx(
              () => controller.error.value == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text(
                            controller.error.value!,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: controller.load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          Obx(() {
            final courses = controller.trainings.toList(growable: false);
            if (courses.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    controller.loading.value
                        ? 'Loading training courses…'
                        : controller.error.value == null
                        ? 'No training courses for this device yet.'
                        : '',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SliverList.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];

                /// 包含入口及课程身份的 Hero 标签。
                final tag = TrainingRouteArguments.titleTag('list', course.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppListEntrance(
                    key: ValueKey(course.id),
                    animate: course.id != null && _seen.add(course.id!),
                    index: index,
                    child: TrainingListTile(
                      training: course,
                      heroTag: tag,
                      onTap: () {
                        if (course.id != null) {
                          unawaited(
                            Get.toNamed<void>(
                              AppRoutes.trainingInfoPath(course.id!),
                              arguments: TrainingRouteArguments(
                                summary: course,
                                titleHeroTag: tag,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          }),
          const SliverPadding(padding: EdgeInsets.only(bottom: 112)),
        ],
      ),
    ),
  );
}
