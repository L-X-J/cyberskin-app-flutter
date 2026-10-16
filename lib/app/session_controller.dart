// 应用级会话与前端设备连接状态，供路由和页面共享。
import 'dart:async';

import 'package:get/get.dart';

import '../core/storage/session_credential_store.dart';
import '../features/content/domain/entities/app_content.dart';
import '../features/control/domain/device_session.dart';
import '../features/control/presentation/control_session_controller.dart';
import '../features/device/domain/device.dart';
import 'app_routes.dart';

/// 应用启动阶段的会话状态。
enum SessionState {
  /// 尚未完成启动配置和本地会话判定。
  starting,

  /// 当前没有有效 App 会话。
  anonymous,

  /// 当前存在有效 App 会话。
  authenticated,
}

/// 管理跨页面共享的登录状态和设备连接占位状态。
///
/// 登录态的真相源是本地安全凭证：只要 [SessionCredentialStore] 中不存在未过期
/// 的凭证，会话就必须是 [SessionState.anonymous]，无论启动配置或内存状态如何
/// 声称。远端返回的 `loggedIn` 只作为提示，用于判定凭证已被服务端吊销的情况；
/// 它不能被当作凭证存在的证明，否则会出现「凭证已删但仍显示已登录」的分叉。
final class SessionController extends GetxController {
  /// 创建会话控制器，并绑定可选的凭证存储用于回读与失效监听。
  SessionController({SessionCredentialStore? sessionStore})
    : _sessionStore = sessionStore;

  /// 可选的凭证存储；为空时退化为纯内存状态，供不访问安全的测试使用。
  final SessionCredentialStore? _sessionStore;

  /// 当前会话状态；初始化期间保持 [SessionState.starting]。
  final Rx<SessionState> state = SessionState.starting.obs;

  /// 前端设备连接状态，真实 BLE 接入前默认保持断开。
  final Rx<DeviceConnectionStatus> deviceStatus =
      DeviceConnectionStatus.disconnected.obs;

  /// 凭证失效订阅；在 [onInit] 中挂载，避免重复监听。
  StreamSubscription<void>? _credentialSubscription;

  @override
  void onInit() {
    super.onInit();
    _watchCredentials();
  }

  /// 根据本地凭证回读启动期会话状态。
  ///
  /// 必须在展示任何受保护页面前完成，作为启动期唯一的会话判定入口；已有服务端
  /// 配置同步时以配置为准，避免用本地凭证覆盖刚返回的权威结果。
  Future<void> restore() async {
    if (state.value != SessionState.starting) {
      return;
    }
    final session = await _sessionStore?.read();
    _applyCredentialPresence(session != null);
  }

  /// 重新读取本地凭证并同步会话状态，供登录、登出后显式收敛。
  Future<void> refreshFromCredentials() async {
    final sessionStore = _sessionStore;
    if (sessionStore == null) {
      return;
    }
    final session = await sessionStore.read();
    _applyCredentialPresence(session != null);
  }

  /// 依据启动配置同步会话状态。
  ///
  /// [authenticatedAtStart] 记录请求发出时的会话状态，用于识别竞态：启动前发出的
  /// 匿名配置请求可能在用户登录后才返回，此时不能拿它的 `loggedIn=false` 把刚建立
  /// 的已登录会话错误地标记为失效。
  Future<void> setConfiguration(
    AppConfiguration configuration, {
    SessionState? authenticatedAtStart,
  }) async {
    if (configuration.loggedIn) {
      // 服务端确认已登录，但仍要求本地存在凭证，否则按匿名处理并回到登录，
      // 防止缓存里的历史 loggedIn=true 在凭证已清理后把用户带入受保护页面。
      await refreshFromCredentials();
      return;
    }
    await _invalidateIfAnonymousRefreshed(authenticatedAtStart);
  }

  /// 标记当前会话已认证，并确保已开始监听凭证失效。
  void markAuthenticated() {
    _watchCredentials();
    if (state.value == SessionState.authenticated) {
      return;
    }
    state.value = SessionState.authenticated;
  }

  /// 标记当前会话为匿名，并清理路由保护所依赖的认证状态。
  void markAnonymous() {
    if (state.value == SessionState.anonymous) {
      return;
    }
    state.value = SessionState.anonymous;
  }

  /// 清除本地凭证并收敛为匿名；远端登出是否成功都不保留本地登录态。
  Future<void> logout() async {
    await _sessionStore?.clear();
    markAnonymous();
  }

  /// 更新设备连接状态，并在设备断开时自动让依赖设备的二级页面返回主页未连接状态。
  void setDeviceConnectionStatus(DeviceConnectionStatus status) {
    deviceStatus.value = status;
    final isDisconnected =
        status == DeviceConnectionStatus.disconnected ||
        status == DeviceConnectionStatus.sessionLost;
    if (isDisconnected) {
      _handleDeviceDisconnected();
    }
  }

  void _handleDeviceDisconnected() {
    if (Get.isRegistered<ControlSessionController>()) {
      Get.find<ControlSessionController>().updateState(DeviceSessionState.idle);
    }
    if (AppRoutes.requiresConnectedDevice(Get.currentRoute)) {
      AppRoutes.returnToHome();
    }
  }

  /// 处理服务端返回未登录的配置。
  ///
  /// 仅当请求期间会话没有从匿名跃迁为已认证（即用户没有中途登录）时才清除凭证，
  /// 否则忽略这条过期的匿名结果。
  Future<void> _invalidateIfAnonymousRefreshed(
    SessionState? authenticatedAtStart,
  ) async {
    if (authenticatedAtStart == null) {
      // 调用方未提供竞态快照（多为测试或非启动期调用），保守清理本地凭证。
      await _sessionStore?.clear();
      markAnonymous();
      return;
    }
    final stillAnonymous =
        authenticatedAtStart == SessionState.anonymous &&
        state.value == SessionState.anonymous;
    if (!stillAnonymous) {
      return;
    }
    await _sessionStore?.clear();
    markAnonymous();
  }

  /// 按凭证是否存在写入会话状态。
  void _applyCredentialPresence(bool hasCredentials) {
    state.value = hasCredentials
        ? SessionState.authenticated
        : SessionState.anonymous;
  }

  /// 订阅凭证失效事件；重复调用只保留一个订阅。
  void _watchCredentials() {
    if (_credentialSubscription != null) {
      return;
    }
    _credentialSubscription = _sessionStore?.invalidated.listen((_) {
      markAnonymous();
    });
  }

  @override
  void onClose() {
    unawaited(_credentialSubscription?.cancel());
    _credentialSubscription = null;
    super.onClose();
  }
}
