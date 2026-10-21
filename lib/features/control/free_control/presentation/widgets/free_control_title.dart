// 自由控制入口与页面共享的标题；在跨路由飞行中连续插值字形位置与文字样式。
import 'package:flutter/material.dart';

/// 自由控制共享标题；卡片使用两行，页面使用单行，飞行过程中逐字组衔接。
final class FreeControlTitle extends StatelessWidget {
  /// 创建标题；[compact] 表示首页卡片的两行布局。
  const FreeControlTitle({
    super.key,
    required this.style,
    this.compact = false,
  });

  /// 标题在当前页面的终态文字样式。
  final TextStyle style;

  /// 是否显示首页入口的两行标题。
  final bool compact;

  static const _heroTag = 'free-control-mode-title';

  @override
  Widget build(BuildContext context) {
    return HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(
        tag: _heroTag,
        createRectTween: (begin, end) => RectTween(begin: begin, end: end),
        flightShuttleBuilder: _buildFlight,
        child: Text(
          compact ? 'Free control\nmode' : 'Free control mode',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }

  /// 将 mode 从第二行移至首行末尾，避免 Hero 尺寸变化时文本突然换行。
  static Widget _buildFlight(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final from = (fromContext.widget as Hero).child as Text;
    final to = (toContext.widget as Hero).child as Text;
    final pushing = direction == HeroFlightDirection.push;
    final compactText = pushing ? from : to;
    final expandedText = pushing ? to : from;
    final textDirection = Directionality.of(toContext);
    final textScaler = MediaQuery.textScalerOf(toContext);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(animation.value);
        final style = TextStyle.lerp(
          compactText.style,
          expandedText.style,
          t,
        )!.copyWith(decoration: TextDecoration.none);
        final painter = TextPainter(
          text: TextSpan(text: 'Free control ', style: style),
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout();
        final wordOffset = Offset(painter.width * t, painter.height * (1 - t));
        painter.dispose();
        return DefaultTextStyle(
          style: style,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const PositionedDirectional(
                start: 0,
                top: 0,
                child: Text('Free control', maxLines: 1, softWrap: false),
              ),
              PositionedDirectional(
                start: wordOffset.dx,
                top: wordOffset.dy,
                child: const Text('mode', maxLines: 1, softWrap: false),
              ),
            ],
          ),
        );
      },
    );
  }
}
