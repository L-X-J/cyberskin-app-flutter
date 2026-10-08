import 'dart:async';

import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/session_controller.dart';
import '../../device/domain/device.dart';

/// 主页设备状态与入口导航的展示层控制器。
final class HomeController extends GetxController {
  /// 创建主页控制器。
  HomeController(this._session);

  final SessionController _session;

  /// 当前前端设备连接状态；真实 BLE 接入后由设备会话更新。
  Rx<DeviceConnectionStatus> get deviceStatus => _session.deviceStatus;

  /// 当前是否已经建立 App 会话。
  bool get isAuthenticated =>
      _session.state.value == SessionState.authenticated;

  /// 打开登录页，并保留主页作为登录成功前的视觉上下文。
  void openLogin() {
    unawaited(Get.toNamed<void>(AppRoutes.login));
  }

  /// 打开受保护的设备详情页。
  void openDevice() {
    unawaited(Get.toNamed<void>(AppRoutes.device));
  }

  /// 连接入口的占位动作；真实 BLE 连接由后续设备会话模块接入。
  void requestConnection() {
    if (!isAuthenticated) {
      openLogin();
      return;
    }
    openDevice();
  }
}
