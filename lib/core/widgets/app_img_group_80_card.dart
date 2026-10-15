// img_group_80 视觉背景卡片：用 Canvas 绘制可配置颜色的统一设备/模式背景。
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 复用 `img_group_80_2.svg` 视觉的背景卡片。
///
/// 组件只负责背景表面和尺寸约束；标题、图片、按钮等业务内容由 [child]
/// 叠加。 [backgroundColor] 对应外层底色，[accentColor] 对应顶部径向渐变
/// 的结束色；当调用方只提供一个颜色时，两者保持一致。
final class AppImgGroup80Card extends StatelessWidget {
  /// 创建 img_group_80 背景卡片。
  const AppImgGroup80Card({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.accentColor,
    this.innerShadowColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.height,
  });

  /// 卡片上层内容。
  final Widget child;

  /// 外层底色。
  final Color backgroundColor;

  /// 顶部径向渐变结束色；为空时复用 [backgroundColor]。
  final Color? accentColor;

  /// 内阴影颜色；为空时从 [accentColor] 向白色提亮得到。
  final Color? innerShadowColor;

  /// 卡片圆角。
  final BorderRadius borderRadius;

  /// 固定高度；为空时由内容决定高度。
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accentColor ?? backgroundColor;
    final resolvedShadow =
        innerShadowColor ?? Color.lerp(resolvedAccent, Colors.white, 0.3)!;
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
                painter: _ImgGroup80Painter(
                  backgroundColor: backgroundColor,
                  accentColor: resolvedAccent,
                  innerShadowColor: resolvedShadow,
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

/// `img_group_80_2.svg` 的 Canvas 绘制实现。
final class _ImgGroup80Painter extends CustomPainter {
  const _ImgGroup80Painter({
    required this.backgroundColor,
    required this.accentColor,
    required this.innerShadowColor,
  });

  static const Size _designSize = Size.square(170);
  static const Color _iconColor = Color(0x66FFFFFF);
  static const Color _gradientStart = Colors.black;

  final Color backgroundColor;
  final Color accentColor;
  final Color innerShadowColor;

  @override
  /// 绘制固定设计坐标，并在父约束内保持等比缩放和居中。
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final scale = math.max(
      size.width / _designSize.width,
      size.height / _designSize.height,
    );
    final drawingSize = _designSize * scale;
    final translation = Offset(
      (size.width - drawingSize.width) / 2,
      (size.height - drawingSize.height) / 2,
    );
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 170, 170),
      const Radius.circular(32),
    );

    canvas.save();
    canvas.translate(translation.dx, translation.dy);
    canvas.scale(scale, scale);
    canvas.clipRRect(card);
    canvas.drawRRect(card, Paint()..color = backgroundColor);
    _paintInnerShadow(canvas, card);
    _paintRadialLayer(canvas);
    // _paintMeterSlots(canvas);
    // _paintIcons(canvas);
    canvas.restore();
  }

  /// 绘制 SVG `filter0_i` 对应的向下偏移内阴影。
  void _paintInnerShadow(Canvas canvas, RRect card) {
    final shadowPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(card.outerRect.inflate(41))
      ..addRRect(card.shift(const Offset(0, 1)));
    final shadowPaint = Paint()
      ..color = innerShadowColor
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);
    canvas.drawPath(shadowPath, shadowPaint);
  }

  /// 绘制 SVG `filter1_f` 对应的椭圆径向渐变与图层模糊。
  void _paintRadialLayer(Canvas canvas) {
    const gradientBounds = Rect.fromLTWH(0, 0, 170, 170);
    final gradientShape = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 3, 146, 155),
      const Radius.circular(36),
    );
    final gradient = RadialGradient(
      center: const Alignment(0, -0.9647059),
      radius: 155 / 170,
      colors: [_gradientStart, accentColor],
      stops: const [0, 1],
      transform: const _ImgGroup80GradientTransform(
        center: Alignment(0, -0.9647059),
        aspectRatio: 146 / 155,
      ),
    );
    canvas.saveLayer(
      gradientShape.outerRect.inflate(22),
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 7.05, sigmaY: 7.05),
    );
    canvas.drawRRect(
      gradientShape,
      Paint()..shader = gradient.createShader(gradientBounds),
    );
    canvas.restore();
  }

  /// 绘制底部三行四列的半透明圆角槽位。
  void _paintMeterSlots(Canvas canvas) {
    const columns = <(double, double)>[(21, 28), (54, 29), (87, 29), (121, 28)];
    const rows = <(double, double)>[(104, 0.08), (119, 0.18), (134, 0.27)];
    for (final row in rows) {
      for (final column in columns) {
        final slot = RRect.fromRectAndRadius(
          Rect.fromLTWH(column.$1, row.$1, column.$2, 12),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          slot,
          Paint()..color = Colors.white.withValues(alpha: row.$2),
        );
      }
    }
  }

  @override
  /// 颜色、圆角或尺寸契约变化时重新绘制背景。
  bool shouldRepaint(covariant _ImgGroup80Painter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.innerShadowColor != innerShadowColor;
}

/// 绘制 SVG 径向渐变的横向椭圆变换。
final class _ImgGroup80GradientTransform extends GradientTransform {
  const _ImgGroup80GradientTransform({
    required this.center,
    required this.aspectRatio,
  });

  final Alignment center;
  final double aspectRatio;

  @override
  /// 在渐变中心周围压缩横轴，模拟 SVG 的椭圆渐变变换。
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final alignmentCenter = center.withinRect(bounds);
    return Matrix4.identity()
      ..translateByDouble(alignmentCenter.dx, alignmentCenter.dy, 0, 1)
      ..scaleByDouble(aspectRatio, 1, 1, 1)
      ..translateByDouble(-alignmentCenter.dx, -alignmentCenter.dy, 0, 1);
  }
}
