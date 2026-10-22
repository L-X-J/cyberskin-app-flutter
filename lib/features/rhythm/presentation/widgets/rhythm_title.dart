// 首页入口与节奏列表共享的 Hero 标题，尊重系统减少动态效果。
import 'package:flutter/material.dart';

/// 共享元素只拥有文字展示，不触发路由或设备操作。
final class RhythmTitle extends StatelessWidget {
  /// 创建标题；入口两行、列表按可用空间自然换行。
  const RhythmTitle({super.key, required this.style, this.compact = false});

  /// 当前页面的终态样式。
  final TextStyle style;

  /// 首页入口的两行排版。
  final bool compact;

  /// 两端使用相同标签，不能由 Controller 持有动画。
  static const heroTag = 'custom-rhythm-title';

  @override
  Widget build(BuildContext context) => HeroMode(
    enabled: !MediaQuery.disableAnimationsOf(context),
    child: Hero(
      tag: heroTag,
      createRectTween: (begin, end) => RectTween(begin: begin, end: end),
      flightShuttleBuilder: _flight,
      child: Text(compact ? 'Custom\nrhythm' : 'Custom rhythm', style: style),
    ),
  );

  /// 单独移动 rhythm 字组，避免飞行边界变化导致突然换行。
  static Widget _flight(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final from = (fromContext.widget as Hero).child as Text;
    final to = (toContext.widget as Hero).child as Text;
    final pushing = direction == HeroFlightDirection.push;
    final compact = pushing ? from : to;
    final expanded = pushing ? to : from;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(animation.value);
        final style = TextStyle.lerp(
          compact.style,
          expanded.style,
          t,
        )!.copyWith(decoration: TextDecoration.none);
        final painter = TextPainter(
          text: TextSpan(text: 'Custom ', style: style),
          textDirection: Directionality.of(toContext),
          textScaler: MediaQuery.textScalerOf(toContext),
        )..layout();
        final offset = Offset(painter.width * t, painter.height * (1 - t));
        painter.dispose();
        return DefaultTextStyle(
          style: style,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const PositionedDirectional(
                start: 0,
                top: 0,
                child: Text('Custom', softWrap: false),
              ),
              PositionedDirectional(
                start: offset.dx,
                top: offset.dy,
                child: const Text('rhythm', softWrap: false),
              ),
            ],
          ),
        );
      },
    );
  }
}
