// 片段弹层通道编辑组件；仅回传草稿，不直接控制设备。
import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/buttons/liquid_glass_switch.dart';

import '../../../../domain/entities/rhythm_program.dart';
import '../../../widgets/rhythm_segment_card.dart';
import '../../../widgets/rhythm_surface.dart';
import 'rhythm_slider.dart';

/// 依据单通道能力展示模式及速度，修改只回传草稿。
final class RhythmChannelEditor extends StatelessWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmChannelEditor({
    super.key,
    required this.capability,
    required this.setting,
    required this.onChanged,
  });

  /// 该通道对应的已发布能力。
  final RhythmChannelCapability capability;

  /// 当前片段的通道草稿。
  final RhythmChannelSetting setting;

  /// 将用户选择回传给草稿所有者。
  final ValueChanged<RhythmChannelSetting> onChanged;

  @override
  Widget build(BuildContext context) => RhythmSurface(
    padding: const EdgeInsets.fromLTRB(15, 17, 15, 20),
    child: AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              RhythmChannelIcon(capability.channel),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  capability.channel.label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              LGSwitch(
                value: setting.on,
                activeColor: AppRhythmStyle.pink,
                inactiveColor: AppRhythmStyle.pink,
                thumbColor: const Color(0xFF790A7F),
                onChanged: (value) => onChanged(setting.copyWith(on: value)),
              ),
            ],
          ),
          if (setting.on && capability.modes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 22),
              child: _RhythmModes(
                capability: capability,
                setting: setting,
                onChanged: onChanged,
              ),
            ),
          if (setting.on &&
              capability.channel != RhythmChannel.suck &&
              (capability.variableSpeed || (capability.gearMax ?? 0) > 0))
            Row(
              children: [
                const Text('Speed', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 11),
                Expanded(
                  child: RhythmSlider(
                    value: (setting.value ?? 0).toDouble(),
                    min: 0,
                    max: 100,
                    divisions: capability.variableSpeed
                        ? 100
                        : capability.gearMax,
                    trackHeight: 20,
                    activeColor: const Color(0xFF841184),
                    inactiveColor: AppRhythmStyle.glass,
                    thumbRadius: 18,
                    rightLabel: 'fast',
                    onChanged: (v) =>
                        onChanged(setting.copyWith(value: v.round())),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

/// 折叠仅影响展示，不修改通道草稿；隐藏项不进入交互或语义树。
final class _RhythmModes extends StatefulWidget {
  const _RhythmModes({
    required this.capability,
    required this.setting,
    required this.onChanged,
  });

  final RhythmChannelCapability capability;
  final RhythmChannelSetting setting;
  final ValueChanged<RhythmChannelSetting> onChanged;

  @override
  State<_RhythmModes> createState() => _RhythmModesState();
}

final class _RhythmModesState extends State<_RhythmModes> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = TextStyle(
        fontSize: 14,
        color: Colors.white,
        decoration: TextDecoration.none,
        fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
      );
      // 显式指定测量宽度，确保首行判定和玻璃按钮实际布局使用同一尺寸。
      final widths = <double>[];
      var firstRowCount = 0;
      var usedWidth = 0.0;
      var firstRowFull = false;
      var height = 42.0;
      for (final label in widget.capability.modes) {
        final painter = TextPainter(
          text: TextSpan(text: label, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final width = (painter.width.ceilToDouble() + 48).clamp(
          0.0,
          constraints.maxWidth,
        );
        height = height < painter.height + 16 ? painter.height + 16 : height;
        painter.dispose();
        widths.add(width);
        final nextWidth = usedWidth + (firstRowCount == 0 ? 0 : 4) + width;
        if (!firstRowFull && nextWidth <= constraints.maxWidth) {
          firstRowCount++;
          usedWidth = nextWidth;
        } else {
          firstRowFull = true;
        }
      }
      final overflows = firstRowCount < widths.length;

      Widget modeButton(int i) => AppLiquidGlassButton(
        label: widget.capability.modes[i],
        width: widths[i],
        height: height,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18),
        textStyle: style,
        fillColorOverride: widget.setting.mode == i + 1
            ? AppRhythmStyle.pink
            : null,
        variant: widget.setting.mode == i + 1
            ? AppLiquidGlassButtonVariant.highlighted
            : AppLiquidGlassButtonVariant.translucent,
        onPressed: () => widget.onChanged(
          widget.setting.copyWith(
            mode: i + 1,
            clearMode: widget.setting.mode == i + 1,
          ),
        ),
      );

      // 列表铺满可用宽度；箭头作为独立叠层，不参与模式测量和换行。
      return Stack(
        children: [
          SizedBox(
            width: constraints.maxWidth,
            child: Padding(
              padding: EdgeInsets.only(
                top: overflows && height < 48 ? (48 - height) / 2 : 0,
                bottom: overflows && height < 48 ? (48 - height) / 2 : 0,
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 6,
                children: [
                  for (
                    var i = 0;
                    i < (_expanded ? widths.length : firstRowCount);
                    i++
                  )
                    modeButton(i),
                ],
              ),
            ),
          ),
          if (overflows)
            Positioned(
              right: 0,
              top: height > 48 ? (height - 48) / 2 : 0,
              width: 48,
              child: IconButton(
                tooltip: _expanded ? 'Collapse modes' : 'Expand modes',
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ),
            ),
        ],
      );
    },
  );
}
