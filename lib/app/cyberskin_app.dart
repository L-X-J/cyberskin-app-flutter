// 应用根组件：组装全局主题、路由和 GetX 依赖边界。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/logging/app_log.dart';
import '../core/theme/app_theme.dart';
import '../features/content/data/content_configuration_cache.dart';
import '../features/device/data/in_memory_device_repository.dart';
import '../features/device/domain/device_repository.dart';
import 'app_route_logger.dart';
import 'app_routes.dart';
import 'bindings/app_binding.dart';

/// 组装 GetX 依赖、路由和主题的根组件。
final class CyberskinApp extends StatelessWidget {
  /// 创建应用根组件，并允许测试或环境入口替换设备 Repository。
  const CyberskinApp({
    super.key,
    this.deviceRepository = const InMemoryDeviceRepository(),
    this.contentConfigurationCache,
    this.log = const NoopAppLog(),
  });

  /// 当前应用环境使用的设备 Repository。
  final DeviceRepository deviceRepository;

  /// 启动配置缓存；为空时使用平台 SharedPreferences 实现。
  final ContentConfigurationCache? contentConfigurationCache;

  /// 应用级统一日志实现。
  final AppLog log;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Cyberskin',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.init,
      getPages: AppRoutes.pages,
      routingCallback: (routing) => AppRouteLogger.record(log, routing),
      initialBinding: AppBinding(
        deviceRepository: deviceRepository,
        contentConfigurationCache:
            contentConfigurationCache ??
            SharedPreferencesContentConfigurationCache(),
        log: log,
      ),
    );
  }
}
