// 应用级悬浮位置与路由策略；不持有设备业务状态或执行设备指令。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 页面显式声明的控件可见性与拖动策略。
enum FloatingControlPolicy {
  /// 底部右侧固定，禁止拖动。
  fixed,

  /// 可在安全内容区域内拖动。
  draggable,

  /// 登录、启动、全屏播放或模态弹窗不显示。
  hidden,
}

/// 管理单实例宿主位置；位置仅在会话内保留，不进入持久化或领域模型。
final class FloatingControlController extends GetxController {
  /// 当前页面策略，与设备状态独立变化。
  final Rx<FloatingControlPolicy> policy = FloatingControlPolicy.hidden.obs;

  /// Scaffold 布局后报告的真实全局内容区域，已排除栏位和键盘。
  final Rxn<Rect> bodyBounds = Rxn<Rect>();

  /// 用户拖动的全局左上角；为空时使用右下停靠点。
  final Rxn<Offset> draggedPosition = Rxn<Offset>();

  /// 拖动期间关闭定位动画，避免手指与控件位置产生滞后。
  final RxBool isDragging = false.obs;

  /// 媒体全屏临时覆盖路由策略，退出后继续使用观察者维护的原策略。
  final RxBool mediaFullscreen = false.obs;

  final Map<Route<dynamic>, Rect> _pageBounds = {};
  Route<dynamic>? _activeRoute;
  Size _controlSize = const Size(126, 68);

  /// 根据路由观察结果切换策略；首次布局前沿用旧区域以保留归位动画。
  void activatePage(
    Route<dynamic>? route, {
    required FloatingControlPolicy nextPolicy,
    bool resetPosition = false,
  }) {
    _activeRoute = route;
    isDragging.value = false;
    policy.value = nextPolicy;
    if (resetPosition) draggedPosition.value = null;
    final bounds = _pageBounds[route];
    if (bounds != null) {
      bodyBounds.value = bounds;
      _constrainStoredPosition();
    }
  }

  /// 只接受活动页面的布局更新；转场中的旧页面不能覆盖新页面区域。
  void reportPageBounds(Route<dynamic> route, Rect bounds) {
    _pageBounds[route] = bounds;
    if (route == _activeRoute) {
      bodyBounds.value = bounds;
      _constrainStoredPosition();
    }
  }

  /// 页面销毁时移除几何记录，不让路由引用在全局控制器中累积。
  void forgetPage(Route<dynamic> route) => _pageBounds.remove(route);

  /// 大字体改变控件尺寸后重新限制位置；宿主在布局后调用。
  void updateControlSize(Size size) {
    if (_controlSize == size) return;
    _controlSize = size;
    _constrainStoredPosition();
  }

  /// 计算可见目标位置；固定页面不使用二级页拖动坐标。
  Offset targetFor(Size size) {
    final bounds = bodyBounds.value;
    if (bounds == null) return Offset.zero;
    final dock = Offset(
      bounds.right - size.width - 24,
      bounds.bottom - size.height - 12,
    );
    return _clamp(
      policy.value == FloatingControlPolicy.draggable
          ? draggedPosition.value ?? dock
          : dock,
      bounds,
      size,
    );
  }

  /// 从当前实际绘制位置开始拖动，包括尚未结束的归位动画。
  void startDrag(Offset renderedPosition) {
    if (policy.value != FloatingControlPolicy.draggable) return;
    isDragging.value = true;
    draggedPosition.value = renderedPosition;
    _constrainStoredPosition();
  }

  /// 手势偏移只改变位置，不触发点击或设备状态更新。
  void dragBy(Offset delta) {
    if (!isDragging.value || policy.value != FloatingControlPolicy.draggable) {
      return;
    }
    draggedPosition.value =
        (draggedPosition.value ?? targetFor(_controlSize)) + delta;
    _constrainStoredPosition();
  }

  /// 松手保留位置，不吸附边缘。
  void endDrag() => isDragging.value = false;

  /// 几何变化后立即修正存储位置，避免恢复窗口时重新出现越界坐标。
  void _constrainStoredPosition() {
    final bounds = bodyBounds.value;
    final position = draggedPosition.value;
    if (bounds != null && position != null) {
      draggedPosition.value = _clamp(position, bounds, _controlSize);
    }
  }

  /// 对极小区域收缩边距；不会把控件推到内容区域之外。
  Offset _clamp(Offset position, Rect bounds, Size size) {
    final horizontal = math.min(
      24.0,
      math.max(0.0, (bounds.width - size.width) / 2),
    );
    final vertical = math.min(
      12.0,
      math.max(0.0, (bounds.height - size.height) / 2),
    );
    final minX = bounds.left + horizontal;
    final minY = bounds.top + vertical;
    return Offset(
      position.dx.clamp(
        minX,
        math.max(minX, bounds.right - size.width - horizontal),
      ),
      position.dy.clamp(
        minY,
        math.max(minY, bounds.bottom - size.height - vertical),
      ),
    );
  }
}

/// 观察完整路由栈，包括原生/Material 弹窗，保证控件不浮在模态层之上。
final class FloatingControlObserver extends NavigatorObserver {
  /// 未声明路由默认隐藏，二级页必须显式声明策略。
  FloatingControlObserver({required this.policies, required this.resetRoutes});

  /// 命名路由的显式可见性和拖动策略。
  final Map<String, FloatingControlPolicy> policies;

  /// 返回时清除拖动位置的路由集合。
  final Set<String> resetRoutes;
  final List<Route<dynamic>> _routes = [];

  /// 推送页面或模态路由后同步最上层策略。
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _sync();
  }

  /// 系统返回与 GetX 返回遵循相同策略。
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _forget(route);
    _sync();
  }

  /// off/offAll 移除路由时同步剩余路由，而不是猜测返回目标。
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _forget(route);
    _sync();
  }

  /// 替换路由保留其栈位置。
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (index >= 0) {
      if (newRoute == null) {
        _routes.removeAt(index);
      } else {
        _routes[index] = newRoute;
      }
    }
    if (oldRoute != null) _forget(oldRoute);
    _sync();
  }

  /// 已移除路由立即释放记录，后续 dispose 再次清理也安全。
  void _forget(Route<dynamic> route) {
    if (Get.isRegistered<FloatingControlController>()) {
      Get.find<FloatingControlController>().forgetPage(route);
    }
  }

  /// PopupRoute 上方不绘制控件，避免跨 Navigator 的模态点击穿透。
  void _sync() {
    if (!Get.isRegistered<FloatingControlController>()) return;
    final route = _routes.isEmpty ? null : _routes.last;
    Get.find<FloatingControlController>().activatePage(
      route,
      nextPolicy: route == null || route is PopupRoute<dynamic>
          ? FloatingControlPolicy.hidden
          : policies[route.settings.name] ?? FloatingControlPolicy.hidden,
      resetPosition: route != null && resetRoutes.contains(route.settings.name),
    );
  }
}
