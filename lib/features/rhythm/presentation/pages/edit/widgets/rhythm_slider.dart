// 节奏编辑器滑杆：原生交互配合始终透明的玻璃胶囊与轨道右端标签。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

/// 仅处理展示与交互的速度滑杆；范围和步进由调用方的设备能力决定。
///
/// 原生 Slider 保留键盘、辅助功能、点击和拖动，玻璃层不参与命中测试。
final class RhythmSlider extends StatefulWidget {
  /// 创建受控滑杆；回调为空时禁用。
  const RhythmSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.divisions,
    required this.activeColor,
    required this.inactiveColor,
    this.trackHeight = 20,
    this.thumbRadius = 18,
    this.rightLabel,
  }) : assert(max > min),
       assert(value >= min && value <= max),
       assert(divisions == null || divisions > 0),
       assert(trackHeight > 0),
       assert(thumbRadius > 0);

  /// 调用方持有的当前值。
  final double value;

  /// 交互回调；不在组件内部保存业务值。
  final ValueChanged<double>? onChanged;

  /// 开始点击或拖动时通知调用方。
  final ValueChanged<double>? onChangeStart;

  /// 完成点击或拖动时通知调用方。
  final ValueChanged<double>? onChangeEnd;

  /// 能力决定的范围与离散步进。
  final double min;

  /// 允许的最大值。
  final double max;

  /// 离散档数；为空时连续变化。
  final int? divisions;

  /// 活动段和剩余段的颜色。
  final Color activeColor;

  /// 未填充轨道的颜色。
  final Color inactiveColor;

  /// 轨道逻辑高度。
  final double trackHeight;

  /// 胶囊几何基准，沿用原滑杆的宽高比例。
  final double thumbRadius;

  /// 叠放在轨道物理右端，不占用轨道宽度且不拦截交互。
  final String? rightLabel;

  @override
  State<RhythmSlider> createState() => _RhythmSliderState();
}

