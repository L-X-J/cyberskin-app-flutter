// 设备产品说明书页面状态与说明书加载编排。
import 'dart:async';

import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../domain/repositories/device_catalog_repository.dart';

/// 产品说明书页面的 GetX 控制器。
///
/// 说明书条目由后台按发布顺序提供；Controller 只负责加载、选中项和错误状态，
/// 不解析 HTTP 响应，也不把设备型号或标签复制成客户端业务常量。
final class DeviceManualController extends GetxController {
  /// 创建指定设备型号的说明书控制器。
  DeviceManualController(
    this._repository, {
    required this.modelId,
    this.productName,
  });

  final DeviceCatalogRepository _repository;

  /// 当前说明书对应的设备型号 ID。
  final int modelId;

  /// 来源页面已知的产品展示名称；不参与说明书的领域加载和缓存键。
  final String? productName;

  /// 当前设备说明书快照。
  final Rxn<DeviceManual> manual = Rxn<DeviceManual>();

  /// 说明书请求是否正在执行。
  final RxBool isLoading = false.obs;

  /// 最近一次加载失败；成功或尚未加载时为空。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  /// 当前选中的后台说明书条目下标。
  final RxInt selectedTab = 0.obs;

  /// 路由依赖就绪后自动加载说明书。
  @override
  void onReady() {
    super.onReady();
    unawaited(load());
  }

  /// 加载说明书；重复调用期间忽略并发请求。
  Future<void> load() async {
    if (isLoading.value) {
      return;
    }
    isLoading.value = true;
    failure.value = null;

    final result = await _repository.getManual(modelId);
    final loadedManual = result.valueOrNull;
    if (loadedManual != null) {
      manual.value = loadedManual;
      selectedTab.value = _safeSelectedTab(
        selectedTab.value,
        loadedManual.items.length,
      );
    } else {
      failure.value = result.failureOrNull;
    }
    isLoading.value = false;
  }

  /// 响应错误状态中的重试操作。
  Future<void> reload() => load();

  /// 选择说明书条目；无条目或越界下标会被安全忽略。
  void selectTab(int index) {
    final length = manual.value?.items.length ?? 0;
    if (index < 0 || index >= length) {
      return;
    }
    selectedTab.value = index;
  }

  /// 当刷新后的条目数量减少时，保留合法选中项并回退到首项。
  int _safeSelectedTab(int index, int length) {
    if (length == 0) {
      return 0;
    }
    return index.clamp(0, length - 1);
  }
}
