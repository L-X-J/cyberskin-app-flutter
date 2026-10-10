// 主页状态与多 Repository 数据聚合编排。
import 'dart:async';

import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/session_controller.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../core/error/app_failure.dart';
import '../../content/domain/repositories/content_repository.dart';
import '../../device/domain/device.dart';
import '../../device/domain/device_repository.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../device/domain/repositories/user_device_repository.dart';
import '../../device/presentation/device_manual_route_arguments.dart';
import '../../training/domain/repositories/training_repository.dart';
import 'home_dashboard.dart';

/// 主页设备状态与内容数据的展示层控制器。
final class HomeController extends GetxController {
  /// 创建主页控制器；依赖为空时保留匿名壳层的离线视觉能力。
  HomeController(
    this._session, {
    DeviceRepository? deviceRepository,
    UserDeviceRepository? userDeviceRepository,
    DeviceCatalogRepository? deviceCatalogRepository,
    TrainingRepository? trainingRepository,
    ContentRepository? contentRepository,
  }) : _deviceRepository = deviceRepository,
       _userDeviceRepository = userDeviceRepository,
       _deviceCatalogRepository = deviceCatalogRepository,
       _trainingRepository = trainingRepository,
       _contentRepository = contentRepository;

  final SessionController _session;
  final DeviceRepository? _deviceRepository;
  final UserDeviceRepository? _userDeviceRepository;
  final DeviceCatalogRepository? _deviceCatalogRepository;
  final TrainingRepository? _trainingRepository;
  final ContentRepository? _contentRepository;

  /// 聚合后的主页数据；替换快照而不是修改共享列表，避免部分更新闪烁。
  final Rx<HomeDashboard> dashboard = HomeDashboard().obs;

  /// 内容加载状态。
  final RxBool isLoading = false.obs;

  /// 最近一次可安全展示的加载错误。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  /// 首页一级内容区当前标签；切换不离开当前路由。
  final Rx<AppTab> selectedTab = AppTab.home.obs;

  /// 当前前端设备连接状态；真实 BLE 接入后由设备会话更新。
  Rx<DeviceConnectionStatus> get deviceStatus => _session.deviceStatus;

  /// 当前是否已经建立 App 会话。
  bool get isAuthenticated =>
      _session.state.value == SessionState.authenticated;

  /// 页面依赖就绪后加载公开内容和用户设备数据。
  @override
  void onReady() {
    super.onReady();
    // 未配置 API 地址的开发壳层不发起无意义的 localhost 请求；真实构建通过 dart-define 开启。
    if (const String.fromEnvironment('CYBERSKIN_API_BASE_URL').isNotEmpty) {
      unawaited(load());
    }
  }

  /// 依次读取各 Repository，单项失败不丢弃其余可用主页内容。
  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    failure.value = null;

    final errors = <AppFailure>[];
    final deviceResult = _deviceRepository == null
        ? null
        : await _deviceRepository.loadDevices();
    final boundResult = _userDeviceRepository == null || !isAuthenticated
        ? null
        : await _userDeviceRepository.listUserDevices();
    final modelsResult = _deviceCatalogRepository == null
        ? null
        : await _deviceCatalogRepository.listDeviceModels();
    final trainingsResult = _trainingRepository == null
        ? null
        : await _trainingRepository.listTrainings();
    final adsResult = _contentRepository == null
        ? null
        : await _contentRepository.listAdvertisements();

    for (final result in [
      deviceResult,
      boundResult,
      modelsResult,
      trainingsResult,
      adsResult,
    ]) {
      final error = result?.failureOrNull;
      if (error != null && error.code != FailureCode.unauthorized) {
        errors.add(error);
      }
    }

    final boundDevices = boundResult?.valueOrNull ?? const [];
    if (boundDevices.length > 1) {
      errors.add(
        const AppFailure(
          code: FailureCode.invalidData,
          message: 'Only one device can be bound at a time.',
        ),
      );
    }
    dashboard.value = HomeDashboard(
      connectedDevices: deviceResult?.valueOrNull ?? const [],
      boundDevices: boundDevices,
      deviceModels: modelsResult?.valueOrNull ?? const [],
      trainings: trainingsResult?.valueOrNull ?? const [],
      advertisements: adsResult?.valueOrNull ?? const [],
    );
    failure.value = errors.isEmpty ? null : errors.first;
    isLoading.value = false;
  }

  /// 响应用户刷新操作。
  Future<void> reload() => load();

  /// 选择首页内容区域标签；导航外观由 [AppScaffold] 响应同一状态。
  void selectTab(AppTab tab) => selectedTab.value = tab;

  /// 打开登录页，并保留主页作为登录成功前的视觉上下文。
  void openLogin() => unawaited(Get.toNamed<void>(AppRoutes.login));

  /// 打开受保护的设备详情页。
  void openDevice() => unawaited(Get.toNamed<void>(AppRoutes.device));

  /// 打开后台配置的产品说明；缺少型号 ID 时回退到设备主页。
  void openDeviceManual(int? modelId, {String? productName}) {
    if (modelId == null || modelId <= 0) {
      openDevice();
      return;
    }
    unawaited(
      Get.toNamed<void>(
        AppRoutes.deviceManual.replaceFirst(':modelId', '$modelId'),
        arguments: DeviceManualRouteArguments(productName: productName),
      ),
    );
  }

  /// 连接入口的占位动作；真实 BLE 连接由设备会话模块接入。
  void requestConnection() {
    if (!isAuthenticated) {
      openLogin();
      return;
    }
    openDevice();
  }

  /// 打开个人中心；未登录时直接跳转登录页，不依赖 Middleware 延迟拦截。
  void openProfile() {
    if (!isAuthenticated) {
      openLogin();
      return;
    }
    unawaited(Get.toNamed<void>(AppRoutes.profile));
  }
}
