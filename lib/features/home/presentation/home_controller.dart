// 主页状态、BLE 自动发现与多 Repository 数据聚合编排。
import 'dart:async';

import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/session_controller.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../core/error/app_failure.dart';
import '../../control/domain/device_command_repository.dart';
import '../../content/domain/repositories/content_repository.dart';
import '../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../device/domain/device.dart';
import '../../device/domain/device_repository.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../device/domain/repositories/user_device_repository.dart';
import '../../device/presentation/device_manual_route_arguments.dart';
import '../../training/domain/repositories/training_repository.dart';
import 'home_dashboard.dart';
import 'states/home_ble_card_state.dart';

export 'states/home_ble_card_state.dart';

/// 主页设备状态、BLE 运行时与内容数据的展示层控制器。
final class HomeController extends GetxController with WidgetsBindingObserver {
  /// 创建主页控制器；BLE 协调器为空时保留无硬件环境的离线壳层能力。
  HomeController(
    this._session, {
    DeviceRepository? deviceRepository,
    UserDeviceRepository? userDeviceRepository,
    DeviceCatalogRepository? deviceCatalogRepository,
    TrainingRepository? trainingRepository,
    ContentRepository? contentRepository,
    CyberskinBleRuntimeCoordinator? bleCoordinator,
    DeviceCommandRepository? deviceCommandRepository,
  }) : _deviceRepository = deviceRepository,
       _userDeviceRepository = userDeviceRepository,
       _deviceCatalogRepository = deviceCatalogRepository,
       _trainingRepository = trainingRepository,
       _contentRepository = contentRepository,
       _bleCoordinator = bleCoordinator,
       _deviceCommandRepository = deviceCommandRepository;

  final SessionController _session;
  final DeviceRepository? _deviceRepository;
  final UserDeviceRepository? _userDeviceRepository;
  final DeviceCatalogRepository? _deviceCatalogRepository;
  final TrainingRepository? _trainingRepository;
  final ContentRepository? _contentRepository;
  final CyberskinBleRuntimeCoordinator? _bleCoordinator;
  final DeviceCommandRepository? _deviceCommandRepository;
  final List<Worker> _bleWorkers = <Worker>[];

  /// 聚合后的主页数据；替换快照而不是修改共享列表，避免部分更新闪烁。
  final Rx<HomeDashboard> dashboard = HomeDashboard().obs;

  /// 内容加载状态。
  final RxBool isLoading = false.obs;

  /// 最近一次可安全展示的加载错误。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  /// 最近一次绑定失败的服务端消息；与 BLE 卡片阶段解耦，用户主动重试时才清除。
  final Rxn<String> bindFailureMessage = Rxn<String>();

  /// 首页一级内容区当前标签；切换不离开当前路由。
  final Rx<AppTab> selectedTab = AppTab.home.obs;

  /// 顶部 BLE 扫描卡的完整展示状态，文案和操作由 Controller 统一决定。
  final Rx<HomeBleCardState> bleCardState = HomeBleCardState.checking().obs;

  bool _hadConnectedDevice = false;
  bool _powerOffInProgress = false;

  /// 当前前端设备连接状态；由 BLE 事件同步到全局 SessionController。
  Rx<DeviceConnectionStatus> get deviceStatus => _session.deviceStatus;

  /// 当前主页待用户确认的首次发现设备。
  Rxn<BleDiscoveredDevice>? get pendingDiscovery =>
      _bleCoordinator?.pendingDiscovery;

  /// 当前是否处于 BLE 扫描窗口。
  RxBool? get isScanning => _bleCoordinator?.isScanning;

  /// 当前是否已经建立 App 会话。
  bool get isAuthenticated =>
      _session.state.value == SessionState.authenticated;

  /// 页面依赖就绪后加载主页并启动已登录用户的 BLE 自动发现。
  @override
  void onReady() {
    super.onReady();
    WidgetsBinding.instance.addObserver(this);
    _bindBleObservers();
    // 未配置 API 地址时跳过主页网络聚合；已认证页面仍需恢复 BLE 自动发现。
    if (const String.fromEnvironment('CYBERSKIN_API_BASE_URL').isNotEmpty) {
      unawaited(_loadHomeAndStartBle());
    } else if (isAuthenticated) {
      unawaited(startDiscovery());
    }
  }

