// GetX 路由日志适配器：把页面跳转转换为不含 arguments 的统一日志事件。
import 'package:get/get.dart';

import '../core/logging/app_log.dart';

/// 记录 GetX 页面路由变化。
abstract final class AppRouteLogger {
  /// 将 GetX 路由回调转换为统一日志；弹窗和 BottomSheet 不作为页面跳转记录。
  static void record(AppLog log, Routing? routing) {
    if (routing == null ||
        routing.isDialog == true ||
        routing.isBottomSheet == true) {
      return;
    }
    log.route(
      previous: routing.previous,
      current: routing.current,
      isBack: routing.isBack ?? false,
      removed: routing.removed,
      routeType: routing.route?.runtimeType.toString(),
    );
  }
}
