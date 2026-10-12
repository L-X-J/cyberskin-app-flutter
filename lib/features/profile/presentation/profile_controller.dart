import 'dart:async';

import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/session_controller.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_repository.dart';

/// 当前用户资料加载与退出登录控制器。
final class ProfileController extends GetxController {
  /// 创建资料控制器。
  ProfileController(this._authRepository, this._session);

  final AuthRepository _authRepository;
  final SessionController _session;

  /// 当前用户资料。
  final Rxn<AppUser> user = Rxn<AppUser>();

  /// 是否正在加载资料。
  final isLoading = false.obs;

  /// 是否正在退出登录。
  final isLoggingOut = false.obs;

  /// 当前可展示错误。
  final failure = Rxn<AppFailure>();

  @override
  void onReady() {
    super.onReady();
    unawaited(load());
  }

  /// 获取当前用户资料。
  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    failure.value = null;
    final result = await _authRepository.currentUser();
    isLoading.value = false;
    if (result case Success<AppUser>(:final value)) {
      user.value = value;
      return;
    }
    failure.value = result.failureOrNull;
  }

  /// 清理本地会话并回到主页；远端退出失败也不能保留本地登录态。
  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    // 远端请求与本地清理并行，节省时间；远端失败不影响本地登出。
    await Future.wait<void>([
      _authRepository.logout(),
      _session.logout(),
    ]);
    isLoggingOut.value = false;
    await Get.offAllNamed<void>(AppRoutes.home);
  }
}
