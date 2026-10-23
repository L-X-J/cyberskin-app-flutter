// 训练定向验证的公共内存边界，不连接网络或物理设备。
import 'dart:async';

import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/control/domain/repositories/device_playback_port.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/domain/repositories/user_device_repository.dart';
import 'package:cyberskin_app/features/training/domain/entities/training.dart';
import 'package:cyberskin_app/features/training/domain/repositories/training_repository.dart';
import 'package:flutter_test/flutter_test.dart';

TrainingDetail course(
  int id, {
  String command = 't:40',
  String range = '00:00-00:10',
  int total = 10,
}) => TrainingDetail(
  summary: TrainingSummary(
    id: id,
    nameEn: 'Training $id',
    deviceModelId: 1,
    intensity: '6',
    totalSeconds: total,
    stageCount: 1,
  ),
  purposeSummary: 'Training purpose',
  purposeUrl: 'https://store.test/training/purpose.html',
  programUrl: 'https://store.test/training/$id.json',
  programDownloadUrl: 'https://store.test/training/$id.json?signature=1',
  customModes: [
    TrainingCustomMode(
      range: range,
      description: 'Stretch',
      commandData: command,
      additionalProperties: const {},
    ),
  ],
);
DeviceModelDetail model() => DeviceModelDetail(
  summary: const DeviceModelSummary(id: 1, name: 'Model 1'),
  supportedActions: const [
    {
      'code': 't',
      'modes': ['Mode 1'],
      'variableSpeed': true,
    },
  ],
);

class Catalog extends Fake implements DeviceCatalogRepository {
  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async =>
      Result.ok(model());
}

class Repository extends Fake implements TrainingRepository {
  final pending = <int, Completer<Result<TrainingDetail>>>{};
  TrainingDetail? value;
  int loads = 0, downloads = 0;
  final programPending = <int, Completer<Result<TrainingDetail>>>{};
  int? filtered;
  @override
  Future<Result<String>> loadPurpose(String url) async =>
      const Result.ok('<p>Training purpose</p>');
  @override
  Future<Result<TrainingDetail>> getTraining(int id) async {
    loads++;
    return pending[id]?.future ??
        Result.ok((value ?? course(id)).withProgram([]));
  }

  @override
  Future<Result<TrainingDetail>> loadProgram(TrainingDetail metadata) async {
    downloads++;
    final id = metadata.summary.id!;
    return programPending[id]?.future ?? Result.ok(value ?? course(id));
  }

  @override
  Future<Result<List<TrainingSummary>>> listTrainings({
    int? deviceModelId,
  }) async {
    filtered = deviceModelId;
    return Result.ok([course(1).summary]);
  }
}

class Devices extends Fake implements UserDeviceRepository {
  List<UserDevice> values = const [UserDevice(id: 1, deviceModelId: 2)];
  @override
  Future<Result<List<UserDevice>>> listUserDevices() async => Result.ok(values);
}

class Port implements DevicePlaybackPort {
  @override
  DevicePlaybackTarget? target = const DevicePlaybackTarget(
    modelId: 1,
    remoteId: 'a',
    name: 'Model 1',
  );
  final controller = StreamController<DevicePlaybackEvent>.broadcast(
    sync: true,
  );
  final commands = <String>[];
  bool failStop = false;
  Completer<void>? gate;
  @override
  Stream<DevicePlaybackEvent> get events => controller.stream;
  @override
  Future<Result<void>> send(String command, DevicePlaybackTarget target) async {
    commands.add(command);
    await gate?.future;
    return failStop && command == 't:s'
        ? const Result.failure(
            AppFailure(code: FailureCode.business, message: 'Stop failed'),
          )
        : const Result.ok(null);
  }

  @override
  Future<void> startBackground() async {}
  @override
  Future<void> stopBackground() async {}
  void connect(DevicePlaybackTarget? next, {bool expired = false}) {
    target = next;
    controller.add(DevicePlaybackEvent(next, sessionExpired: expired));
  }
}
