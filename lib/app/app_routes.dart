// 应用壳层路由表：集中声明顶层页面及其依赖绑定，避免页面自行拼接路由。
import 'package:get/get.dart';

import '../features/device/presentation/device_home_page.dart';
import '../features/init/presentation/init_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/video/presentation/video_page.dart';
import 'bindings/device_binding.dart';
import 'bindings/init_binding.dart';
import 'init_route_transition.dart';

/// 归属于应用壳层的命名路由。
abstract final class AppRoutes {
  /// 应用启动初始化路由。
  static const String init = '/init';

  /// 设备主页路由。
  static const String device = '/device';

  /// 视频主页路由。
  static const String video = '/video';

  /// 从设备主页进入的用户资料路由。
  static const String profile = '/profile';

  /// 所有顶层路由及其局部依赖绑定。
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: init,
      page: () => const InitPage(),
      binding: InitBinding(),
      customTransition: InitRouteTransition(),
      transitionDuration: const Duration(milliseconds: 420),
    ),
    GetPage<dynamic>(
      name: device,
      page: () => const DeviceHomePage(),
      binding: DeviceBinding(),
      customTransition: DeviceRouteTransition(),
      transitionDuration: const Duration(milliseconds: 1200),
    ),
    GetPage<dynamic>(name: video, page: () => const VideoPage()),
    GetPage<dynamic>(name: profile, page: () => const ProfilePage()),
  ];
}
