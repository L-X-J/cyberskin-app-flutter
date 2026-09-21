// 应用进程入口：只负责启动根组件，不承载业务初始化或状态编排。
import 'package:flutter/widgets.dart';

import 'app/cyberskin_app.dart';

/// 启动 Cyberskin Flutter 应用。
void main() {
  runApp(const CyberskinApp());
}
