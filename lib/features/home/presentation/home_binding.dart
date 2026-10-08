import 'package:get/get.dart';

import '../../../app/session_controller.dart';
import 'home_controller.dart';

/// 注册主页生命周期内的展示层控制器。
final class HomeBinding extends Bindings {
  /// 创建主页绑定。
  HomeBinding();

  @override
  void dependencies() {
    Get.put<HomeController>(HomeController(Get.find<SessionController>()));
  }
}
