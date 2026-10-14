// 设备主页状态与数据加载编排。
import 'dart:async';

import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../data/cyberskin_ble_runtime_coordinator.dart';
import '../domain/connected_device_state.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';

/// 设备主页的 GetX 控制器。
///
/// 每个字段独立响应式，使后续高频 BLE 状态更新只重建直接展示该字段的组件。
final class DeviceHomeController extends GetxController {
  /// 创建由 [repository] 提供数据的控制器。
  DeviceHomeController(this._repository, [this._bleCoordinator]);

  final DeviceRepository _repository;
  final CyberskinBleRuntimeCoordinator? _bleCoordinator;

  /// 当前可供用户访问的设备列表。
  final RxList<Device> devices = <Device>[].obs;

  /// Repository 是否正在加载设备数据。
  final RxBool isLoading = false.obs;

  /// 最近一次加载失败；成功或尚未加载时为 `null`。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  /// 当前待用户确认的首次发现设备。
  Rxn<BleDiscoveredDevice>? get pendingDiscovery =>
      _bleCoordinator?.pendingDiscovery;

  /// 页面依赖就绪后自动触发首次加载。
  @override
  void onReady() {
    super.onReady();
    unawaited(load());
    unawaited(_bleCoordinator?.loadProfilesAndStart());
  }

  /// 加载当前设备列表；重复调用期间会忽略并发加载请求。
  Future<void> load() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    failure.value = null;

    final result = await _repository.loadDevices();
    final loadedDevices = result.valueOrNull;
    if (loadedDevices != null) {
      devices.assignAll(loadedDevices);
      _syncConnectedDevice(loadedDevices);
    } else {
      failure.value = result.failureOrNull;
    }
    isLoading.value = false;
  }

  /// 将已加载设备列表同步到协调器的连接设备视图。
  ///
  /// 连接成功时取列表首项构造 [ConnectedDeviceState]，断开时清除视图。
  /// remoteId 从协调器的 connectionStates 中找第一个 connected 条目获取。
  void _syncConnectedDevice(List<Device> loadedDevices) {
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;
    if (loadedDevices.isEmpty || !coordinator.hasConnectedDevice) {
      coordinator.clearConnectedDevice();
      return;
    }
    // 找到当前已连接设备的 BLE remoteId。
    String? connectedRemoteId;
    for (final entry in coordinator.connectionStates.entries) {
      if (entry.value == BleConnectionState.connected) {
        connectedRemoteId = entry.key;
        break;
      }
    }
    if (connectedRemoteId == null) {
      coordinator.clearConnectedDevice();
      return;
    }
    final device = loadedDevices.first;
    coordinator.setConnectedDevice(
      ConnectedDeviceState(device: device, remoteId: connectedRemoteId),
    );
  }

  /// 响应用户刷新操作重新加载设备数据。
  Future<void> reload() => load();

  /// 确认首次发现设备并完成 BLE 连接与后端绑定。
  Future<bool> confirmDiscovery() async {
    final device = pendingDiscovery?.value;
    if (device == null || _bleCoordinator == null) return false;
    return _bleCoordinator.confirmAndConnect(device);
  }

  /// 忽略当前首次发现设备。
  Future<void> dismissDiscovery() =>
      _bleCoordinator?.dismissDiscovery() ?? Future<void>.value();

  /// 重新启动 profile 加载和蓝牙扫描。
  Future<void> startDiscovery() =>
      _bleCoordinator?.loadProfilesAndStart() ?? Future<void>.value();
}