  /// 先初始化蓝牙状态并加载主页数据，再以后台 profile 启动自动扫描和已知设备自动重连。
  Future<void> _loadHomeAndStartBle() async {
    // 蓝牙适配器状态与账号权限无关，匿名主页也必须先完成初始化，
    // 否则卡片会一直停留在初始的 Checking Bluetooth。
    final coordinator = _bleCoordinator;
    Future<void>? discovery;
    if (coordinator != null) {
      await coordinator.initializeBluetooth();
      if (isAuthenticated) {
        // BLE profile/扫描不应等待主页内容接口；登录返回后立即恢复设备发现。
        discovery = startDiscovery();
      }
    }
    // 未配置 API 地址的开发壳层跳过网络请求，但仍保留真实蓝牙状态和扫描能力。
    if (const String.fromEnvironment('CYBERSKIN_API_BASE_URL').isNotEmpty) {
      await load();
    }
    await discovery;
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

  /// 打开产品说明书页；提供摘要时用于首帧和 Hero 动画，缺少型号 ID 时回退到设备主页。
  void openDeviceManual(int? modelId, {DeviceModelSummary? summary}) {
    if (modelId == null || modelId <= 0) {
      openDevice();
      return;
    }
    unawaited(
      Get.toNamed<void>(
        AppRoutes.deviceManual.replaceFirst(':modelId', '$modelId'),
        arguments: DeviceManualRouteArguments(
          modelId: modelId,
          summary: summary,
        ),
      ),
    );
  }

  /// 在主页发起 BLE profile 加载、权限申请、扫描和已知设备自动重连。
  Future<void> startDiscovery() async {
    if (!isAuthenticated) {
      openLogin();
      return;
    }
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;
    // 用户主动发起新一轮扫描，清除上一次绑定失败的持久提示。
    bindFailureMessage.value = null;
    await coordinator.loadProfilesAndStart();
    _syncBleStatus();
  }

  /// 停止主页发起的扫描窗口；已经建立的连接会继续保留。
  Future<void> stopDiscovery() async {
    await _bleCoordinator?.stopDiscovery();
    _syncBleStatus();
  }

  /// 确认主页发现的新设备，连接成功后创建用户绑定并刷新主页快照。
  Future<void> confirmDiscovery() async {
    final coordinator = _bleCoordinator;
    final device = coordinator?.pendingDiscovery.value;
    if (coordinator == null || device == null) return;
    bindFailureMessage.value = null;
    final connected = await coordinator.confirmAndConnect(device);
    _syncBleStatus();
    if (connected) {
      await load();
    } else {
      // bind 失败时把服务端消息持久保存到独立字段，与协调器 failureCode 解耦，
      // 避免后续 profile reload 或扫描重启把错误文案清掉。
      final serverMsg = coordinator.failureMessage.value;
      if (serverMsg != null && serverMsg.isNotEmpty) {
        bindFailureMessage.value = serverMsg;
      }
    }
  }

  /// 忽略主页当前发现的新设备，继续保留后台扫描能力。
  Future<void> dismissDiscovery() async {
    await _bleCoordinator?.dismissDiscovery();
  }

  /// 主页主连接入口；已连接时进入设备详情，否则启动自动发现。
  void requestConnection() {
    if (!isAuthenticated) {
      openLogin();
      return;
    }
    if (deviceStatus.value == DeviceConnectionStatus.connected ||
        deviceStatus.value == DeviceConnectionStatus.lowBattery) {
      openDevice();
      return;
    }
    unawaited(handleBlePrimaryAction());
  }

  /// 处理顶部蓝牙卡片的主操作，包括打开蓝牙、申请权限和重新扫描。
  Future<void> handleBlePrimaryAction() async {
    final phase = bleCardState.value.phase;
    final coordinator = _bleCoordinator;
    if (coordinator == null) {
      if (phase == HomeBleCardPhase.loginRequired || !isAuthenticated) {
        openLogin();
      }
      return;
    }

    switch (phase) {
      case HomeBleCardPhase.bluetoothOff:
        final turnedOn = await coordinator.turnOnBluetooth();
        if (!turnedOn) {
          await coordinator.openBluetoothSettings();
        } else if (isAuthenticated) {
          await startDiscovery();
        }
      case HomeBleCardPhase.permissionRequired:
        final granted = await coordinator.requestBluetoothPermissions();
        if (granted && isAuthenticated) {
          await startDiscovery();
        }
      case HomeBleCardPhase.unavailable:
        await coordinator.openBluetoothSettings();
      case HomeBleCardPhase.loginRequired:
        openLogin();
      case HomeBleCardPhase.checking:
      case HomeBleCardPhase.ready:
      case HomeBleCardPhase.noDevice:
      case HomeBleCardPhase.connectionFailed:
      case HomeBleCardPhase.bindFailed:
        if (!isAuthenticated) {
          openLogin();
        } else {
          await startDiscovery();
        }
      case HomeBleCardPhase.scanning:
      case HomeBleCardPhase.connecting:
      case HomeBleCardPhase.deviceFound:
        break;
    }
  }

  /// 打开个人中心；未登录时直接跳转登录页，不依赖 Middleware 延迟拦截。
  void openProfile() {
    if (!isAuthenticated) {
      openLogin();
      return;
    }
    unawaited(Get.toNamed<void>(AppRoutes.profile));
  }

  /// 确认设备关机，等待设备响应后主动断开并解除当前用户绑定。
  Future<void> confirmPowerOffAndUnbind() async {
    if (_powerOffInProgress) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Turn off device?'),
        content: const Text(
          'The device will power off and disconnect from this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Turn off'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;

    final coordinator = _bleCoordinator;
    final commandRepository = _deviceCommandRepository;
    final boundDevice = dashboard.value.boundDevice;
    final connectedState = coordinator?.connectedDevice.value;
    final modelId = connectedState == null
        ? boundDevice?.deviceModelId
        : int.tryParse(connectedState.device.model.trim()) ??
              boundDevice?.deviceModelId;
    final bindingId = boundDevice?.id;
    final remoteId = connectedState?.remoteId;
    if (coordinator == null ||
        commandRepository == null ||
        modelId == null ||
        bindingId == null ||
        remoteId == null) {
      _showPowerOffError('The connected device is not ready.');
      return;
    }

    _powerOffInProgress = true;
    try {
      final commandResult = await commandRepository.send(
        'power_off:off',
        modelId: modelId,
        remoteId: remoteId,
      );
      if (commandResult.isFailure) {
        _showPowerOffError(
          commandResult.failureOrNull?.message ??
              'The device did not accept the power off command.',
        );
        return;
      }

      final responded = await _waitForPowerOffResponse(coordinator, remoteId);
      if (!responded) {
        _showPowerOffError('The device did not confirm that it is powering off.');
        return;
      }

      await coordinator.disconnectIntentionally(remoteId);
      await coordinator.forgetKnownDevice(modelId, remoteId);
      final unbindResult = await _userDeviceRepository!.unbind(bindingId);
      if (unbindResult.isFailure) {
        _showPowerOffError(
          unbindResult.failureOrNull?.message ??
              'The device disconnected, but could not be unbound.',
        );
      }
      await load();
    } finally {
      _powerOffInProgress = false;
    }
  }

  Future<bool> _waitForPowerOffResponse(
    CyberskinBleRuntimeCoordinator coordinator,
    String remoteId,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (coordinator.isDeviceShuttingDown(remoteId)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return coordinator.isDeviceShuttingDown(remoteId);
  }

  void _showPowerOffError(String message) {
    Get.snackbar('Device action failed', message, snackPosition: SnackPosition.BOTTOM);
  }

  /// 监听 BLE 连接与运行态 Rx，确保主页状态和全局浮动控制条同步。
  void _bindBleObservers() {
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;
    _bleWorkers.add(
      ever<Map<String, BleConnectionState>>(
        coordinator.connectionStates,
        (_) => _onBleConnectionStateChanged(),
      ),
    );
    _bleWorkers.add(
      ever<Map<String, BleRuntimeStatus>>(
        coordinator.runtime,
        (_) => _syncBleStatus(),
      ),
    );
    _bleWorkers.add(
      ever<String>(coordinator.adapterState, (state) {
        _syncBleCardState();
        if (state == 'on' && isAuthenticated) {
          // 登录或权限回调早于适配器状态事件时，在开关确认后补发自动扫描。
          unawaited(startDiscovery());
        }
      }),
    );
    _bleWorkers.add(
      ever<SessionState>(_session.state, (state) {
        _syncBleCardState();
        if (state == SessionState.authenticated) {
          // 登录返回主页后自动恢复 BLE 流程；协调器内部会再次检查权限和开关。
          unawaited(startDiscovery());
        } else if (state == SessionState.anonymous) {
          // 注销后清理自动发现和用户 profile，避免匿名会话复用旧账号数据。
          unawaited(coordinator.clearUserSession());
        }
      }),
    );
    _bleWorkers.add(
      ever(coordinator.isInitialized, (_) => _syncBleCardState()),
    );
    _bleWorkers.add(
      ever(coordinator.permissionGranted, (_) {
        _syncBleCardState();
        if (coordinator.permissionGranted.value &&
            coordinator.adapterState.value == 'on' &&
            isAuthenticated) {
          unawaited(startDiscovery());
        }
      }),
    );
    _bleWorkers.add(ever(coordinator.isScanning, (_) => _syncBleCardState()));
    _bleWorkers.add(
      ever(coordinator.scanCompleted, (_) => _syncBleCardState()),
    );
    _bleWorkers.add(ever(coordinator.failureCode, (_) => _syncBleCardState()));
    _bleWorkers.add(
      ever(coordinator.pendingDiscovery, (_) => _syncBleCardState()),
    );
    _syncBleStatus();
    _syncBleCardState();
  }

  /// 将 SDK 状态映射为应用级连接状态，并在状态收敛后刷新设备快照。
  void _onBleConnectionStateChanged() {
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;
    final wasConnected = _hadConnectedDevice;
    _syncBleStatus();
    final isConnected = coordinator.hasConnectedDevice;
    if (isConnected != wasConnected) {
      unawaited(load());
    }
  }

  /// 将适配器、权限、扫描和发现事件收敛为顶部卡片的用户文案状态。
  void _syncBleCardState() {
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;
    final adapter = coordinator.adapterState.value;
    final pending = coordinator.pendingDiscovery.value;
    final failureCode = coordinator.failureCode.value;
    final phase = _resolveBleCardPhase(
      adapter: adapter,
      pending: pending,
      failureCode: failureCode,
      coordinator: coordinator,
    );
    bleCardState.value = HomeBleCardState.fromPhase(
      phase,
      adapterOn: adapter == 'on',
      errorMessage: coordinator.failureMessage.value,
    );
  }

  /// 按优先级把底层 BLE 状态映射成用户可理解的卡片阶段。
  HomeBleCardPhase _resolveBleCardPhase({
    required String adapter,
    required BleDiscoveredDevice? pending,
    required String? failureCode,
    required CyberskinBleRuntimeCoordinator coordinator,
  }) {
    if (adapter == 'off' || adapter == 'turningOff') {
      return HomeBleCardPhase.bluetoothOff;
    }
    if (adapter == 'unavailable') {
      return HomeBleCardPhase.unavailable;
    }
    if (adapter == 'unauthorized' ||
        (failureCode == 'permission_denied' &&
            !coordinator.permissionGranted.value)) {
      return HomeBleCardPhase.permissionRequired;
    }
    if (!coordinator.isInitialized.value || adapter == 'unknown') {
      return HomeBleCardPhase.checking;
    }
    if (!isAuthenticated) return HomeBleCardPhase.loginRequired;
    if (coordinator.isConnecting) return HomeBleCardPhase.connecting;
    if (pending != null) return HomeBleCardPhase.deviceFound;
    if (coordinator.isScanning.value) return HomeBleCardPhase.scanning;
    if (failureCode == 'bind_failed') {
      return HomeBleCardPhase.bindFailed;
    }
    if (failureCode == 'connection_failed' ||
        failureCode == 'command_failed' ||
        failureCode == 'scan_failed' ||
        failureCode == 'discovery_failed' ||
        failureCode == 'profile_load_failed') {
      return HomeBleCardPhase.connectionFailed;
    }
    if (coordinator.scanCompleted.value) return HomeBleCardPhase.noDevice;
    return HomeBleCardPhase.ready;
  }

  /// 从系统设置返回前台时重新检查权限、蓝牙开关并恢复已登录用户的扫描。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isAuthenticated) {
      unawaited(startDiscovery());
    }
  }

  /// 将 BLE 传输状态收敛到 SessionController，供主页路由和全局控制条消费。
  void _syncBleStatus() {
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;
    final connected = coordinator.hasConnectedDevice;
    final connecting = coordinator.isConnecting;
    if (connecting) {
      _session.setDeviceConnectionStatus(DeviceConnectionStatus.connecting);
    } else if (connected) {
      _session.setDeviceConnectionStatus(DeviceConnectionStatus.connected);
    } else if (_hadConnectedDevice) {
      _session.setDeviceConnectionStatus(DeviceConnectionStatus.sessionLost);
    } else {
      _session.setDeviceConnectionStatus(DeviceConnectionStatus.disconnected);
    }
    _hadConnectedDevice = connected;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final worker in _bleWorkers) {
      worker.dispose();
    }
    _bleWorkers.clear();
    super.onClose();
  }
}
