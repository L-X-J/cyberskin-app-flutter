// 训练公共播放、预览隔离、失败保留及异步请求回归。
import 'dart:async';

import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/control/domain/repositories/device_playback_port.dart';
import 'package:cyberskin_app/features/control/domain/services/device_program_playback.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm_program.dart';
import 'package:cyberskin_app/features/rhythm/domain/services/rhythm_playback.dart';
import 'package:cyberskin_app/features/training/domain/entities/training.dart';
import 'package:cyberskin_app/features/training/domain/services/training_program.dart';
import 'package:cyberskin_app/features/training/presentation/pages/home/training_home_controller.dart';
import 'package:cyberskin_app/features/training/presentation/training_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'training_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Port port;
  late DeviceProgramPlayback engine;
  late Repository repository;
  late TrainingSessionController session;
  setUp(() {
    Get.testMode = true;
    port = Port();
    engine = DeviceProgramPlayback(port);
    repository = Repository();
    session = Get.put(
      TrainingSessionController(repository, Catalog(), engine),
      permanent: true,
    );
  });
  tearDown(() async {
    session.onClose();
    await engine.dispose();
    await port.controller.close();
    Get.reset();
  });
  test(
    'preview has no output; Start Stop Restart share one loaded program',
    () async {
      await session.select(1);
      expect(session.ready.value, isTrue);
      expect(port.commands, isEmpty);
      expect(repository.downloads, 0);
      expect(session.detail.value!.customModes, isEmpty);
      await session.toggle();
      expect(repository.downloads, 1);
      expect(engine.snapshot.program?.source, 'training');
      expect(session.phase.value, DeviceProgramPlaybackPhase.running);
      session.leaveInfo();
      expect(engine.active, isTrue);
      await session.select(1);
      expect(repository.loads, 1);
      await session.toggle();
      expect(engine.active, isFalse);
      expect(session.finished.value, isTrue);
      await session.toggle();
      expect(engine.active, isTrue);
      expect(repository.loads, 1);
    },
  );
  test('leaving during JSON download cannot start a stale course', () async {
    await session.select(1);
    repository.programPending[1] = Completer();
    final start = session.toggle();
    expect(repository.downloads, 1);
    session.leaveInfo();
    await session.select(2);
    repository.programPending[1]!.complete(Result.ok(course(1)));
    await start;
    expect(port.commands, isEmpty);
    expect(session.summary.value?.id, 2);
    expect(engine.active, isFalse);
  });
  test('preview B cannot replace or receive progress from running A', () async {
    await session.select(1);
    await session.toggle();
    final running = engine.snapshot.program;
    await session.select(2);
    expect(engine.snapshot.program, same(running));
    expect(session.phase.value, DeviceProgramPlaybackPhase.idle);
    expect(session.summary.value?.id, 2);
    await session.toggle();
    expect(engine.snapshot.program?.id, '2');
  });
  test('late detail and leave-before-start do not alter new selection or send output', () async {
    final pending = Completer<Result<TrainingDetail>>();
    repository.pending[1] = pending;
    final first = session.select(1);
    session.leaveInfo();
    await session.select(2);
    pending.complete(Result.ok(course(1)));
    await first;
    expect(session.summary.value?.id, 2);
    expect(session.ready.value, isTrue);
    final start = session.toggle();
    session.leaveInfo();
    await start;
    expect(port.commands, isEmpty);
    expect(engine.active, isFalse);
  });
  test(
    'leaving while preflight stop awaits cancels actual training output',
    () async {
      await session.select(1);
      port.gate = Completer<void>();
      final start = session.toggle();
      await Future<void>.delayed(Duration.zero);
      expect(port.commands, ['t:s']);
      session.leaveInfo();
      port.gate!.complete();
      await start;
      expect(port.commands, ['t:s']);
      expect(engine.active, isFalse);
    },
  );
  test('stop failure preserves program; preview another course cannot lose its snapshot', () async {
    await session.select(1);
    await session.toggle();
    final running = engine.snapshot.program;
    port.failStop = true;
    await session.toggle();
    expect(engine.snapshot.program, same(running));
    expect(session.phase.value, DeviceProgramPlaybackPhase.interrupted);
    await session.select(2);
    await session.toggle();
    expect(engine.snapshot.program, same(running));
    await session.select(1);
    expect(session.ready.value, isTrue);
    expect(session.detail.value?.summary.id, 1);
    port.failStop = false;
    await session.toggle();
    expect(engine.active, isFalse);
  });
  test('disconnect resumes only on original device and relative commands cannot replay', () async {
    await session.select(1);
    await session.toggle();
    final original = port.target;
    port.connect(null);
    expect(engine.snapshot.phase, DeviceProgramPlaybackPhase.interrupted);
    port.connect(
      const DevicePlaybackTarget(modelId: 1, remoteId: 'b', name: 'Other'),
    );
    expect(await engine.resume(), isFalse);
    port.connect(original);
    expect(await engine.resume(), isTrue);
    await engine.stop();
    repository.value = course(2, command: 't:+');
    await session.select(2);
    await session.toggle();
    await engine.pause();
    expect(await engine.resume(), isFalse);
    expect(engine.snapshot.message, contains('relative'));
  });
  test(
    'training and rhythm use the same exclusive engine even for equal IDs',
    () async {
      await session.select(1);
      await session.toggle();
      final rhythm = RhythmPlayback.fromEngine(engine);
      final value = Rhythm(
        id: 1,
        name: 'Rhythm',
        deviceModelId: 1,
        segments: [
          RhythmSegment({
            'start-end': '00:00-00:10',
            'des': 'Stretch',
            'command_data': 't:20',
          }),
        ],
      );
      expect(
        await rhythm.start(value, const [
          RhythmChannelCapability(
            channel: RhythmChannel.thrust,
            modes: [],
            variableSpeed: true,
          ),
        ]),
        isTrue,
      );
      expect(engine.snapshot.program?.source, 'rhythm');
      expect(session.phase.value, DeviceProgramPlaybackPhase.idle);
      expect(session.finished.value, isTrue);
    },
  );
  test('logout invalidates pending loads and clears preview', () async {
    repository.pending[1] = Completer();
    final load = session.select(1);
    port.connect(null, expired: true);
    repository.pending[1]!.complete(Result.ok(course(1)));
    await load;
    expect(session.summary.value, isNull);
    expect(session.ready.value, isFalse);
    expect(port.commands, isEmpty);
  });
  test('compiler shares protocol rules, validates stats/modes, and inserts safe gaps', () {
    final program = TrainingProgram.compile(
      course(1, range: '00:03-00:10'),
      model(),
    );
    expect(program.steps.first.duration.inSeconds, 3);
    expect(program.steps.first.commands.single.toString(), 't:s');
    for (final value in [
      course(1, command: 's:20'),
      course(1, command: 'CM->t:2'),
      course(1, total: 11),
    ]) {
      expect(
        () => TrainingProgram.compile(value, model()),
        throwsFormatException,
      );
    }
  });
  test('list uses actual connected model then bound model then all', () async {
    final devices = Devices();
    final list = TrainingHomeController(repository, devices, port);
    await list.load();
    expect(repository.filtered, 1);
    port.target = null;
    await list.load();
    expect(repository.filtered, 2);
    devices.values = [];
    await list.load();
    expect(repository.filtered, isNull);
    list.onClose();
  });
  test('natural completion emits exactly one event and leaves the detail restartable', () async {
    repository.value = course(1, range: '00:00-00:01', total: 1);
    await session.select(1);
    await session.toggle();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    expect(session.completion.value, 1);
    expect(session.finished.value, isTrue);
    expect(session.remaining.value, 0);
    await engine.stop();
    expect(session.completion.value, 1);
    expect(session.ready.value, isTrue);
  });
}
