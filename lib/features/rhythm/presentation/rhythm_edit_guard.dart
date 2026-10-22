// 拦截绕过暂停确认的编辑器直达导航。
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../domain/services/rhythm_playback.dart';

/// 编辑页面必须通过统一入口取得暂停锁，深链不得直接解锁设备编辑。
final class RhythmEditGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) => Get.find<RhythmPlayback>().editing
      ? null
      : const RouteSettings(name: AppRoutes.rhythmHome);
}