final class _RhythmSliderState extends State<RhythmSlider> {
  static const _maxThumbScale = 1.15;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final preferredThumbWidth = widget.thumbRadius * 2.6;
    final thumbHeight = widget.thumbRadius * 1.6;
    final labelStyle = Theme.of(context).textTheme.labelSmall!
        .copyWith(fontSize: 10);
    final textScaler = MediaQuery.textScalerOf(context);
    final height = math.max(
      math.max(48.0, thumbHeight * 1.2 + 16),
      textScaler.scale(labelStyle.fontSize!) * (labelStyle.height ?? 1.5) + 16,
    );
    final normalized = (widget.value - widget.min) / (widget.max - widget.min);
    final fraction = Directionality.of(context) == TextDirection.rtl
        ? 1 - normalized
        : normalized;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 视觉轨道铺满组件；缩放与原生中心行程共用同一动画值，
          // 让两端静止时伸出 4 像素，按下/释放的每一帧也不超过此边界。
          final thumbWidth = math.min(
            preferredThumbWidth,
            constraints.maxWidth / _maxThumbScale,
          );
          return TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 1,
              end: _dragging && widget.onChanged != null ? _maxThumbScale : 1,
            ),
            duration: const Duration(milliseconds: 10),
            builder: (context, scale, child) {
              final inset = math.max(0.0, thumbWidth * scale / 2 - 4);
              final trackWidth = math.max(
                0.0,
                constraints.maxWidth - 2 * inset,
              );
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: widget.trackHeight,
                        trackShape: _RhythmTrackShape(inset, fraction),
                        thumbShape: _GlassThumbSpace(thumbWidth, thumbHeight),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 24,
                        ),
                        activeTrackColor: widget.activeColor,
                        inactiveTrackColor: widget.inactiveColor,
                        disabledActiveTrackColor: widget.activeColor.withValues(
                          alpha: 0.4,
                        ),
                        disabledInactiveTrackColor: widget.inactiveColor,
                        activeTickMarkColor: Colors.transparent,
                        inactiveTickMarkColor: Colors.transparent,
                        showValueIndicator: ShowValueIndicator.never,
                      ),
                      child: Slider(
                        padding: EdgeInsets.zero,
                        value: widget.value,
                        min: widget.min,
                        max: widget.max,
                        divisions: widget.divisions,
                        onChanged: widget.onChanged,
                        onChangeStart: (value) {
                          setState(() => _dragging = true);
                          widget.onChangeStart?.call(value);
                        },
                        onChangeEnd: (value) {
                          setState(() => _dragging = false);
                          widget.onChangeEnd?.call(value);
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: inset + trackWidth * fraction - thumbWidth / 2,
                    width: thumbWidth,
                    height: thumbHeight,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: scale,
                        child: LiquidGlass.withOwnLayer(
                          fake: true,
                          shape: LiquidRoundedSuperellipse(
                            borderRadius: thumbHeight / 2 - 2,
                          ),
                          settings: const LiquidGlassSettings(
                            glassColor: Colors.transparent,
                            blur: 2,
                            thickness: 25,
                            refractiveIndex: 1.15,
                            lightIntensity: 1.8,
                            chromaticAberration: 0.2,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                  if (widget.rightLabel != null)
                    Positioned(
                      left: 4,
                      right: 4,
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: Text(
                            widget.rightLabel!,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// 透明原生拇指只提供交互几何；实际玻璃由不拦截事件的叠层绘制。
final class _GlassThumbSpace extends SliderComponentShape {
  const _GlassThumbSpace(this.width, this.height);
  final double width;
  final double height;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

/// 原生交互矩形仅定义中心行程；绘制轨道独立铺满组件的物理宽度。
final class _RhythmTrackShape extends RoundedRectSliderTrackShape {
  const _RhythmTrackShape(this.inset, this.fraction);
  final double inset;
  final double fraction;

  // 圆角只属于自绘视觉轨道；原生行程不得再为离散档位追加圆角留白，
  // 否则原生中心与玻璃错位，极窄行程还会产生无效的中心夹取区间。
  @override
  bool get isRounded => false;

  // 离散 Slider 内部会对位置补间；装饰胶囊由受控值驱动，填充也须使用
  // 同一即时位置，否则拖动开始的数帧中填充终点会落后于玻璃中心。
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final track = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final visualTrack = Rect.fromLTWH(
      offset.dx,
      track.top,
      parentBox.size.width,
      track.height,
    );
    final activeColor = ColorTween(
      begin: sliderTheme.disabledActiveTrackColor,
      end: sliderTheme.activeTrackColor,
    ).evaluate(enableAnimation)!;
    final inactiveColor = ColorTween(
      begin: sliderTheme.disabledInactiveTrackColor,
      end: sliderTheme.inactiveTrackColor,
    ).evaluate(enableAnimation)!;
    final isRtl = textDirection == TextDirection.rtl;
    final normalized = isRtl ? 1 - fraction : fraction;
    final center = track.left + track.width * fraction;
    // 最小值不绘制活动色，最大值铺满；中间值严格止于玻璃中心。
    final fillEdge = normalized <= 0
        ? (isRtl ? visualTrack.right : visualTrack.left)
        : normalized >= 1
        ? (isRtl ? visualTrack.left : visualTrack.right)
        : center;
    final canvas = context.canvas;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(visualTrack, Radius.circular(track.height / 2)),
    );
    canvas.drawRect(visualTrack, Paint()..color = inactiveColor);
    if (normalized > 0) {
      canvas.drawRect(
        Rect.fromLTRB(
          isRtl ? fillEdge : visualTrack.left,
          visualTrack.top,
          isRtl ? visualTrack.right : fillEdge,
          visualTrack.bottom,
        ),
        Paint()..color = activeColor,
      );
    }
    canvas.restore();
  }

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => Rect.fromLTWH(
    offset.dx + inset,
    offset.dy + (parentBox.size.height - sliderTheme.trackHeight!) / 2,
    math.max(0, parentBox.size.width - 2 * inset),
    sliderTheme.trackHeight!,
  );
}
