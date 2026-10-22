// 节奏详情预览与运行页；返回不停止会话，完成保留详情供重新开始。
import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/services/rhythm_playback.dart';
import '../../rhythm_session_controller.dart';
import '../../widgets/rhythm_dialogs.dart';
import '../../widgets/rhythm_page_frame.dart';
import '../../widgets/rhythm_surface.dart';
import 'widgets/rhythm_segment_queue.dart';
import 'widgets/rhythm_timer.dart';

/// 展示独立执行会话，返回不会停止设备。
final class RhythmInfoPage extends StatefulWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmInfoPage({super.key});
  @override
  State<RhythmInfoPage> createState() => _RhythmInfoPageState();
}

final class _RhythmInfoPageState extends State<RhythmInfoPage> {
  final session = Get.find<RhythmSessionController>();
  @override
  void dispose() {
    session.leaveInfo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RhythmPageFrame(
    onBack: () => Get.back<void>(),
    trailing: AppLiquidGlassButton(
      label: 'Edit',
      leadingIcon: Icons.edit_outlined,
      height: 32,
      iconSize: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      variant: AppLiquidGlassButtonVariant.translucent,
      onPressed: () async {
        final rhythm = session.infoRhythm.value;
        if (rhythm != null &&
            await openRhythmEditor(rhythm: rhythm) &&
            mounted) {
          Get.back<void>();
        }
      },
    ),
    body: ListView(
      children: [
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final overlap =
                constraints.maxWidth >= 340 &&
                MediaQuery.textScalerOf(context).scale(16) <= 21;
            final timer = Obx(
              () => RhythmTimer(seconds: session.infoTotalRemaining.value),
            );
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    '${session.target.value?.name ?? 'Device'} · ${session.target.value == null ? 'Disconnected' : 'Connected'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (!overlap)
                  Align(alignment: Alignment.centerRight, child: timer),
                const SizedBox(height: 18),
                Padding(
                  padding: EdgeInsets.only(right: overlap ? 140 : 0),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.infoRhythm.value?.name ?? 'Custom rhythm',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total segments: ${session.infoRhythm.value?.segments.length ?? 0}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppRhythmStyle.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() => RhythmError(session.infoError.value)),
                Obx(() {
                  final rhythm = session.infoRhythm.value;

                  final index = session.infoIndex.value;
                  if (rhythm == null || index >= rhythm.segments.length) {
                    return const SizedBox.shrink();
                  }
                  return RhythmSegmentQueue(
                    rhythm: rhythm,
                    index: index,
                    remaining: session.infoRemaining.value,
                    phase: session.infoPhase.value,
                    capabilities: session.capabilities.toList(),
                  );
                }),
              ],
            );
            return overlap
                ? Stack(
                    children: [
                      content,
                      Positioned(top: 12, right: 16, child: timer),
                    ],
                  )
                : content;
          },
        ),
        Obx(
          () =>
              session.infoPhase.value == RhythmPlaybackPhase.paused ||
                  session.infoPhase.value == RhythmPlaybackPhase.interrupted
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Progress saved. Return to the rhythm list to resume.',
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
    footer: Obx(() {
      final active =
          session.infoPhase.value == RhythmPlaybackPhase.running ||
          session.infoPhase.value == RhythmPlaybackPhase.paused ||
          session.infoPhase.value == RhythmPlaybackPhase.interrupted;
      final label = active
          ? 'Stop'
          : session.infoFinished.value
          ? 'Restart'
          : 'Start';
      return AppLiquidGlassButton(
        label: label,
        isLoading: session.infoBusy.value || session.busy.value,
        width: double.infinity,
        height: MediaQuery.textScalerOf(context).scale(20) > 26 ? 104 : 58,
        onPressed: session.toggleInfo,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      );
    }),
  );
}
