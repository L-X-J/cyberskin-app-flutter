// 训练列表查询及型号选择，连接型号优先，解绑或退出后作废旧响应。
import 'dart:async';

import 'package:get/get.dart';

import '../../../../control/domain/repositories/device_playback_port.dart';
import '../../../../device/domain/repositories/user_device_repository.dart';
import '../../../domain/entities/training.dart';
import '../../../domain/repositories/training_repository.dart';

/// 训练目录控制器，负责型号优先级和查询世代。
final class TrainingHomeController extends GetxController {
  /// 创建训练目录控制器，负责型号优先级和查询世代。
  TrainingHomeController(this.repository, this.devices, this.port);

  /// 训练内容访问边界。
  final TrainingRepository repository;

  /// 当前账号的设备绑定访问边界。
  final UserDeviceRepository devices;

  /// 公共播放器的设备身份与事件端口。
  final DevicePlaybackPort port;

  /// 已成功加载的课程摘要；刷新失败保留旧数据。
  final trainings = <TrainingSummary>[].obs;

  /// 完整详情及能力加载状态。
  final loading = false.obs;

  /// 可安全向用户展示的当前操作或查询错误。
  final error = RxnString();

  /// 当前实际连接的设备身份；断开时为空。
  final target = Rxn<DevicePlaybackTarget>();

  /// 本轮列表筛选使用的型号；为空时不限制型号。
  final modelId = RxnInt();
  StreamSubscription<DevicePlaybackEvent>? _subscription;
  int _generation = 0;

  @override
  void onInit() {
    super.onInit();
    target.value = port.target;
    _subscription = port.events.listen((event) {
      final previous = target.value?.modelId;
      target.value = event.target;
      if (event.sessionExpired) {
        _generation++;
        trainings.clear();
        loading.value = false;
        error.value = null;
        return;
      }
      if (previous != event.target?.modelId) unawaited(load());
    });
    unawaited(load());
  }

  /// 读取当前型号的课程目录，忽略较早查询的迟到响应。
  Future<void> load() async {
    final generation = ++_generation;
    bool current() => !isClosed && generation == _generation;
    loading.value = true;
    error.value = null;
    try {
      var selected = port.target?.modelId;
      if (selected == null) {
        final bound = await devices.listUserDevices();
        if (!current()) return;
        if (bound.isFailure) {
          error.value = bound.failureOrNull!.message;
          return;
        }
        final models = bound.valueOrNull!
            .map((device) => device.deviceModelId)
            .whereType<int>()
            .toSet();
        if (models.length == 1) selected = models.single;
      }
      if (!current()) return;
      modelId.value = selected;
      final result = await repository.listTrainings(deviceModelId: selected);
      if (!current()) return;
      if (result.isSuccess) {
        trainings.assignAll(result.valueOrNull!);
      } else {
        error.value = result.failureOrNull!.message;
      }
    } on Object {
      if (current()) {
        error.value = 'Unable to load training courses. Please try again.';
      }
    } finally {
      if (current()) loading.value = false;
    }
  }

  @override
  void onClose() {
    _generation++;
    unawaited(_subscription?.cancel());
    super.onClose();
  }
}
