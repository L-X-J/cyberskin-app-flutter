// 壳层通过继承依赖提供页面观察器，局部轮播不隐藏全局可变单例。
import 'package:flutter/material.dart';

/// 提供当前 Navigator 的页面可见性事件；观察器由应用实例拥有。
final class AppRouteVisibility extends InheritedWidget {
  /// 绑定应用实例创建的观察器。
  const AppRouteVisibility({
    super.key,
    required this.observer,
    required super.child,
  });

  /// 当前 Navigator 注册的同一个页面观察器。
  final RouteObserver<PageRoute<dynamic>> observer;

  /// 无应用壳层时返回空，组件仍遵守自身标签和前后台状态。
  static RouteObserver<PageRoute<dynamic>>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AppRouteVisibility>()
      ?.observer;
  @override
  bool updateShouldNotify(AppRouteVisibility oldWidget) =>
      observer != oldWidget.observer;
}
