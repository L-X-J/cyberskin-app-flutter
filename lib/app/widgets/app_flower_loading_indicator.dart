// 应用级花形加载指示器：提供不承载交互或语义的持续旋转视觉反馈。
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 应用壳与一级页面可复用的花形加载指示器。
///
/// 组件只表达进行中的等待状态，不处理点击、焦点或无障碍语义；承载它的
/// 页面组件需要自行提供操作语义与状态说明。
final class AppFlowerLoadingIndicator extends StatefulWidget {
  /// 创建花形加载指示器。
  const AppFlowerLoadingIndicator({
    super.key,
    this.size = 32,
    this.color = Colors.white,
  }) : assert(size > 0);

  /// 花形的正方形边长。
  final double size;

  /// 花瓣绘制颜色。
  final Color color;

  @override
  State<AppFlowerLoadingIndicator> createState() =>
      _AppFlowerLoadingIndicatorState();
}

final class _AppFlowerLoadingIndicatorState
    extends State<AppFlowerLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RotationTransition(
          turns: _rotationController,
          child: SizedBox.square(
            dimension: widget.size,
            child: CustomPaint(painter: _FlowerPainter(color: widget.color)),
          ),
        ),
      ),
    );
  }
}

/// 绘制八瓣花形，保持中心留白以让旋转轨迹清晰可辨。
final class _FlowerPainter extends CustomPainter {
  const _FlowerPainter({required this.color});

  static const int _petalCount = 8;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final shortestSide = size.shortestSide;
    final center = size.center(Offset.zero);
    final petalWidth = shortestSide * 0.18;
    final petalHeight = shortestSide * 0.38;
    final radius = shortestSide * 0.22;
    final petal = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius),
        width: petalWidth,
        height: petalHeight,
      ),
      Radius.circular(petalWidth / 2),
    );
    final paint = Paint()..color = color;

    for (var index = 0; index < _petalCount; index++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(index * math.pi * 2 / _petalCount);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawRRect(petal, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FlowerPainter oldDelegate) =>
      oldDelegate.color != color;
}
