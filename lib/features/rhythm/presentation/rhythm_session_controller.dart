// 将独立节奏执行会话拆分为 UI 所需的原子响应式字段。
import 'dart:async';

import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../domain/entities/rhythm.dart';
import '../domain/entities/rhythm_program.dart';
import '../domain/repositories/rhythm_catalog.dart';
import '../domain/repositories/rhythm_device_port.dart';
import '../domain/repositories/rhythm_repository.dart';
import '../domain/services/rhythm_playback.dart';

/// 将执行器快照拆成原子响应式字段，页面无需订阅 BLE 实现。
final class RhythmSessionController extends GetxController {
  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmSessionController(
    this.playback,
    this.catalog, {
    required this.repository,
  });

  /// 应用级执行会话，页面销毁不释放它。
  final RhythmPlayback playback;

  /// 已绑定型号及已发布能力的访问边界。
  final RhythmCatalog catalog;

  /// 详情元数据与完整 JSON 的统一访问入口，下载和缓存仍归 Repository。
  final RhythmRepository repository;

  /// 当前会话绑定的不可变节奏快照。
  final rhythm = Rxn<Rhythm>();

  /// 当前可用设备；断开时为空。
  final target = Rxn<RhythmDeviceTarget>();

  /// 执行器确认的当前状态。
  final phase = RhythmPlaybackPhase.idle.obs;

  /// 当前片段索引；编辑弹层为空表示新增。
  final index = 0.obs, remaining = 0.obs, totalRemaining = 0.obs;

  /// 设备操作在途状态，防止界面重复操作。
  final busy = false.obs;

  /// 可展示错误及名称字段错误，互不覆盖。
  final error = RxnString();

  /// 所选型号支持的通道和模式。
  final capabilities = <RhythmChannelCapability>[].obs;

  /// 详情选择独立于执行器；浏览其他节奏不接收旧会话进度。
  final infoRhythm = Rxn<Rhythm>();

  /// 详情展示的执行阶段；预览始终为 idle。
  final infoPhase = RhythmPlaybackPhase.idle.obs;

  /// 当前详情片段与倒计时，独立订阅避免整页刷新。
  final infoIndex = 0.obs, infoRemaining = 0.obs, infoTotalRemaining = 0.obs;

  /// 详情文件及能力加载中；独立于设备按钮请求。
  final infoLoading = false.obs;

  /// 完整程序和型号能力已准备好，只有此时允许播放和编辑。
  final infoReady = false.obs;

  /// 详情按钮请求与已结束标志。
  final infoBusy = false.obs, infoFinished = false.obs;

  /// 详情专属错误，不被其他后台会话错误覆盖。
  final infoError = RxnString();
  bool _following = false;
  int _selectionGeneration = 0;

  int _sessionGeneration = 0;
  StreamSubscription<RhythmPlaybackSnapshot>? _playback;
  StreamSubscription<RhythmDeviceEvent>? _device;
  @override
  void onInit() {
    super.onInit();
    target.value = playback.port.target;
    _apply(playback.snapshot);
    _playback = playback.changes.listen(_apply);
    _device = playback.port.events.listen((e) {
      target.value = e.target;
      if (e.sessionExpired) {
        _sessionGeneration++;
        _selectionGeneration++;
        _following = false;
        infoRhythm.value = null;
        infoBusy.value = false;
        infoLoading.value = false;
        infoReady.value = false;
        infoError.value = null;
        rhythm.value = null;
        capabilities.clear();
        if (Get.currentRoute.startsWith('/rhythm')) {
          Get.offAllNamed<void>(AppRoutes.home);
        }
      }
    });
  }

  void _apply(RhythmPlaybackSnapshot s) {
    rhythm.value = s.rhythm;
    phase.value = s.phase;
    index.value = s.index;
    remaining.value = s.remainingSeconds;
    totalRemaining.value = s.totalRemainingSeconds;
    busy.value = s.busy;
    error.value = s.message;
    if (_following &&
        (s.rhythm == null || s.rhythm?.id == infoRhythm.value?.id)) {
      // stop/finish 会清除领域快照，详情仍保留原节奏以便显式重启。
      if (s.rhythm != null) {
        infoRhythm.value = s.rhythm;
        infoIndex.value = s.index;
      }
      infoPhase.value = s.phase;
      infoRemaining.value = s.remainingSeconds;
      infoTotalRemaining.value = s.totalRemainingSeconds;
      infoError.value = s.message;
      if (s.phase == RhythmPlaybackPhase.completed ||
          (s.phase == RhythmPlaybackPhase.idle && s.rhythm == null)) {
        infoFinished.value = true;
      }
    }
  }

