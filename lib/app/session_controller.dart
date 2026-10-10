// 应用级会话与前端设备连接状态，供路由和页面共享。
import 'package:get/get.dart';

import '../features/content/domain/entities/app_content.dart';
import '../features/device/domain/device.dart';

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
final class SessionController extends GetxController {
  /// 当前会话状态；初始化期间保持 [SessionState.starting]。
  final Rx<SessionState> state = SessionState.starting.obs;

  /// 会话认证版本号；每次登录态切换时自增。
  ///
  /// 用于让在途的异步任务判断自己捕获的结果是否已经过期：例如启动时发出的
  /// 匿名配置刷新可能在用户登录后才返回，此时版本号已变化，旧结果必须丢弃。
  int _revision = 0;

  /// 当前会话版本号快照。
  int get revision => _revision;

  /// 前端设备连接状态，真实 BLE 接入前默认保持断开。
  final Rx<DeviceConnectionStatus> deviceStatus =
      DeviceConnectionStatus.disconnected.obs;

  /// 用启动配置同步会话状态。
  void setConfiguration(AppConfiguration configuration) {
    if (configuration.loggedIn) {
      markAuthenticated();
    } else {
      markAnonymous();
    }
  }

  /// 标记当前会话已认证。
  void markAuthenticated() {
    if (state.value == SessionState.authenticated) return;
    state.value = SessionState.authenticated;
    _revision++;
  }

  /// 标记当前会话为匿名，并清理路由保护所依赖的认证状态。
  void markAnonymous() {
    if (state.value == SessionState.anonymous) return;
    state.value = SessionState.anonymous;
    _revision++;
  }

  /// 更新设备连接占位状态，供未来 BLE Adapter 接入时替换。
  void setDeviceConnectionStatus(DeviceConnectionStatus status) {
    deviceStatus.value = status;
  }
}
