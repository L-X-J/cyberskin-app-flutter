// 初始化页离场与下一页进入的路由动画。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 初始化页被下一页覆盖时的离场动画。
///
/// 初始化页通过 [secondaryAnimation] 感知下一页入栈，从原尺寸放大到 1.08 倍并淡出。
final class InitRouteTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final exitAnimation = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0).animate(exitAnimation),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.08).animate(exitAnimation),
        alignment: alignment ?? Alignment.center,
        child: child,
      ),
    );
  }
}

/// 设备主页的进入动画，替代 GetX 默认的侧滑转场。
final class DeviceRouteTransition extends CustomTransition {
  /// 创建设备主页进入转场。
  DeviceRouteTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enterAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: enterAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(enterAnimation),
        alignment: alignment ?? Alignment.center,
        child: child,
      ),
    );
  }
}
