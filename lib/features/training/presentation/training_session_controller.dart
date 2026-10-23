// 应用级训练预览与会话编排；页面退出仅取消待启动请求，不释放公共播放器。
import 'dart:async';

import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../control/domain/entities/device_program.dart';
import '../../control/domain/repositories/device_playback_port.dart';
import '../../control/domain/services/device_program_playback.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../domain/entities/training.dart';
import '../domain/repositories/training_repository.dart';
import '../domain/services/training_program.dart';

/// 运行快照独立于预览选择，浏览课程不会切换设备输出。
final class TrainingSessionController extends GetxController {
  /// 创建训练展示组件。
  TrainingSessionController(this.repository, this.catalog, this.playback);

  /// 训练内容访问边界。
  final TrainingRepository repository;

  /// 后台已发布型号和能力的访问入口。
  final DeviceCatalogRepository catalog;

  /// 应用内唯一公共播放引擎。
  final DeviceProgramPlayback playback;

  /// 当前预览课程摘要，首帧可由路由提供。
  final summary = Rxn<TrainingSummary>();

  /// 当前详情元数据；Start 加载完整程序后替换，独立于后台运行快照。
  final detail = Rxn<TrainingDetail>();

  /// 当前实际连接的设备身份；断开时为空。
  final target = Rxn<DevicePlaybackTarget>();

  /// 详情元数据、能力加载及显式操作状态。
  final loading = false.obs, ready = false.obs, busy = false.obs;

  /// 当前详情是否已经停止或完成，用于显示 Restart。
  final finished = false.obs;

  /// 当前详情对应的引擎阶段；预览保持 idle。
  final phase = DeviceProgramPlaybackPhase.idle.obs;

  /// 公共引擎计算的总剩余秒数。
  final remaining = 0.obs;

  /// 可安全向用户展示的当前操作或查询错误。
  final error = RxnString();

  /// 自然完成事件序号，每个会话只递增一次。
  final completion = 0.obs;

  DeviceProgram? _prepared, _runningProgram, _candidate;
  TrainingDetail? _candidateDetail;
  TrainingDetail? _runningDetail;
  DeviceModelDetail? _model;
  DeviceProgramPlaybackSnapshot? _previous;
  StreamSubscription<DeviceProgramPlaybackSnapshot>? _changes;
  StreamSubscription<DevicePlaybackEvent>? _devices;
  int _selection = 0, _account = 0, _infoOwner = 0;
  int? _id;
  bool _following = false;

  @override
  void onInit() {
    super.onInit();
    target.value = playback.port.target;
    _previous = playback.snapshot;
    _changes = playback.changes.listen(_apply);
    _devices = playback.port.events.listen((event) {
      target.value = event.target;
      if (!event.sessionExpired) return;
      _account++;
      _selection++;
      _infoOwner++;
      _following = false;
      _prepared = _runningProgram = _candidate = null;
      _candidateDetail = null;
      _runningDetail = null;
      _model = null;
      _id = null;
      summary.value = null;
      detail.value = null;
      loading.value = ready.value = busy.value = false;
      remaining.value = 0;
      error.value = null;
      finished.value = false;
      phase.value = DeviceProgramPlaybackPhase.idle;
      if (Get.currentRoute.startsWith('/training')) {
        Get.offAllNamed<void>(AppRoutes.home);
      }
    });
  }

  void _apply(DeviceProgramPlaybackSnapshot snapshot) {
    if (_candidate != null && identical(snapshot.program, _candidate)) {
      _runningProgram = _candidate;
      _runningDetail = _candidateDetail;
      _following = _runningDetail?.summary.id == summary.value?.id;
      _candidate = null;
      _candidateDetail = null;
    }
    final wasOurs =
        identical(_previous?.program, _runningProgram) &&
        _runningProgram != null;
    final isOurs =
        identical(snapshot.program, _runningProgram) && _runningProgram != null;
    final ended = wasOurs && snapshot.program == null;
    if (ended && snapshot.phase == DeviceProgramPlaybackPhase.completed) {
      completion.value++;
      if (Get.context != null) Get.snackbar('Training', 'Training complete.');
    }
    if (_following && (isOurs || ended)) {
      phase.value = snapshot.phase;
      remaining.value = snapshot.totalRemainingSeconds;
      error.value = snapshot.message;
      if (ended) {
        finished.value = true;
        _following = false;
      }
    } else if (_following && !isOurs && snapshot.program != null) {
      // rhythm / 手动操作接管后，旧页面不能停止新会话。
      _following = false;
      phase.value = DeviceProgramPlaybackPhase.idle;
      finished.value = true;
      remaining.value = summary.value?.totalSeconds ?? 0;
    }
    _previous = snapshot;
  }

