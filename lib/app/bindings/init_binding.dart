// 初始化路由的局部依赖装配。
import 'package:get/get.dart';

import '../../features/content/domain/repositories/content_repository.dart';
import '../../features/init/presentation/init_controller.dart';

/// 注册初始化页面及其 Controller。
final class InitBinding extends Bindings {
  /// 创建初始化路由绑定。
  InitBinding();

  @override
  void dependencies() {
    Get.put<InitController>(InitController(Get.find<ContentRepository>()));
  }
}
