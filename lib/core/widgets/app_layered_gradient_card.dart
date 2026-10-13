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
    this.topGradientRadius,
    this.topGradientAspectRatio = 0.7,
    this.topGradientOffsetY = AppLayeredGradientStyle.gradientOffsetY,
    this.topLayerBlur = AppLayeredGradientStyle.layerBlur,
    this.innerShadowColor = AppLayeredGradientStyle.innerShadowColor,
    this.innerShadowBlur = AppLayeredGradientStyle.innerShadowBlur,
    this.innerShadowOffset = AppLayeredGradientStyle.innerShadowOffset,
    this.innerShadowSpread = 0,
    this.innerShadowOpacity = 1,
    this.borderRadius = AppRadius.card,
    this.height,
  }) : assert(topGradientRadius == null || topGradientRadius > 0),
       assert(topGradientAspectRatio == null || topGradientAspectRatio > 0),
       assert(topLayerBlur >= 0),
       assert(innerShadowBlur >= 0),
       assert(innerShadowSpread >= 0),
       assert(innerShadowOpacity >= 0 && innerShadowOpacity <= 1);

  /// 使用扫描卡已确认的配色、色标与阴影；尺寸仍由布局和内容决定。
  const AppLayeredGradientCard.scan({
    Key? key,
    required Widget child,
    double? height,
  }) : this(
         key: key,
         child: child,
         height: height,
         baseColor: AppScanCardStyle.baseColor,
         topGradientColors: AppScanCardStyle.gradientColors,
         topGradientStops: AppScanCardStyle.gradientStops,
         topGradientCenter: AppScanCardStyle.gradientCenter,
         topGradientRadius: AppScanCardStyle.gradientRadius,
         topGradientAspectRatio: AppScanCardStyle.gradientAspectRatio,
         topGradientOffsetY: AppScanCardStyle.gradientOffsetY,
         topLayerBlur: AppScanCardStyle.layerBlur,
         innerShadowColor: AppScanCardStyle.innerShadowColor,
         innerShadowBlur: AppScanCardStyle.innerShadowBlur,
         innerShadowOffset: AppScanCardStyle.innerShadowOffset,
         innerShadowSpread: AppScanCardStyle.innerShadowSpread,
         innerShadowOpacity: AppScanCardStyle.innerShadowOpacity,
       );

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

  /// 上层径向渐变半径；为空时自动按卡片高度与短边精准匹配 Figma 契约。
  final double? topGradientRadius;

  /// 上层径向渐变横纵比；为空时自动按卡片宽高比精准匹配 Figma 契约。
  final double? topGradientAspectRatio;

  /// 上层径向渐变垂直向下平移的逻辑像素。
  final double topGradientOffsetY;

  /// 上层渐变层的设计 blur 值，映射为 Flutter 的 sigma。
  final double topLayerBlur;

  /// 底层内阴影颜色。
  final Color innerShadowColor;

  /// 底层内阴影的设计 blur 值。
  final double innerShadowBlur;

  /// 底层内阴影偏移。
  final Offset innerShadowOffset;

  /// 内阴影向内扩散的逻辑像素；默认零，保持其他卡片原有表面。
  final double innerShadowSpread;

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
                  topGradientAspectRatio: topGradientAspectRatio,
                  topGradientOffsetY: topGradientOffsetY,
                  topLayerBlur: topLayerBlur,
                  innerShadowColor: innerShadowColor,
                  innerShadowBlur: innerShadowBlur,
                  innerShadowOffset: innerShadowOffset,
                  innerShadowSpread: innerShadowSpread,
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
    required this.topGradientAspectRatio,
    required this.topGradientOffsetY,
    required this.topLayerBlur,
    required this.innerShadowColor,
    required this.innerShadowBlur,
    required this.innerShadowOffset,
    required this.innerShadowSpread,
    required this.innerShadowOpacity,
    required this.borderRadius,
  });

  final Color baseColor;
  final List<Color> topGradientColors;
  final List<double> topGradientStops;
  final Alignment topGradientCenter;
  final double? topGradientRadius;
  final double? topGradientAspectRatio;
  final double topGradientOffsetY;
  final double topLayerBlur;
  final Color innerShadowColor;
  final double innerShadowBlur;
  final Offset innerShadowOffset;
  final double innerShadowSpread;
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
    // 内阴影的正扩散收缩透明孔洞，使白色遮罩向内部延伸。
    // 极小卡片限制收缩量，避免产生负尺寸的 RRect。
    final spread = innerShadowSpread.clamp(
      0.0,
      shape.outerRect.shortestSide / 2,
    );
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(shape.outerRect.inflate(sigma * 4 + offset.distance + 1))
      ..addRRect(shape.deflate(spread).shift(offset));
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
    final effectiveRadius =
        topGradientRadius ??
        (layerBounds.shortestSide > 0
            ? layerBounds.height / layerBounds.shortestSide
            : 1.0);
    final effectiveAspectRatio =
        topGradientAspectRatio ??
        (layerBounds.height > 0 ? layerBounds.width / layerBounds.height : 1.0);

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
          radius: effectiveRadius,
          transform: (effectiveAspectRatio == 1 && topGradientOffsetY == 0)
              ? null
              : _TopGradientTransform(
                  aspectRatio: effectiveAspectRatio,
                  offsetY: topGradientOffsetY,
                  alignment: topGradientCenter,
                ),
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
        oldDelegate.topGradientAspectRatio != topGradientAspectRatio ||
        oldDelegate.topGradientOffsetY != topGradientOffsetY ||
        oldDelegate.topLayerBlur != topLayerBlur ||
        oldDelegate.innerShadowColor != innerShadowColor ||
        oldDelegate.innerShadowBlur != innerShadowBlur ||
        oldDelegate.innerShadowOffset != innerShadowOffset ||
        oldDelegate.innerShadowSpread != innerShadowSpread ||
        oldDelegate.innerShadowOpacity != innerShadowOpacity ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// 在着色器坐标内变换径向渐变：以渐变中心为轴心横轴拉伸（椭圆）及垂直平移。
final class _TopGradientTransform extends GradientTransform {
  const _TopGradientTransform({
    required this.aspectRatio,
    required this.offsetY,
    required this.alignment,
  });

  final double aspectRatio;
  final double offsetY;
  final Alignment alignment;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = alignment.withinRect(bounds);
    final matrix = Matrix4.identity();
    if (aspectRatio != 1) {
      matrix
        ..translateByDouble(center.dx, center.dy, 0, 1)
        ..scaleByDouble(aspectRatio, 1, 1, 1)
        ..translateByDouble(-center.dx, -center.dy, 0, 1);
    }
    if (offsetY != 0) {
      // 在矩阵变换后加上着色器坐标平移 offsetY，使 Canvas 上的渐变图案向下平移 offsetY 逻辑像素。
      matrix.translateByDouble(0, offsetY, 0, 1);
    }
    return matrix;
  }
}
