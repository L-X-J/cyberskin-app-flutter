// 公共双层渐变卡片：按明确图层顺序绘制底色、内阴影和上层渐变。
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_blur.dart';
import '../theme/app_layered_gradient_style.dart';
import '../theme/app_radius.dart';

/// 可跨业务域复用的双层渐变卡片表面。
///
/// 底层先绘制 [baseColor] 和真正的内阴影；上层再绘制径向渐变，并使用
/// [topLayerBlur] 模糊渐变层。组件只负责表面和尺寸约束，交互与业务内容
/// 由 [child] 提供。
final class AppLayeredGradientCard extends StatelessWidget {
  /// 创建双层渐变卡片。
  const AppLayeredGradientCard({
    super.key,
    required this.child,
    required this.baseColor,
    this.topGradientColors,
    this.topGradientStops = const [0.0, 1.0],
    this.topGradientCenter = AppLayeredGradientStyle.gradientCenter,
    this.topGradientRadius = AppLayeredGradientStyle.gradientRadius,
    this.topLayerBlur = AppLayeredGradientStyle.layerBlur,
    this.innerShadowColor = AppLayeredGradientStyle.innerShadowColor,
    this.innerShadowBlur = AppLayeredGradientStyle.innerShadowBlur,
    this.innerShadowOffset = AppLayeredGradientStyle.innerShadowOffset,
    this.innerShadowOpacity = 1,
    this.borderRadius = AppRadius.card,
    this.height,
  }) : assert(topGradientRadius > 0),
       assert(topLayerBlur >= 0),
       assert(innerShadowBlur >= 0),
       assert(innerShadowOpacity >= 0 && innerShadowOpacity <= 1);

  /// 卡片内部内容。
  final Widget child;

  /// 底层纯色填充。
  final Color baseColor;

  /// 上层径向渐变颜色；为空时由黑色过渡至 [baseColor]。
  final List<Color>? topGradientColors;

  /// 上层径向渐变停止点。
  final List<double> topGradientStops;

  /// 上层径向渐变中心。
  final Alignment topGradientCenter;

  /// 上层径向渐变半径。
  final double topGradientRadius;

  /// 上层渐变层的设计 blur 值，映射为 Flutter 的 sigma。
  final double topLayerBlur;

  /// 底层内阴影颜色。
  final Color innerShadowColor;

  /// 底层内阴影的设计 blur 值。
  final double innerShadowBlur;

  /// 底层内阴影偏移。
  final Offset innerShadowOffset;

  /// 底层内阴影不透明度。
  final double innerShadowOpacity;

  /// 卡片圆角。
  final BorderRadius borderRadius;

  /// 固定高度；为空时由子内容决定高度。
  final double? height;

  @override
  Widget build(BuildContext context) {
    assert(topGradientColors == null || topGradientColors!.length >= 2);
    assert((topGradientColors?.length ?? 2) == topGradientStops.length);
    final expand = height != null;
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: expand ? StackFit.expand : StackFit.passthrough,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LayeredGradientCardPainter(
                  baseColor: baseColor,
                  topGradientColors:
                      topGradientColors ??
                      [AppLayeredGradientStyle.gradientStart, baseColor],
                  topGradientStops: topGradientStops,
                  topGradientCenter: topGradientCenter,
                  topGradientRadius: topGradientRadius,
                  topLayerBlur: topLayerBlur,
                  innerShadowColor: innerShadowColor,
                  innerShadowBlur: innerShadowBlur,
                  innerShadowOffset: innerShadowOffset,
                  innerShadowOpacity: innerShadowOpacity,
                  borderRadius: borderRadius,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// 双层渐变卡片的实际绘制器，保证底层永远先于上层绘制。
final class _LayeredGradientCardPainter extends CustomPainter {
  const _LayeredGradientCardPainter({
    required this.baseColor,
    required this.topGradientColors,
    required this.topGradientStops,
    required this.topGradientCenter,
    required this.topGradientRadius,
    required this.topLayerBlur,
    required this.innerShadowColor,
    required this.innerShadowBlur,
    required this.innerShadowOffset,
    required this.innerShadowOpacity,
    required this.borderRadius,
  });

  final Color baseColor;
  final List<Color> topGradientColors;
  final List<double> topGradientStops;
  final Alignment topGradientCenter;
  final double topGradientRadius;
  final double topLayerBlur;
  final Color innerShadowColor;
  final double innerShadowBlur;
  final Offset innerShadowOffset;
  final double innerShadowOpacity;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final shape = borderRadius.toRRect(Offset.zero & size);
    canvas.save();
    canvas.clipRRect(shape);

    canvas.drawRRect(shape, Paint()..color = baseColor);
    _paintInnerShadow(canvas, shape);
    _paintTopGradient(canvas, shape);

    canvas.restore();
  }

  /// 使用反向遮罩将模糊颜色限制在卡片内部，避免错误地绘制成外阴影。
  void _paintInnerShadow(Canvas canvas, RRect shape) {
    final sigma = innerShadowBlur * AppBlur.flutterSigmaScale;
    final offset = innerShadowOffset;
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(shape.outerRect.inflate(sigma * 4 + offset.distance + 1))
      ..addRRect(shape.shift(offset));
    final paint = Paint()
      ..color = innerShadowColor.withValues(
        alpha: innerShadowColor.a * innerShadowOpacity,
      );
    if (sigma > 0) {
      paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma);
    }
    canvas.drawPath(mask, paint);
  }

  /// 将上层渐变作为独立图层模糊，再覆盖到底层之上。
  void _paintTopGradient(Canvas canvas, RRect shape) {
    final layerBounds = shape.outerRect;
    // 仅模糊渐变图层，内容在滤镜外绘制；圆角边缘的 alpha 让底层透出。
    canvas.saveLayer(
      layerBounds,
      Paint()..imageFilter = AppBlur.layerFilter(topLayerBlur),
    );
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = RadialGradient(
          center: topGradientCenter,
          radius: topGradientRadius,
          colors: topGradientColors,
          stops: topGradientStops,
        ).createShader(layerBounds),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LayeredGradientCardPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        !listEquals(oldDelegate.topGradientColors, topGradientColors) ||
        !listEquals(oldDelegate.topGradientStops, topGradientStops) ||
        oldDelegate.topGradientCenter != topGradientCenter ||
        oldDelegate.topGradientRadius != topGradientRadius ||
        oldDelegate.topLayerBlur != topLayerBlur ||
        oldDelegate.innerShadowColor != innerShadowColor ||
        oldDelegate.innerShadowBlur != innerShadowBlur ||
        oldDelegate.innerShadowOffset != innerShadowOffset ||
        oldDelegate.innerShadowOpacity != innerShadowOpacity ||
        oldDelegate.borderRadius != borderRadius;
  }
}
