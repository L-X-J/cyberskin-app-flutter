// 设备主页状态与数据加载编排。
import 'dart:async';

import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';

/// 设备主页的 GetX 控制器。
///
/// 每个字段独立响应式，使后续高频 BLE 状态更新只重建直接展示该字段的组件。
final class DeviceHomeController extends GetxController {
  /// 创建由 [repository] 提供数据的控制器。
  DeviceHomeController(this._repository);

  final DeviceRepository _repository;

  /// 当前可供用户访问的设备列表。
  final RxList<Device> devices = <Device>[].obs;

  /// Repository 是否正在加载设备数据。
  final RxBool isLoading = false.obs;

  /// 最近一次加载失败；成功或尚未加载时为 `null`。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  /// 页面依赖就绪后自动触发首次加载。
  @override
  void onReady() {
    super.onReady();
    unawaited(load());
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
    } else {
      failure.value = result.failureOrNull;
    }
    isLoading.value = false;
  }

  /// 响应用户刷新操作重新加载设备数据。
  Future<void> reload() => load();
}
