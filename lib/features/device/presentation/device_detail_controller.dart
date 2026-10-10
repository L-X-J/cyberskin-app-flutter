// 设备详情与产品说明书统一页面的状态和数据加载编排。
import 'dart:async';

import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../content/domain/entities/app_content.dart';
import '../../content/domain/repositories/content_repository.dart';
import '../domain/repositories/device_catalog_repository.dart';

/// 设备详情页的 GetX 控制器。
final class DeviceDetailController extends GetxController {
  /// 创建指定设备型号的详情控制器。
  DeviceDetailController(
    this._repository, {
    required this.modelId,
    this.summary,
    ContentRepository? contentRepository,
  }) : _contentRepository = contentRepository;

  final DeviceCatalogRepository _repository;
  final ContentRepository? _contentRepository;

  /// 当前设备型号主键。
  final int modelId;

  /// 入口卡片已经拥有的摘要，用于详情请求期间展示稳定首屏。
  final DeviceModelSummary? summary;

  /// 页面顶部可横向选择的已发布产品型号。
  final RxList<DeviceModelSummary> models = <DeviceModelSummary>[].obs;

  /// 当前选中的产品型号下标。
  final RxInt selectedModelIndex = 0.obs;

  /// 当前选中的产品型号。
  final Rxn<DeviceModelSummary> selectedModel = Rxn<DeviceModelSummary>();

  /// 后台发布的设备型号详情。
  final Rxn<DeviceModelDetail> detail = Rxn<DeviceModelDetail>();

  /// 当前型号的三段式产品说明书。
  final Rxn<DeviceManual> manual = Rxn<DeviceManual>();

  /// 当前选中的说明书段落下标。
  final RxInt selectedManualIndex = 0.obs;

  /// 全局广告接口返回的广告，详情页使用第一张图片作为兜底。
  final RxList<AppAdvertisement> advertisements = <AppAdvertisement>[].obs;

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
    final listResult = await _repository.listDeviceModels();
    final listedModels = listResult.valueOrNull ?? const <DeviceModelSummary>[];
    final availableModels = listedModels.isEmpty
        ? <DeviceModelSummary>[summary ?? DeviceModelSummary(id: modelId)]
        : listedModels;
    models.assignAll(availableModels);
    final initialIndex = availableModels.indexWhere(
      (model) => model.id == modelId,
    );
    await selectModel(
      initialIndex < 0 ? 0 : initialIndex,
      notifyLoading: false,
    );
    final adsResult = await _contentRepository?.listAdvertisements();
    if (adsResult != null) {
      advertisements.assignAll(
        adsResult.valueOrNull ?? const <AppAdvertisement>[],
      );
    }
    if (detail.value == null && manual.value == null) {
      failure.value = listResult.failureOrNull;
    }
    isLoading.value = false;
  }

  /// 响应详情错误状态中的重试操作。
  Future<void> reload() => load();

  /// 选择产品型号并刷新该型号的详情与三段说明书。
  Future<void> selectModel(int index, {bool notifyLoading = true}) async {
    if (index < 0 ||
        index >= models.length ||
        isLoading.value && notifyLoading) {
      return;
    }
    final selected = models[index];
    final selectedId = selected.id;
    if (selectedId == null || selectedId <= 0) {
      return;
    }
    selectedModelIndex.value = index;
    selectedModel.value = selected;
    detail.value = null;
    manual.value = null;
    selectedManualIndex.value = 0;
    if (notifyLoading) {
      isLoading.value = true;
      failure.value = null;
    }
    final results = await Future.wait<Result<dynamic>>([
      _repository.getDeviceModelDetail(selectedId),
      _repository.getManual(selectedId),
    ]);
    final loadedDetail = results[0].valueOrNull as DeviceModelDetail?;
    final loadedManual = results[1].valueOrNull as DeviceManual?;
    if (loadedDetail != null) {
      detail.value = loadedDetail;
    }
    if (loadedManual != null) {
      manual.value = loadedManual;
      selectedManualIndex.value = _safeManualIndex(
        selectedManualIndex.value,
        loadedManual.items.length,
      );
    }
    if (loadedDetail == null && loadedManual == null) {
      failure.value = results[0].failureOrNull ?? results[1].failureOrNull;
    }
    if (notifyLoading) {
      isLoading.value = false;
    }
  }

  /// 选择当前型号的说明书段落。
  void selectManual(int index) {
    final length = manual.value?.items.length ?? 0;
    if (index < 0 || index >= length) {
      return;
    }
    selectedManualIndex.value = index;
  }

  int _safeManualIndex(int index, int length) {
    if (length == 0) {
      return 0;
    }
    return index.clamp(0, length - 1);
  }
}
