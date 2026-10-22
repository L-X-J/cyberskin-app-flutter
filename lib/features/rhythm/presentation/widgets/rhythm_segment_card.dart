// 编辑与运行页共用的片段摘要、通道图标和参数标签。
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_rhythm_style.dart';
import '../../domain/entities/rhythm.dart';
import '../../domain/entities/rhythm_program.dart';
import 'rhythm_surface.dart';

/// 使用设计稿导出的通道图标。
final class RhythmChannelIcon extends StatelessWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmChannelIcon(this.channel, {super.key, this.size = 24});

  /// 对应的运动通道。
  final RhythmChannel channel;

  /// 运行卡采用较紧凑的图标，编辑卡保留完整图标尺寸。
  final double size;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/images/rhythm/${channel == RhythmChannel.thrust ? 'stretch' : channel.name}.svg',
    width: size,
    height: size,
  );
}

/// 复用片段摘要，编辑和运行状态由参数明确区分。
final class RhythmSegmentCard extends StatelessWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmSegmentCard({
    super.key,
    required this.segment,
    required this.capabilities,
    this.onDelete,
    this.onEdit,
    this.nextIn,
    this.remainingSeconds,
    this.running = false,
  });

  /// 待展示的不可变片段。
  final RhythmSegment segment;

  /// 所选型号支持的通道和模式。
  final List<RhythmChannelCapability> capabilities;

  /// 编辑页删除及修改入口；运行页不传。
  final VoidCallback? onDelete, onEdit;

  /// 下一片段切换倒计时；最后一段不展示。
  final int? nextIn;

  /// 当前片段剩余秒数；下一片段预览为空，展示完整时长。
  final int? remainingSeconds;

  /// 运行态使用高亮摘要及倒计时。
  final bool running;
  @override
  Widget build(BuildContext context) {
    RhythmStep step;
    try {
      step = RhythmStep.decode(segment);
    } on FormatException catch (e) {
      return RhythmSurface(
        child: Column(
          children: [
            Text(e.message),
            if (onDelete != null)
              TextButton(
                onPressed: onDelete,
                child: const Text('Delete segment'),
              ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: onEdit,
      child: RhythmSurface(
        padding: running ? const EdgeInsets.all(16) : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    running
                        ? 'This clip lasts for ${remainingSeconds ?? step.durationSec}s'
                        : 'Duration ${step.durationSec}s',
                    style: TextStyle(
                      fontSize: 14,
                      color: running ? Colors.white : AppRhythmStyle.secondary,
                    ),
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Delete segment',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppRhythmStyle.secondary,
                    ),
                  ),
              ],
            ),
            SizedBox(height: running ? 20 : 22),
            if (!step.channels.any((c) => c.on))
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Rest · All channels off'),
              ),
            for (final setting in step.channels.where((c) => c.on))
              Padding(
                padding: EdgeInsets.only(bottom: running ? 14 : 18),
                child: _ChannelSummary(setting, capabilities, compact: running),
              ),
            if (nextIn != null)
              Center(
                child: Text(
                  'Next segment in ${nextIn}s',
                  style: const TextStyle(
                    color: AppRhythmStyle.secondary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _ChannelSummary extends StatelessWidget {
  const _ChannelSummary(
    this.setting,
    this.capabilities, {
    this.compact = false,
  });

  final bool compact;

  /// 当前片段的通道草稿。
  final RhythmChannelSetting setting;

  /// 所选型号支持的通道和模式。
  final List<RhythmChannelCapability> capabilities;
  @override
  Widget build(BuildContext context) {
    final matches = capabilities.where((c) => c.channel == setting.channel);
    final cap = matches.isEmpty ? null : matches.first;

    final mode = setting.mode;
    final tags = <String>[
      if (mode != null)
        cap != null && mode <= cap.modes.length
            ? cap.modes[mode - 1]
            : 'Mode $mode',
      if (setting.value != null) 'Speed ${setting.value}%',
      if (mode == null && setting.value == null) 'Turn on',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RhythmChannelIcon(setting.channel, size: compact ? 14 : 24),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                setting.channel.label,
                style: TextStyle(fontSize: compact ? 14 : 16),
              ),
              for (final tag in tags)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 5 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppRhythmStyle.chip,
                    borderRadius: BorderRadius.circular(compact ? 8 : 18),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
