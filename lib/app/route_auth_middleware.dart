// 应用命名路由的集中认证保护。
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'app_routes.dart';
import 'session_controller.dart';

/// 为受保护页面提供统一的启动中和匿名访问处理。
final class RouteAuthMiddleware extends GetMiddleware {
  /// 创建路由认证 Middleware。
  RouteAuthMiddleware();

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionController>()) {
      return const RouteSettings(name: AppRoutes.init);
    }
    final session = Get.find<SessionController>();
    return switch (session.state.value) {
      SessionState.starting => const RouteSettings(name: AppRoutes.init),
      SessionState.anonymous => const RouteSettings(name: AppRoutes.login),
      SessionState.authenticated => null,
    };
  }
}