  /// 先展示列表元数据，再异步准备完整程序与能力；选择详情不会启动设备。
  Future<void> select(Rhythm value) async {
    final generation = ++_selectionGeneration;
    final sessionGeneration = _sessionGeneration;
    bool current() =>
        !isClosed &&
        generation == _selectionGeneration &&
        sessionGeneration == _sessionGeneration;
    _following = playback.active && playback.snapshot.rhythm?.id == value.id;
    var selected = _following ? playback.snapshot.rhythm! : value;
    infoRhythm.value = selected;
    infoFinished.value = false;
    infoError.value = null;
    infoPhase.value = RhythmPlaybackPhase.idle;
    infoIndex.value = 0;
    _setInfoTime(selected);
    capabilities.clear();
    infoBusy.value = false;
    // 已运行的会话已有完整程序；后台刷新能力不能阻止用户立即停止设备。
    infoReady.value = _following && selected.hasCompleteProgram;
    infoLoading.value = !infoReady.value;
    if (_following) _apply(playback.snapshot);
    try {
      if (!selected.hasCompleteProgram) {
        if (selected.id == null) {
          infoError.value = 'Missing rhythm ID.';
          return;
        }
        final detail = await repository.getById(selected.id!);
        if (!current()) return;
        if (detail.isFailure) {
          infoError.value = detail.failureOrNull!.message;
          return;
        }
        selected = detail.valueOrNull!;
        if (!selected.hasCompleteProgram) {
          infoError.value = 'Unable to load the complete rhythm.';
          return;
        }
        infoRhythm.value = selected;
        _setInfoTime(selected);
      }
      if (selected.deviceModelId == null) {
        infoError.value = 'Missing device model.';
        return;
      }
      final result = await catalog.capabilities(selected.deviceModelId!);
      if (!current()) return;
      if (result.isSuccess) {
        capabilities.assignAll(result.valueOrNull!);
        infoReady.value = true;
      } else {
        infoError.value = result.failureOrNull!.message;
      }
    } on Object {
      if (current()) {
        infoError.value = 'Unable to load this rhythm. Please try again.';
      }
    } finally {
      if (current()) infoLoading.value = false;
    }
  }

  void _setInfoTime(Rhythm value) {
    final steps = value.segments.map((segment) => segment.program).toList();
    infoRemaining.value = steps.isEmpty ? 0 : steps.first.durationSeconds;
    infoTotalRemaining.value =
        value.totalSeconds ??
        steps.fold(0, (total, segment) => total + segment.durationSeconds);
  }

  /// 加载失败后重试当前选择，在途重复点击不会创建第二个请求。
  Future<void> retryInfo() async {
    final selected = infoRhythm.value;
    if (infoLoading.value || selected == null) return;
    await select(selected);
  }

  /// 离开详情只使等待中的启动失效，不停止已运行设备。
  void leaveInfo() {
    _selectionGeneration++;
    infoBusy.value = false;
    infoLoading.value = false;
  }

  /// 活动会话只能明确停止；暂停/中断不绕过原设备恢复保护。
  Future<void> toggleInfo() async {
    if (infoLoading.value ||
        !infoReady.value ||
        infoBusy.value ||
        playback.snapshot.busy ||
        infoRhythm.value == null) {
      return;
    }
    infoBusy.value = true;
    final generation = _selectionGeneration;
    final selected = infoRhythm.value!;
    try {
      if (_following && playback.active) {
        await playback.stop();
        if (generation == _selectionGeneration) _apply(playback.snapshot);
      } else {
        final ok = await start(
          selected,
          isCurrent: () => !isClosed && generation == _selectionGeneration,
        );
        if (generation != _selectionGeneration) return;
        if (ok || playback.snapshot.rhythm == selected) {
          _following = true;
          infoFinished.value = false;
          _apply(playback.snapshot);
        } else {
          infoError.value = error.value;
        }
      }
    } finally {
      if (generation == _selectionGeneration) infoBusy.value = false;
    }
  }

  /// 校验型号和片段后启动，当前同一节奏只返回现有会话。
  Future<bool> start(Rhythm value, {bool Function()? isCurrent}) async {
    if (playback.active && rhythm.value?.id == value.id) return true;
    final modelId = value.deviceModelId;
    if (modelId == null) {
      error.value = 'Missing device model.';
      return false;
    }

    final generation = _sessionGeneration;
    final result = await catalog.capabilities(modelId);
    if (generation != _sessionGeneration || isCurrent?.call() == false) {
      return false;
    }
    if (result.isFailure) {
      error.value = result.failureOrNull!.message;
      return false;
    }

    final ok = await playback.start(value, result.valueOrNull!);
    if (generation != _sessionGeneration) return false;
    if (ok) capabilities.assignAll(result.valueOrNull!);
    return ok;
  }

  /// 获取暂停锁并成功暂停设备后才允许进入编辑器。
  Future<bool> beginEditing() async {
    final generation = _sessionGeneration;
    final connected = target.value;
    var caps = <RhythmChannelCapability>[];
    if (connected != null) {
      final result = await catalog.capabilities(connected.modelId);
      if (generation != _sessionGeneration) return false;
      if (result.isFailure) {
        error.value = result.failureOrNull!.message;
        return false;
      }
      caps = result.valueOrNull!;
    }

    final ok = await playback.beginEditing(caps);
    if (!ok) error.value ??= 'Unable to pause the device. Please try again.';
    return ok;
  }

  @override
  void onClose() {
    unawaited(_playback?.cancel());
    unawaited(_device?.cancel());
    super.onClose();
  }
}