  /// 首帧使用路由摘要；没有摘要也可按 ID 独立加载。活动会话复用被冻结的完整输入。
  Future<void> select(
    int id, {
    TrainingSummary? initial,
    bool preserveOwner = false,
  }) async {
    if (!preserveOwner) _infoOwner++;
    final generation = ++_selection;
    final account = _account;
    bool current() =>
        !isClosed && generation == _selection && account == _account;
    _id = id;
    _following =
        playback.active &&
        identical(playback.snapshot.program, _runningProgram) &&
        _runningDetail?.summary.id == id;
    _prepared = _following ? _runningProgram : null;
    _model = null;
    detail.value = _following ? _runningDetail : null;
    summary.value = detail.value?.summary ?? initial ?? TrainingSummary(id: id);
    phase.value = DeviceProgramPlaybackPhase.idle;
    finished.value = busy.value = false;
    error.value = null;
    remaining.value = summary.value?.totalSeconds ?? 0;
    ready.value = _following;
    loading.value = !_following;
    if (_following) {
      _apply(playback.snapshot);
      return;
    }
    try {
      final result = await repository.getTraining(id);
      if (!current()) return;
      if (result.isFailure) {
        error.value = result.failureOrNull!.message;
        return;
      }

      /// 从同一课程或引擎快照导出的展示值。
      final value = result.valueOrNull!;
      if (value.summary.id != id) {
        throw const FormatException(
          'Training response does not match this course.',
        );
      }
      detail.value = value;
      summary.value = value.summary;
      remaining.value = value.summary.totalSeconds ?? 0;

      /// 本轮列表筛选使用的型号；为空时不限制型号。
      final modelId = value.summary.deviceModelId;
      if (modelId == null) {
        throw const FormatException(
          'This course needs a device model. Please republish it.',
        );
      }
      final capabilities = await catalog.getDeviceModelDetail(modelId);
      if (!current()) return;
      if (capabilities.isFailure) {
        error.value = capabilities.failureOrNull!.message;
        return;
      }
      if (value.programUrl?.isNotEmpty != true) {
        throw const FormatException(
          'Training JSON is unavailable. Please republish this course.',
        );
      }
      _model = capabilities.valueOrNull!;
      ready.value = true;
    } on FormatException catch (failure) {
      if (current()) error.value = failure.message;
    } on Object {
      if (current()) {
        error.value = 'Unable to load this training. Please try again.';
      }
    } finally {
      if (current()) loading.value = false;
    }
  }

  /// 重试当前详情选择，不重复发送在途加载请求。
  Future<void> retry() async {
    if (!loading.value && _id != null) {
      await select(_id!, initial: summary.value, preserveOwner: true);
    }
  }

  /// 详情页持有的选择世代，旧页面释放时不能取消新页面的加载。
  int get selectionVersion => _infoOwner;

  /// 返回时取消详情请求及尚未执行的启动；后台会话仍由唯一公共引擎持有。
  void leaveInfo({int? expectedSelection}) {
    if (expectedSelection != null && expectedSelection != _infoOwner) return;
    _selection++;
    _infoOwner++;
    loading.value = false;
    busy.value = false;
  }

  /// Start / Stop / Restart；停止必须绑定原程序，失败时保留恢复和再次停止的入口。
  Future<void> toggle() async {
    if (busy.value ||
        loading.value ||
        !ready.value ||
        detail.value == null ||
        playback.snapshot.busy) {
      return;
    }
    final generation = _selection;
    final account = _account;
    bool current() =>
        !isClosed && generation == _selection && account == _account;
    busy.value = true;
    try {
      if (_following && playback.active) {
        final expected = _runningProgram;
        final stopped = await playback.stop(expectedProgram: expected);
        if (current() && !stopped) {
          error.value =
              playback.snapshot.message ??
              'Unable to stop this training. Please try again.';
        }
        return;
      }
      if (_prepared == null) {
        final connected = playback.port.target;
        if (connected == null ||
            connected.modelId != summary.value?.deviceModelId) {
          error.value = 'Connect the matching device before starting training.';
          return;
        }
        final loaded = await repository.loadProgram(detail.value!);
        if (!current()) return;
        if (loaded.isFailure) {
          error.value = loaded.failureOrNull!.message;
          return;
        }
        final value = loaded.valueOrNull!;
        _prepared = TrainingProgram.compile(value, _model!);
        detail.value = value;
        summary.value = value.summary;
        remaining.value = value.summary.totalSeconds ?? 0;
      }
      final prepared = _prepared!;
      // 运行输入在启动前冻结，后续网络变化不影响该会话。
      final selected = detail.value!;
      _candidate = prepared;
      _candidateDetail = selected;
      final ok = await playback.prepareAndStart(
        () => prepared,
        isCurrent: current,
      );
      if (identical(_candidate, prepared)) {
        _candidate = null;
        _candidateDetail = null;
      }
      if (!current()) return;
      if (ok || identical(playback.snapshot.program, prepared)) {
        _following = true;
        finished.value = false;
        _apply(playback.snapshot);
      } else {
        _following = false;
        error.value =
            playback.snapshot.message ?? 'Unable to start this training.';
      }
    } on FormatException catch (failure) {
      if (current()) {
        ready.value = false;
        error.value = failure.message;
      }
    } finally {
      if (current()) busy.value = false;
    }
  }

  @override
  void onClose() {
    _selection++;
    unawaited(_changes?.cancel());
    unawaited(_devices?.cancel());
    super.onClose();
  }
}
