// 应用壳层路由表：集中声明顶层页面及其依赖绑定，避免页面自行拼接路由。
import 'package:get/get.dart';

import '../features/auth/presentation/login_binding.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/control/free_control/presentation/free_control_binding.dart';
import '../features/control/free_control/presentation/free_control_page.dart';
import '../features/device/presentation/device_manual_binding.dart';
import '../features/device/presentation/device_manual_page.dart';
import '../features/home/presentation/home_binding.dart';
import '../features/home/presentation/home_page.dart';
import '../features/init/presentation/init_page.dart';
import '../features/profile/presentation/profile_binding.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/rhythm/domain/entities/rhythm.dart';
import '../features/rhythm/domain/repositories/rhythm_catalog.dart';
import '../features/rhythm/domain/repositories/rhythm_repository.dart';
import '../features/rhythm/domain/services/rhythm_playback.dart';
import '../features/rhythm/presentation/pages/edit/rhythm_edit_controller.dart';
import '../features/rhythm/presentation/pages/edit/rhythm_edit_page.dart';
import '../features/rhythm/presentation/pages/home/rhythm_home_controller.dart';
import '../features/rhythm/presentation/pages/home/rhythm_home_page.dart';
import '../features/rhythm/presentation/pages/info/rhythm_info_page.dart';
import '../features/rhythm/presentation/rhythm_edit_guard.dart';
import '../features/training/presentation/pages/home/training_home_page.dart';
import '../features/training/presentation/pages/info/training_info_page.dart';
import '../features/training/presentation/training_binding.dart';
import '../features/video/presentation/video_binding.dart';
import '../features/video/presentation/video_browser_page.dart';
import '../features/video/presentation/video_page.dart';
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

  /// 设备产品说明书路由，型号 ID 通过 `:modelId` 传入。
  static const String deviceManual = '/device/manual/:modelId';

  /// 视频主页路由。
  static const String video = '/video';

  /// Browser 来源打开的 App 内网页容器。
  static const String videoBrowser = '/video/browser';

  /// 从设备主页进入的用户资料路由。
  static const String profile = '/profile';

  /// 自由控制模式路由。
  static const String freeControl = '/control/free';

  /// 训练列表和按 ID 独立加载的详情路由。
  static const trainingHome = '/training';

  /// 按课程主键加载完整详情。
  static const trainingInfo = '/training/info/:id';

  /// 生成具体课程的命名路由。
  static String trainingInfoPath(int id) => '/training/info/$id';

  /// 自定义节奏列表，断连仍可浏览。
  static const rhythmHome = '/rhythm';

  /// 新增与编辑共用路由，需要暂停锁。
  static const rhythmEdit = '/rhythm/edit';

  /// 节奏运行详情，页面返回不停止会话。
  static const rhythmInfo = '/rhythm/info';

  /// 显式页面策略；新增二级页必须登记，登录和未声明页面默认隐藏。
  static const Map<String, FloatingControlPolicy> floatingControlPolicies = {
    home: FloatingControlPolicy.fixed,
    deviceManual: FloatingControlPolicy.hidden,
    video: FloatingControlPolicy.fixed,
    videoBrowser: FloatingControlPolicy.draggable,
    profile: FloatingControlPolicy.draggable,
    freeControl: FloatingControlPolicy.hidden,
    trainingHome: FloatingControlPolicy.fixed,
    trainingInfo: FloatingControlPolicy.hidden,
    rhythmHome: FloatingControlPolicy.fixed,
    rhythmEdit: FloatingControlPolicy.hidden,
    rhythmInfo: FloatingControlPolicy.hidden,
    init: FloatingControlPolicy.hidden,
    login: FloatingControlPolicy.hidden,
  };

  /// 依赖设备已连接的二级路由集合；当设备断开连接时，若当前处于这些页面，会自动退回到主页未连接状态。
  static const Set<String> requiresConnectedDeviceRoutes = {freeControl};

  /// 检查指定路由名称是否强依赖设备连接。
  static bool requiresConnectedDevice(String? routeName) {
    if (routeName == null) return false;
    if (routeName.startsWith('/control/')) return true;
    return requiresConnectedDeviceRoutes.contains(routeName);
  }

  /// 安全返回主页。如果主页在路由栈中，pop 回退到主页；否则重置到主页。
  static void returnToHome() {
    if (Get.currentRoute == home) return;
    Get.until((route) => route.settings.name == home);
    if (Get.currentRoute != home) {
      Get.offAllNamed<void>(home);
    }
  }

  /// 所有顶层路由及其局部依赖绑定。
  ///
  /// 注意：Get 的全局路由树以 `List<GetPage>` 保存页面，匹配后会通过 `copy()`
  /// 重新包装成 `GetPage<dynamic>`，因此此处声明的泛型不会传到最终路由上。
  /// 命名路由一律派发 `Route<dynamic>`，`Get.toNamed<T>` 不能依赖 `T` 做类型转换。
  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<void>(
      name: trainingHome,
      page: () => const TrainingHomePage(),
      binding: TrainingBinding(),
      middlewares: [RouteAuthMiddleware()],
    ),
    GetPage<void>(
      name: trainingInfo,
      page: () => const TrainingInfoPage(),
      middlewares: [RouteAuthMiddleware()],
    ),
    GetPage<void>(
      name: rhythmHome,
      page: () => const RhythmHomePage(),
      binding: BindingsBuilder<void>(
        () => Get.lazyPut(
          () => RhythmHomeController(Get.find<RhythmRepository>()),
        ),
      ),
      middlewares: [RouteAuthMiddleware()],
    ),
    GetPage<bool>(
      name: rhythmEdit,
      page: () => const RhythmEditPage(),
      binding: BindingsBuilder<void>(
        () => Get.lazyPut(
          () => RhythmEditController(
            Get.find<RhythmRepository>(),
            Get.find<RhythmCatalog>(),
            Get.find<RhythmPlayback>(),
            Get.arguments is Rhythm ? Get.arguments as Rhythm : null,
          ),
        ),
      ),
      middlewares: [RouteAuthMiddleware(), RhythmEditGuard()],
    ),
    GetPage<void>(
      name: rhythmInfo,
      page: () => const RhythmInfoPage(),
      middlewares: [RouteAuthMiddleware()],
    ),
    GetPage<void>(
      name: init,
      page: () => const InitPage(),
      binding: InitBinding(),
      customTransition: InitRouteTransition(),
      transitionDuration: const Duration(milliseconds: 420),
    ),
    GetPage<void>(
      name: login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage<void>(
      name: home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage<void>(
      name: deviceManual,
      page: () => const DeviceManualPage(),
      binding: DeviceManualBinding(),
      customTransition: DeviceManualRouteTransition(),
      transitionDuration: const Duration(milliseconds: 520),
    ),
    GetPage<void>(
      name: video,
      page: () => const VideoPage(),
      binding: VideoBinding(),
    ),
    GetPage<void>(name: videoBrowser, page: () => const VideoBrowserPage()),
    GetPage<void>(
      name: profile,
      page: () => const ProfilePage(),
      binding: ProfileBinding(),
      middlewares: <GetMiddleware>[RouteAuthMiddleware()],
    ),
    GetPage<void>(
      name: freeControl,
      page: () => const FreeControlPage(),
      binding: FreeControlBinding(),
      customTransition: FreeControlRouteTransition(),
      transitionDuration: const Duration(milliseconds: 560),
      middlewares: <GetMiddleware>[RouteAuthMiddleware()],
    ),
  ];
}
