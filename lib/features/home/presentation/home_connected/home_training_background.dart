// 首页训练卡片专属背景：按 SVG 绘制深蓝底、内发光与模糊菱形渐变。
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// 训练推荐背景，尺寸由内容决定，装饰独立映射到 SVG 的局部坐标。
final class HomeTrainingBackground extends StatelessWidget {
  /// 创建训练推荐背景，前景内容不参与背景滤镜。
  const HomeTrainingBackground({super.key, required this.child});

  /// 卡片前景内容。
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadius.card,
    child: CustomPaint(
      painter: const _TrainingBackgroundPainter(),
      child: child,
    ),
  );
}

/// SVG 使用四象限线性渐变形成菱形，不能用椭圆径向渐变替代。
final class _TrainingBackgroundPainter extends CustomPainter {
  const _TrainingBackgroundPainter();

  static const _referenceSize = Size(353, 136);
  static const _baseColor = Color(0xFF161B5B);
  static const _glowColors = [Color(0xFF6989FF), Color(0xFF080B33)];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final shape = AppRadius.card.toRRect(bounds);
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRRect(shape, Paint()..color = _baseColor);

    // 反向遮罩经 sigma 9 模糊后，仅保留 SVG 的白色内发光。
    final innerMask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(bounds.inflate(36))
      ..addRRect(shape);
    canvas.drawPath(
      innerMask,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // 仅缩放背景装饰，不限制内容高度或文字缩放。
    canvas.scale(
      size.width / _referenceSize.width,
      size.height / _referenceSize.height,
    );
    const glowBounds = Rect.fromLTWH(31, 21, 291, 94);
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 353, 136),
      Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    );
    canvas.clipRRect(
      RRect.fromRectAndRadius(glowBounds, const Radius.circular(47)),
    );
    canvas.translate(176.5, 68);
    for (final xDirection in const [-1.0, 1.0]) {
      for (final yDirection in const [-1.0, 1.0]) {
        canvas.save();
        canvas.scale(145.5 * xDirection, 47 * yDirection);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 1, 1),
          Paint()
            ..isAntiAlias = false
            ..shader = ui.Gradient.linear(
              Offset.zero,
              const Offset(0.5, 0.5),
              _glowColors,
            ),
        );
        canvas.restore();
      }
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TrainingBackgroundPainter oldDelegate) => false;
}
