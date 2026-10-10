// 设备详情页状态与设备型号详情加载编排。
import 'dart:async';

import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../domain/repositories/device_catalog_repository.dart';

/// 设备详情页的 GetX 控制器。
final class DeviceDetailController extends GetxController {
  /// 创建指定设备型号的详情控制器。
  DeviceDetailController(
    this._repository, {
    required this.modelId,
    this.summary,
  });

  final DeviceCatalogRepository _repository;

  /// 当前设备型号主键。
  final int modelId;

  /// 入口卡片已经拥有的摘要，用于详情请求期间展示稳定首屏。
  final DeviceModelSummary? summary;

  /// 后台发布的设备型号详情。
  final Rxn<DeviceModelDetail> detail = Rxn<DeviceModelDetail>();

  /// 详情请求是否正在执行。
  final RxBool isLoading = false.obs;

  /// 最近一次详情请求失败。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  /// 路由依赖就绪后自动加载详情。
  @override
  void onReady() {
    super.onReady();
    unawaited(load());
  }

  /// 加载设备详情；重复调用期间忽略并发请求。
  Future<void> load() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    failure.value = null;
    final result = await _repository.getDeviceModelDetail(modelId);
    final loaded = result.valueOrNull;
    if (loaded != null) {
      detail.value = loaded;
    } else {
      failure.value = result.failureOrNull;
    }
    isLoading.value = false;
  }

  /// 响应详情错误状态中的重试操作。
  Future<void> reload() => load();
}
