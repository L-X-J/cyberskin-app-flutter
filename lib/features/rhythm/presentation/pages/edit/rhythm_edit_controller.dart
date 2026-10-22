// 新增/编辑草稿、型号切换和保存编排；不向设备下发草稿内容。
import 'package:get/get.dart';

import '../../../domain/entities/rhythm.dart';
import '../../../domain/entities/rhythm_program.dart';
import '../../../domain/repositories/rhythm_catalog.dart';
import '../../../domain/repositories/rhythm_repository.dart';
import '../../../domain/services/rhythm_playback.dart';

/// 维护编辑草稿并校验保存条件，不发送草稿控制指令。
final class RhythmEditController extends GetxController {
  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmEditController(
    this.repository,
    this.catalog,
    this.playback,
    this.original,
  );

  /// 节奏持久化的唯一访问入口。
  final RhythmRepository repository;

  /// 已绑定型号及已发布能力的访问边界。
  final RhythmCatalog catalog;

  /// 应用级执行会话，页面销毁不释放它。
  final RhythmPlayback playback;

  /// 编辑入口的原始快照；新增时为空。
  final Rhythm? original;

  /// 当前账号已绑定型号的可选择列表。
  final models = <RhythmModel>[].obs;

  /// 当前草稿适用型号。
  final selectedModel = RxnInt();

  /// 所选型号支持的通道和模式。
  final capabilities = <RhythmChannelCapability>[].obs;

  /// 有序草稿片段，修改时替换不可变片段。
  final segments = <RhythmSegment>[].obs;

  /// 加载中、保存中及草稿变更等独立操作状态。
  final loading = false.obs, saving = false.obs, dirty = false.obs;

  /// 可展示错误及名称字段错误，互不覆盖。
  final error = RxnString(), nameError = RxnString();

  /// 用户可见名称。
  String name = '';
  int _modelGeneration = 0;
  @override
  void onInit() {
    super.onInit();
    name = original?.name ?? '';
    segments.assignAll(original?.segments ?? []);
    selectedModel.value =
        original?.deviceModelId ?? playback.port.target?.modelId;
    load();
  }

  /// 加载已绑定型号并恢复原有选择。
  Future<void> load() async {
    loading.value = true;
    error.value = null;

    final result = await catalog.models();
    if (isClosed) return;
    if (result.isFailure) {
      error.value = result.failureOrNull!.message;
      loading.value = false;
      return;
    }
    models.assignAll(result.valueOrNull!);
    if (!models.any((m) => m.id == selectedModel.value)) {
      selectedModel.value = original == null && models.isNotEmpty
          ? models.first.id
          : null;
    }
    if (selectedModel.value != null) {
      await loadCapabilities(selectedModel.value!);
    }
    loading.value = false;
  }

  /// 加载型号能力并丢弃过期异步响应。
  Future<void> loadCapabilities(int id) async {
    final generation = ++_modelGeneration;
    loading.value = true;
    capabilities.clear();

    final result = await catalog.capabilities(id);
    if (isClosed || generation != _modelGeneration) return;
    if (result.isFailure) {
      error.value = result.failureOrNull!.message;
    } else {
      capabilities.assignAll(result.valueOrNull!);
      error.value = null;
    }
    loading.value = false;
  }

  /// 清空旧型号片段后加载新能力，调用前由页面确认。
  Future<void> selectModel(int id) async {
    if (selectedModel.value == id) return;
    segments.clear();
    selectedModel.value = id;
    dirty.value = true;
    await loadCapabilities(id);
  }

  /// 同步名称输入并清除原字段错误。
  void setName(String value) {
    name = value;
    dirty.value = true;
    nameError.value = null;
  }

  /// 验证后追加或替换片段，达到上限时拒绝写入。
  bool putSegment(RhythmStep step, {int? at}) {
    if (saving.value || loading.value) return false;
    try {
      step.validate(capabilities);
      step.encode(capabilities: capabilities);
    } on FormatException catch (e) {
      error.value = e.message;
      return false;
    }
    if (at == null && segments.length >= 30) {
      error.value = 'Maximum 30 segments reached.';
      return false;
    }
    if (at == null) {
      segments.add(step.encode(capabilities: capabilities));
    } else {
      segments[at] = step.encode(capabilities: capabilities);
    }
    segments.assignAll(RhythmStep.timeline(segments));
    dirty.value = true;
    return true;
  }

  /// 删除草稿片段，无需访问远端。
  void deleteSegment(int index) {
    if (saving.value) return;
    segments.removeAt(index);
    segments.assignAll(RhythmStep.timeline(segments));
    dirty.value = true;
  }

  /// 校验完整草稿并提交，失败保留用户输入。
  Future<bool> save() async {
    if (saving.value || loading.value) return false;
    nameError.value = null;
    error.value = null;
    if (name.trim().isEmpty) {
      nameError.value = 'Please name this rhythm.';
      return false;
    }
    if (name.trim().length > 64) {
      nameError.value = 'Use no more than 64 characters.';
      return false;
    }
    if (selectedModel.value == null) {
      error.value = 'Please select an applicable device.';
      return false;
    }
    if (segments.isEmpty) {
      error.value = 'Add at least one segment.';
      return false;
    }
    try {
      for (final s in segments) {
        RhythmStep.decode(s).validate(capabilities);
      }
    } on FormatException catch (e) {
      error.value = e.message;
      return false;
    }
    segments.assignAll(RhythmStep.timeline(segments));
    saving.value = true;
    if (playback.active &&
        playback.snapshot.rhythm?.id == original?.id &&
        !await playback.stop()) {
      saving.value = false;
      error.value = playback.snapshot.message;
      return false;
    }

    final result = original?.id == null
        ? await repository.create(
            RhythmCreateRequest(
              deviceModelId: selectedModel.value!,
              name: name.trim(),
              segments: segments,
            ),
          )
        : await repository.update(
            original!.id!,
            RhythmUpdateRequest(
              deviceModelId: selectedModel.value!,
              name: name.trim(),
              segments: segments,
            ),
          );
    saving.value = false;
    if (result.isFailure) {
      error.value = result.failureOrNull!.message;
      return false;
    }
    dirty.value = false;
    return true;
  }

  @override
  void onClose() {
    playback.finishEditing();
    super.onClose();
  }
}
