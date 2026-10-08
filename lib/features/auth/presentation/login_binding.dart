import 'package:get/get.dart';

import '../../../app/session_controller.dart';
import '../../content/domain/repositories/content_repository.dart';
import '../domain/auth_repository.dart';
import 'login_controller.dart';

/// 注册登录页生命周期内的认证控制器。
final class LoginBinding extends Bindings {
  /// 创建登录页绑定。
  LoginBinding();

  @override
  void dependencies() {
    Get.put<LoginController>(
      LoginController(
        Get.find<AuthRepository>(),
        Get.find<ContentRepository>(),
        Get.find<SessionController>(),
      ),
    );
  }
}
