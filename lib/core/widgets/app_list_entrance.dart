// 列表条目首次出现时淡入上移；完成后保持终态，不响应刷新重播。
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 页面记录已经出现的 ID，本组件仅管理一次有限时长的局部动画。
final class AppListEntrance extends StatefulWidget {
  /// 创建入场包装，列表重建不重置进度。
  const AppListEntrance({
    super.key,
    required this.animate,
    required this.index,
    required this.child,
  });

  /// 该条目在本页面是否首次出现。
  final bool animate;

  /// 错峰序号，延迟最多五级。
  final int index;

  /// 不携带业务状态的内容子树。
  final Widget child;

  @override
  State<AppListEntrance> createState() => _AppListEntranceState();
}

final class _AppListEntranceState extends State<AppListEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _progress;

  @override
  void initState() {
    super.initState();
    final delay = math.min(widget.index, 5) * 45;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 360 + delay),
      value: widget.animate ? 0 : 1,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / (360 + delay), 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _progress,
    child: AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, 24 * (1 - _progress.value)),
        child: child,
      ),
    ),
  );
}
