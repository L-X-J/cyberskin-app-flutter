// 设备详情、BLE SDK 与 GetX 应用状态之间的适配服务。
import 'dart:async';
import 'dart:io';

import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/connected_device_state.dart';
import '../domain/repositories/device_catalog_repository.dart';
import '../domain/repositories/user_device_repository.dart';
import 'ble_known_device_store.dart';

// BLE 诊断日志开关：仅在 debug 模式下输出，release 构建自动关闭。
const bool _kBleLog = kDebugMode;

/// Cyberskin 的 BLE 运行时协调器。
///
/// 后端 profile、SDK 连接状态和页面状态在此处汇合；页面不直接接触 FlutterBluePlus。
class CyberskinBleRuntimeCoordinator extends GetxService {
  CyberskinBleRuntimeCoordinator({
    required DeviceCatalogRepository catalogRepository,
    UserDeviceRepository? userDeviceRepository,
    Future<SharedPreferences>? preferencesFuture,
  }) : _catalogRepository = catalogRepository,
       _userDeviceRepository = userDeviceRepository,
       _preferencesFuture =
           preferencesFuture ?? SharedPreferences.getInstance();

  final DeviceCatalogRepository _catalogRepository;
  final UserDeviceRepository? _userDeviceRepository;
  final Future<SharedPreferences> _preferencesFuture;
  BleDeviceManager? _manager;
  BleDeviceManager get manager => _manager!;
  final RxBool isInitialized = false.obs;
  final RxBool isScanning = false.obs;
  final RxString adapterState = 'unknown'.obs;
  final RxBool permissionGranted = false.obs;
  final RxBool scanCompleted = false.obs;
  final Rxn<String> failureCode = Rxn<String>();
  final Rxn<String> failureMessage = Rxn<String>();
  final Rxn<BleDiscoveredDevice> pendingDiscovery = Rxn<BleDiscoveredDevice>();
  final RxMap<String, BleRuntimeStatus> runtime =
      <String, BleRuntimeStatus>{}.obs;
  final RxMap<String, BleConnectionState> connectionStates =
      <String, BleConnectionState>{}.obs;

  /// 当前连接设备的完整运行时视图；连接后由 [DeviceHomeController] 赋值，断开时清为 null。
  ///
  /// Obx 组件可直接订阅此字段或其内部各遥测字段，实现点位级刷新。
  final Rxn<ConnectedDeviceState> connectedDevice = Rxn<ConnectedDeviceState>();
  StreamSubscription<BleEvent>? _events;
  Map<int, BleDeviceProfile> _profilesByModel = <int, BleDeviceProfile>{};
  bool _profilesConfigured = false;
  Future<void>? _initializeFuture;
  Future<void>? _startFuture;
  Future<void>? _discoveryFuture;
  int _sessionGeneration = 0;
  // App 主动发起断开的设备 ID 集合，用于区分设备侧断开与 App 侧断开。
  final Set<String> _intentionalDisconnects = <String>{};
  // 当前扫描周期内已主动请求连接的设备 ID；防止对同一设备重复调用 connectDiscovered。
  // SDK 在第一轮扫描中可能不会自动触发已知设备连接，此标志保证我们只发起一次。
  String? _attemptedConnectionId;

