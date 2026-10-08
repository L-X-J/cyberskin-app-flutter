import 'package:get/get.dart';

import '../../../app/session_controller.dart';
import '../../auth/domain/auth_repository.dart';
import 'profile_controller.dart';

/// 注册资料页生命周期内的控制器。
final class ProfileBinding extends Bindings {
  /// 创建资料页绑定。
  ProfileBinding();

  @override
  void dependencies() {
    Get.put<ProfileController>(
      ProfileController(
        Get.find<AuthRepository>(),
        Get.find<SessionController>(),
      ),
    );
  }
}
