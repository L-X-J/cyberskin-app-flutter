// 训练预览与运行详情；页面只展示状态，返回后全局控件继续控制同一会话。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';

import '../../../../../core/result/result.dart';
import '../../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../../control/domain/services/device_program_playback.dart';
import '../../../domain/repositories/training_repository.dart';
import '../../training_route_arguments.dart';
import '../../training_session_controller.dart';
import '../../widgets/training_page_frame.dart';
import '../../widgets/training_title.dart';
import 'widgets/training_timer.dart';

/// 课程预览、运行与重启详情页面。
final class TrainingInfoPage extends StatefulWidget {
  /// 创建课程预览、运行与重启详情页面。
  const TrainingInfoPage({super.key});
  @override
  State<TrainingInfoPage> createState() => _TrainingInfoPageState();
}

final class _TrainingInfoPageState extends State<TrainingInfoPage> {
  final session = Get.find<TrainingSessionController>();
  late final String _heroTag;
  late final int _selectionVersion;
  @override
  void initState() {
    super.initState();
    final args = Get.arguments is TrainingRouteArguments
        ? Get.arguments as TrainingRouteArguments
        : null;
    final id = int.tryParse(Get.parameters['id'] ?? '') ?? args?.summary?.id;
    _heroTag =
        args?.titleHeroTag ?? TrainingRouteArguments.titleTag('direct', id);
    unawaited(session.select(id ?? -1, initial: args?.summary));
    _selectionVersion = session.selectionVersion;
  }

  @override
  void dispose() {
    session.leaveInfo(expectedSelection: _selectionVersion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) session.leaveInfo(expectedSelection: _selectionVersion);
    },
    child: TrainingPageFrame(
      body: ListView(
        children: [
          Obx(
            () => TrainingTitle(
              title: session.summary.value?.nameEn ?? 'Training',
              tag: _heroTag,
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              '${session.target.value?.name ?? 'Device'} · ${session.target.value == null ? 'Disconnected' : 'Connected'}',
              style: const TextStyle(fontSize: 16, color: Color(0xFFCBC8D6)),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final detail = session.detail.value;
            final summary = detail?.purposeSummary;
            final url = detail?.purposeUrl;
            return InkWell(
              onTap: url == null || url.isEmpty ? null : () => _purpose(url),
              borderRadius: BorderRadius.circular(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          summary?.isNotEmpty == true
                              ? summary!
                              : 'Training purpose',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFCECADC),
                          ),
                        ),
                      ),
                      if (url != null && url.isNotEmpty)
                        const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Center(
            child: Obx(
              () => TrainingTimer(
                remaining: session.remaining.value,
                total: session.summary.value?.totalSeconds ?? 0,
              ),
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(16) > 23;
              final metrics = [
                Obx(
                  () => TrainingMetric(
                    label: 'Time',
                    value: trainingTime(session.remaining.value),
                  ),
                ),
                Obx(
                  () => TrainingMetric(
                    label: 'Intensity',
                    value: session.summary.value?.intensity ?? '—',
                  ),
                ),
                Obx(
                  () => TrainingMetric(
                    label: 'Minutes',
                    value: session.summary.value?.minutesLabel ?? '—',
                  ),
                ),
              ];
              return narrow
                  ? Column(
                      children: [
                        for (final metric in metrics)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: metric,
                            ),
                          ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < metrics.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(child: metrics[i]),
                        ],
                      ],
                    );
            },
          ),
          Obx(
            () => session.loading.value
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => session.error.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        children: [
                          Text(
                            session.error.value!,
                            textAlign: TextAlign.center,
                          ),
                          if (!session.ready.value && !session.loading.value)
                            TextButton(
                              onPressed: session.retry,
                              child: const Text('Retry'),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          Obx(
            () =>
                session.phase.value == DeviceProgramPlaybackPhase.paused ||
                    session.phase.value ==
                        DeviceProgramPlaybackPhase.interrupted
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Progress saved. Return to use the floating control to resume.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
        ],
      ),
      footer: Obx(() {
        /// 首页内容标签当前是否可见。
        final active = switch (session.phase.value) {
          DeviceProgramPlaybackPhase.running ||
          DeviceProgramPlaybackPhase.paused ||
          DeviceProgramPlaybackPhase.interrupted => true,
          _ => false,
        };

        /// 统计项名称。
        final label = active
            ? 'Stop'
            : session.finished.value
            ? 'Restart'
            : 'Start';
        return AppLiquidGlassButton(
          label: label,
          width: double.infinity,
          height: MediaQuery.textScalerOf(context).scale(20) > 26 ? 88 : 58,
          isLoading: session.busy.value,
          onPressed: session.loading.value || !session.ready.value
              ? null
              : session.toggle,
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        );
      }),
    ),
  );
  void _purpose(String url) {
    Get.dialog<void>(
      Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * .75,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Training purpose',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Get.back<void>(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: _TrainingPurposeContent(
                      url: url,
                      repository: session.repository,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 弹窗打开后固定正文地址；失败时仅重试当前课程的公开文件。
final class _TrainingPurposeContent extends StatefulWidget {
  const _TrainingPurposeContent({required this.url, required this.repository});

  final String url;
  final TrainingRepository repository;

  @override
  State<_TrainingPurposeContent> createState() =>
      _TrainingPurposeContentState();
}

final class _TrainingPurposeContentState
    extends State<_TrainingPurposeContent> {
  late Future<Result<String>> _result;

  @override
  void initState() {
    super.initState();
    _result = widget.repository.loadPurpose(widget.url);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Result<String>>(
    future: _result,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final result = snapshot.data!;
      if (result.isFailure) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.failureOrNull!.message),
            TextButton(
              onPressed: () => setState(() {
                _result = widget.repository.loadPurpose(widget.url);
              }),
              child: const Text('Retry'),
            ),
          ],
        );
      }
      return HtmlWidget(result.valueOrNull!);
    },
  );
}