  /// 初始化 BLE 适配器状态，但不读取账号数据或启动设备扫描。
  ///
  /// 匿名主页也需要展示真实的蓝牙开关状态，因此适配器初始化不能依赖登录态。
  Future<void> initializeBluetooth() {
    if (isInitialized.value) return Future<void>.value();
    final existing = _initializeFuture;
    if (existing != null) return existing;
    final future = _initializeBluetooth();
    _initializeFuture = future;
    return future.whenComplete(() {
      if (identical(_initializeFuture, future)) {
        _initializeFuture = null;
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
  }

  /// 加载后台 profile 并启动自动发现；重复调用共享同一个初始化 Future。
  ///
  /// 主页和设备页都可能在路由切换时触发该入口，必须在协调器内合并并发请求，
  /// 避免重复创建 BLE 监听、重复请求目录详情或同时启动多个扫描会话。
  Future<void> loadProfilesAndStart() {
    if (_profilesConfigured) {
      return _startDiscovery();
    }
    final existing = _startFuture;
    if (existing != null) return existing;
    final future = _loadProfilesAndStart();
    _startFuture = future;
    return future.whenComplete(() {
      if (identical(_startFuture, future)) {
        _startFuture = null;
      }
    });
  }

  Future<void> _loadProfilesAndStart() async {
    final generation = _sessionGeneration;
    failureCode.value = null;
    failureMessage.value = null;
    scanCompleted.value = false;
    _bleLog('loadProfilesAndStart: 开始加载设备 profile');
    await initializeBluetooth();
    final manager = this.manager;
    final t0 = DateTime.now();
    final result = await _catalogRepository.listDeviceModels();
    _bleLog('listDeviceModels 耗时 ${DateTime.now().difference(t0).inMilliseconds}ms');
    final summaries = result.valueOrNull;
    if (summaries == null) {
      final failure = result.failureOrNull;
      _bleLog('listDeviceModels 失败: ${failure?.message}');
      failureCode.value = 'profile_load_failed';
      failureMessage.value =
          failure?.message ?? 'Device profiles could not be loaded.';
      _profilesConfigured = false;
      return;
    }
    _bleLog('获取到 ${summaries.length} 个型号摘要，开始串行拉取详情');
    final profiles = <BleDeviceProfile>[];
    var detailLoadFailed = false;
    for (final summary in summaries) {
      final modelId = summary.id;
      if (modelId == null || modelId <= 0) continue;
      final t1 = DateTime.now();
      final detail = await _catalogRepository.getDeviceModelDetail(modelId);
      final value = detail.valueOrNull;
      if (value == null) {
        _bleLog('getDeviceModelDetail($modelId) 失败 (${DateTime.now().difference(t1).inMilliseconds}ms): ${detail.failureOrNull?.message}');
        detailLoadFailed = true;
        continue;
      }
      _bleLog('getDeviceModelDetail($modelId) 成功 (${DateTime.now().difference(t1).inMilliseconds}ms)');
      final profile = _toProfile(value);
      profiles.add(profile);
    }
    // 注销可能在目录请求期间发生；过期结果不能重新写入用户 profile 或启动扫描。
    if (generation != _sessionGeneration) {
      _bleLog('loadProfilesAndStart: session 已失效，丢弃结果');
      return;
    }
    if (detailLoadFailed && profiles.isEmpty) {
      _bleLog('loadProfilesAndStart: 所有型号详情加载失败');
      failureCode.value = 'profile_load_failed';
      failureMessage.value = 'Device profiles could not be loaded.';
      return;
    }
    _profilesByModel = {
      for (final profile in profiles) profile.modelId: profile,
    };
    _bleLog('profile 加载完成，共 ${profiles.length} 个: ${profiles.map((p) => '${p.modelId}(${p.profileKey})').join(', ')}');
    manager.configureProfiles(profiles);
    _profilesConfigured = true;
    await _startDiscovery();
  }

  /// 只在权限和系统蓝牙开关均满足条件时启动扫描。
  ///
  /// 登录回调、主页初始化和用户点击可能同时触发扫描，因此这里合并并发请求，
  /// 并在每次真正启动前重新检查平台状态，避免权限或开关变化后仍调用 SDK 扫描。
  Future<void> _startDiscovery() {
    if (!_profilesConfigured) return Future<void>.value();
    // 已有活跃连接时不启动扫描；重连由设备侧断开事件触发，不需要持续扫描。
    if (hasConnectedDevice) {
      _bleLog('_startDiscovery: 跳过，设备已连接');
      return Future<void>.value();
    }
    // SDK 的 manager.isScanning 表示自动扫描请求仍保持开启，
    // 不代表当前这一轮扫描正在进行；重扫只能依据事件状态判断。
    if (isScanning.value) return Future<void>.value();
    final existing = _discoveryFuture;
    if (existing != null) return existing;
    final future = _checkAndStartDiscovery();
    _discoveryFuture = future;
    return future.whenComplete(() {
      if (identical(_discoveryFuture, future)) {
        _discoveryFuture = null;
      }
    });
  }

  Future<void> _checkAndStartDiscovery() async {
    final current = manager;
    // 蓝牙关闭时先保留 Bluetooth off 阶段，不触发可能因适配器关闭而失败的权限请求。
    if (adapterState.value != 'on') {
      _bleLog('_checkAndStartDiscovery: 跳过，适配器状态=${adapterState.value}');
      return;
    }
    final permissionsGranted = await current.requestBluetoothPermissions();
    // 除了依赖异步事件外同步保存结果，避免平台权限实现不广播事件时状态不一致。
    permissionGranted.value = permissionsGranted;
    if (!permissionsGranted) {
      _bleLog('_checkAndStartDiscovery: 跳过，权限未授予');
      return;
    }
    // 权限弹窗期间用户可能关闭蓝牙，启动前需要再次核对开关状态。
    if (adapterState.value != 'on') {
      _bleLog('_checkAndStartDiscovery: 跳过，权限弹窗期间蓝牙被关闭');
      return;
    }
    _bleLog('_checkAndStartDiscovery: 启动自动扫描');
    await current.startAutoDiscovery();
  }

  Future<void> _initializeBluetooth() async {
    final preferences = await _preferencesFuture;
    _manager ??= BleDeviceManager(
      knownDeviceStore: SharedPreferencesKnownDeviceStore(preferences),
      logger: _AppBleLogger(),
    );
    // SDK 初始化会立即广播一次当前适配器状态；必须先接收事件，避免
    // `initialize()` 完成前的首个状态被广播流丢弃，主页永久停留在 checking。
    _events ??= manager.events.listen(_onEvent);
    // 先初始化 SDK 的 adapterState 流，确保主页不会因为初始 unknown 永远停留在检查态。
    await manager.initialize();
    isInitialized.value = true;
  }

  /// 停止扫描，但保留已建立的连接和 profile 缓存。
  /// 请求蓝牙权限；页面使用结果更新引导文案。
  Future<bool> requestBluetoothPermissions() async {
    final current = _manager;
    if (current == null) return false;
    final granted = await current.requestBluetoothPermissions();
    permissionGranted.value = granted;
    return granted;
  }

  /// 尝试打开蓝牙；系统不允许直接开启时由页面继续引导设置。
  Future<bool> turnOnBluetooth() async {
    // iOS / macOS 等平台不支持代码直接开蓝牙，避免调用 FlutterBluePlus.turnOn 触发平台异常。
    if (!Platform.isAndroid) {
      return false;
    }
    final current = _manager;
    if (current == null) return false;
    final completer = Completer<bool>();
    await runZonedGuarded(
      () async {
        try {
          final result = await current.turnOnBluetooth();
          if (!completer.isCompleted) completer.complete(result);
        } catch (_) {
          if (!completer.isCompleted) completer.complete(false);
        }
      },
      (error, stack) {
        // 捕获与隔离 flutter_blue_plus 内部 responseStream 悬空抛出的 Bad state: No element 异步微任务错误。
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    return completer.future;
  }

  /// 打开系统设置，让用户开启蓝牙或修改权限。
  Future<bool> openBluetoothSettings() async {
    try {
      if (Platform.isAndroid) {
        final uri = Uri.parse('action:android.settings.BLUETOOTH_SETTINGS');
        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri);
        }
      } else if (Platform.isIOS) {
        // iOS 上直接跳转系统设置首页
        final rootUris = <Uri>[
          Uri.parse('App-Prefs:root'),
          Uri.parse('App-Prefs:'),
        ];
        for (final uri in rootUris) {
          if (await canLaunchUrl(uri)) {
            return await launchUrl(uri);
          }
        }
      }
    } catch (_) {}
    final current = _manager;
    if (current == null) return false;
    return current.openBluetoothSettings();
  }

  /// 停止扫描，但保留已建立的连接和 profile 缓存。
  Future<void> stopDiscovery() async {
    final current = _manager;
    if (current == null) return;
    await current.stopAutoDiscovery();
  }

  /// 注销时清理用户 profile、待确认设备和扫描请求，防止匿名会话继续复用旧账号数据。
  Future<void> clearUserSession() async {
    _sessionGeneration++;
    await stopDiscovery();
    // 内存缓存在注销时失效，防止旧账号设备列表泄给新登录用户。
    _userDeviceRepository?.invalidateCache();
    pendingDiscovery.value = null;
    _intentionalDisconnects.clear();
    _profilesByModel = <int, BleDeviceProfile>{};
    _profilesConfigured = false;
    scanCompleted.value = false;
  }

  /// 当前是否存在已建立的 BLE 连接。
  bool get hasConnectedDevice => connectionStates.values.any(
    (state) => state == BleConnectionState.connected,
  );

  /// 当前是否正在建立 BLE 连接。
  bool get isConnecting => connectionStates.values.any(
    (state) => state == BleConnectionState.connecting,
  );

  /// 返回当前已连接设备的运行态；当前产品只允许绑定一台设备。
  BleRuntimeStatus? get connectedRuntime {
    for (final entry in connectionStates.entries) {
      if (entry.value == BleConnectionState.connected) {
        return runtime[entry.key];
      }
    }
    return null;
  }

  Future<bool> confirmAndConnect(BleDiscoveredDevice device) async {
    pendingDiscovery.value = null;
    final connected = await manager.connectDiscovered(device);
    if (!connected) return false;
    final repository = _userDeviceRepository;
    if (repository == null) return true;
    final result = await repository.bind(
      UserDeviceBindRequest(
        deviceModelId: device.profile.modelId,
        deviceUid: device.remoteId,
      ),
    );
    if (result.isFailure) {
      // 绑定被服务端拒绝；标记为预期断开，避免触发设备侧断开的重扫逻辑。
      _intentionalDisconnects.add(device.remoteId);
      await manager.disconnect(device.remoteId);
      failureCode.value = 'bind_failed';
      failureMessage.value =
          result.failureOrNull?.message ?? 'Device could not be registered.';
      return false;
    }
    await manager.rememberDevice(device.profile.profileKey, device.remoteId);
    return true;
  }

  Future<void> dismissDiscovery() async {
    pendingDiscovery.value = null;
  }

  Future<bool> sendCommand({
    required int modelId,
    required String remoteId,
    required String command,
  }) => manager.sendSemanticCommand(
    remoteId: remoteId,
    profileKey: _profilesByModel[modelId]?.profileKey ?? '',
    command: command,
  );

  /// 判断指定设备是否已经上报关机前状态。
  bool isDeviceShuttingDown(String remoteId) =>
      runtime[remoteId]?.isShuttingDown == true;

  /// 主动断开设备并清理连接视图；该断开不会触发自动重连扫描。
  Future<void> disconnectIntentionally(String remoteId) async {
    _intentionalDisconnects.add(remoteId);
    await manager.disconnect(remoteId);
    clearConnectedDevice();
  }

  /// 清除设备记忆，防止关机解除绑定后下一轮扫描自动重连。
  Future<void> forgetKnownDevice(int modelId, String remoteId) async {
    final profile = _profilesByModel[modelId];
    if (profile == null) return;
    await manager.forgetDevice(profile.profileKey, remoteId);
  }

  BleDeviceProfile? profileForModel(int modelId) => _profilesByModel[modelId];

  /// 由 [DeviceHomeController] 在加载到匹配设备后调用，建立连接设备视图。
  ///
  /// 若已存在相同 [remoteId] 的视图，则仅更新 [device] 元数据并重新应用当前运行态，
  /// 避免替换视图对象导致所有下游 Obx 重建。
  void setConnectedDevice(ConnectedDeviceState state) {
    final existing = connectedDevice.value;
    if (existing != null && existing.remoteId == state.remoteId) {
      // remoteId 不变时仅刷新运行态快照；device 元数据不可变，不需要更新。
      final current = runtime[state.remoteId];
      if (current != null) existing.applyStatus(current);
      return;
    }
    // 新设备或 remoteId 变化：替换视图对象并立即应用当前已知运行态。
    final current = runtime[state.remoteId];
    if (current != null) state.applyStatus(current);
    connectedDevice.value = state;
  }

  /// 由 [DeviceHomeController] 在设备断开后调用，清除连接设备视图。
  void clearConnectedDevice() {
    connectedDevice.value = null;
  }

  BleDeviceProfile _toProfile(DeviceModelDetail detail) {
    final ble = detail.ble;
    final summary = detail.summary;
    final profileKey = ble?.profileKey ?? 'pechtak.generic.v1';
    return BleDeviceProfile(
      modelId: summary.id ?? 0,
      profileKey: profileKey,
      hardwareUid: summary.hardwareUid ?? '',
      hardwareNameLock: detail.hardwareExtensionUid,
      deviceType: summary.tags ?? 'device',
      gatt: BleGattConfiguration(
        readService: ble?.readService,
        readCharacteristic: ble?.readCharacteristic,
        writeService: ble?.writeService,
        writeCharacteristic: ble?.writeCharacteristic,
      ),
    );
  }

  void _onEvent(BleEvent event) {
    switch (event) {
      case BleScanningChanged(:final scanning):
        _bleLog('扫描状态变化: scanning=$scanning');
        if (scanning) {
          scanCompleted.value = false;
        } else if (isScanning.value) {
          scanCompleted.value = true;
        }
        isScanning.value = scanning;
      case BleAdapterChanged(:final state):
        _bleLog('适配器状态变化: $state');
        adapterState.value = state;
        if (state == 'on') {
          failureCode.value = null;
          failureMessage.value = null;
        }
      case BlePermissionChanged(:final granted):
        _bleLog('权限变化: granted=$granted');
        permissionGranted.value = granted;
        if (granted && failureCode.value == 'permission_denied') {
          failureCode.value = null;
          failureMessage.value = null;
        }
      case BleDeviceDiscovered(:final device, :final isKnown):
        _bleLog(
          '发现设备: id=${device.remoteId} '
          'name=${device.name} '
          'profile=${device.profile.profileKey} '
          'isKnown=$isKnown '
          '→ ${isKnown ? '已知设备，自动重连' : '新设备，等待用户确认'}',
        );
        if (!isKnown) {
          pendingDiscovery.value = device;
        } else if (!hasConnectedDevice &&
            !isConnecting &&
            _attemptedConnectionId != device.remoteId) {
          // iOS CoreBluetooth 冷启动时，SDK 的 startAutoDiscovery 自动重连在
          // 第一轮扫描中可能不触发，需要 App 层主动发起一次 connectDiscovered。
          // 用 _attemptedConnectionId 去重，确保同一 remoteId 本轮只发一次连接请求。
          _attemptedConnectionId = device.remoteId;
          _bleLog('_onEvent: 主动发起已知设备连接 id=${device.remoteId}');
          unawaited(manager.connectDiscovered(device));
        }
      case BleConnectionChanged(:final remoteId, :final state):
        _bleLog('连接状态变化: id=$remoteId state=$state');
        connectionStates[remoteId] = state;
        if (state == BleConnectionState.connected) {
          // 已连接：停止扫描，避免继续消耗系统资源和电量。
          // 断开时会重新触发扫描，不需要在这里保留扫描窗口。
          unawaited(manager.stopAutoDiscovery());
        } else if (state == BleConnectionState.disconnected ||
            state == BleConnectionState.failed) {
          final wasIntentional = _intentionalDisconnects.remove(remoteId);
          _bleLog(
            '设备断开: id=$remoteId '
            '${wasIntentional ? '(App 主动断开，不重扫)' : '(设备侧断开，触发重扫)'}',
          );
          // 断开后下一轮扫描需要重新尝试连接。
          _attemptedConnectionId = null;
          if (!wasIntentional) {
            pendingDiscovery.value = null;
            scanCompleted.value = false;
            unawaited(_startDiscovery());
          }
        }
      case BleRuntimeChanged(:final remoteId, :final status):
        runtime[remoteId] = status;
        final connected = connectedDevice.value;
        if (connected != null && connected.remoteId == remoteId) {
          connected.applyStatus(status);
        }
      case BleFailure(:final code, :final message):
        _bleLog('BLE 错误: code=$code message=$message');
        failureCode.value = code;
        failureMessage.value = message;
      case BleCommandResult():
        break;
    }
  }

  @override
  void onClose() {
    unawaited(_events?.cancel());
    if (_manager != null) unawaited(manager.dispose());
    super.onClose();
  }
}

void _bleLog(String message) {
  if (_kBleLog) debugPrint('[BLE] $message');
}

final class _AppBleLogger implements BleLogger {
  @override
  void debug(String message) {
    if (_kBleLog) debugPrint('[BLE:SDK] $message');
  }

  @override
  void warning(String message, [Object? error]) {
    if (_kBleLog) {
      debugPrint('[BLE:SDK⚠] $message${error != null ? ' | $error' : ''}');
    }
  }
}
