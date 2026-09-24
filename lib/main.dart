// 应用进程入口：只负责启动根组件，不承载业务初始化或状态编排。
import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app/cyberskin_app.dart';
import 'core/logging/app_log.dart';

/// 启动 Cyberskin Flutter 应用。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 先打开异步日志输出，再挂载应用，避免启动阶段的路由和 API 日志丢失。
  final log = await AppLogger.initialize();
  AppLifecycleListener(onDetach: () => unawaited(log.close()));
  runApp(CyberskinApp(log: log));
}
