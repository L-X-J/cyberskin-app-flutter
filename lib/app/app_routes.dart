// 应用壳层路由表：集中声明顶层页面及其依赖绑定，避免页面自行拼接路由。
import 'package:get/get.dart';

import '../features/auth/presentation/login_binding.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/device/presentation/device_manual_binding.dart';
import '../features/device/presentation/device_manual_page.dart';
import '../features/device/presentation/device_home_page.dart';
import '../features/home/presentation/home_binding.dart';
import '../features/home/presentation/home_page.dart';
import '../features/init/presentation/init_page.dart';
import '../features/profile/presentation/profile_binding.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/video/presentation/video_binding.dart';
import '../features/video/presentation/video_page.dart';
import 'bindings/device_binding.dart';
import 'bindings/init_binding.dart';
import 'floating_control_controller.dart';
import 'init_route_transition.dart';
import 'route_auth_middleware.dart';

/// 归属于应用壳层的命名路由。
abstract final class AppRoutes {
  /// 应用启动初始化路由。
  static const String init = '/init';

  /// 匿名可浏览的应用主页。
  static const String home = '/home';

  /// 登录页面。
  static const String login = '/login';

  /// 设备主页路由。
  static const String device = '/device';

  /// 设备产品说明书路由，型号 ID 通过 `:modelId` 传入。
  static const String deviceManual = '/device/manual/:modelId';

  /// 视频主页路由。
  static const String video = '/video';

  /// 从设备主页进入的用户资料路由。
  static const String profile = '/profile';

  /// 显式页面策略；新增二级页必须登记，登录和未声明页面默认隐藏。
  static const Map<String, FloatingControlPolicy> floatingControlPolicies = {
    home: FloatingControlPolicy.fixed,
    device: FloatingControlPolicy.fixed,
    deviceManual: FloatingControlPolicy.hidden,
    video: FloatingControlPolicy.fixed,
    profile: FloatingControlPolicy.draggable,
    init: FloatingControlPolicy.hidden,
    login: FloatingControlPolicy.hidden,
  };

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
      name: login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage<dynamic>(
      name: home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: device,
      page: () => const DeviceHomePage(),
      binding: DeviceBinding(),
      customTransition: DeviceRouteTransition(),
      transitionDuration: const Duration(milliseconds: 1200),
      middlewares: <GetMiddleware>[RouteAuthMiddleware()],
    ),
    GetPage<dynamic>(
      name: deviceManual,
      page: () => const DeviceManualPage(),
      binding: DeviceManualBinding(),
      customTransition: DeviceManualRouteTransition(),
      transitionDuration: const Duration(milliseconds: 520),
    ),
    GetPage<dynamic>(
      name: video,
      page: () => const VideoPage(),
      binding: VideoBinding(),
    ),
    GetPage<dynamic>(
      name: profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
      middlewares: <GetMiddleware>[RouteAuthMiddleware()],
    ),
  ];
}
