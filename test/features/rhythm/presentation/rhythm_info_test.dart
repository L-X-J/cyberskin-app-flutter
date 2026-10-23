// 详情预览、真实执行会话隔离、停止/完成、异步保护与片段触觉回归。
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm_program.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_catalog.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_device_port.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_repository.dart';
import 'package:cyberskin_app/features/rhythm/domain/services/rhythm_playback.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/info/rhythm_info_page.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/info/widgets/rhythm_segment_queue.dart';
import 'package:cyberskin_app/features/rhythm/presentation/rhythm_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const caps = [
  RhythmChannelCapability(
    channel: RhythmChannel.thrust,
    modes: [],
    variableSpeed: true,
  ),
];
Rhythm fixture(int id, {int seconds = 30, int count = 2}) => Rhythm(
  id: id,
  deviceModelId: 1,
  name: 'Rhythm $id',
  segments: List.generate(
    count,
    (index) => RhythmStep(
      durationSec: seconds,
      channels: [],
    ).encode(startSeconds: index * seconds),
  ),
);

class Port implements RhythmDevicePort {
  @override
  RhythmDeviceTarget? target = const RhythmDeviceTarget(
    modelId: 1,
    remoteId: 'a',
    name: 'Test',
  );
  final eventsController = StreamController<RhythmDeviceEvent>.broadcast(
    sync: true,
  );
  final commands = <String>[];
  @override
  Stream<RhythmDeviceEvent> get events => eventsController.stream;
  @override
  Future<Result<void>> send(String command, RhythmDeviceTarget target) async {
    commands.add(command);
    return const Result.ok(null);
  }

  @override
  Future<void> startBackground() async {}
  @override
  Future<void> stopBackground() async {}
}

class Catalog implements RhythmCatalog {
  Completer<Result<List<RhythmChannelCapability>>>? pending;
  @override
  Future<Result<List<RhythmChannelCapability>>> capabilities(int id) async {
    if (pending != null) return pending!.future;
    return const Result.ok(caps);
  }

  @override
  Future<Result<List<RhythmModel>>> models() async => const Result.ok([]);
}

class Repository extends Fake implements RhythmRepository {
  Completer<Result<Rhythm>>? pending;
  int loads = 0, downloads = 0;
  @override
  Future<Result<Rhythm>> getById(int id, {bool loadProgram = true}) async {
    loads++;
    final result =
        await (pending?.future ?? Future.value(Result.ok(fixture(id))));
    if (loadProgram) {
      downloads++;
      return result;
    }
    if (result.isFailure) return result;
    final value = result.valueOrNull!;
    return Result.ok(
      Rhythm(
        id: value.id,
        deviceModelId: value.deviceModelId,
        name: value.name,
        segmentCount: value.segmentCount ?? value.segments.length,
        totalSeconds:
            value.totalSeconds ??
            value.segments.fold<int>(
              0,
              (total, segment) => total + segment.program.durationSeconds,
            ),
        previewSegments: value.segments.take(3).toList(),
      ),
    );
  }
}

void main() {
  late Port port;
  late Catalog catalog;
  late RhythmPlayback playback;
  late RhythmSessionController session;
  late Repository repository;
  setUp(() {
    Get.testMode = true;
    port = Port();
    catalog = Catalog();
    playback = RhythmPlayback(port);
    repository = Repository();
    session = Get.put(
      RhythmSessionController(playback, catalog, repository: repository),
    );
  });
  tearDown(() async {
    await playback.dispose();
    await port.eventsController.close();
    Get.reset();
  });
  testWidgets('详情与能力加载期间不可播放，短预览不下载完整JSON', (tester) async {
    repository.pending = Completer();
    final loading = session.select(
      Rhythm(
        id: 1,
        deviceModelId: 1,
        name: 'Rhythm 1',
        segmentCount: 2,
        totalSeconds: 60,
      ),
    );
    await tester.pumpWidget(const GetMaterialApp(home: RhythmInfoPage()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('rhythm-info-loading')), findsOneWidget);
    expect(find.text('Rhythm 1'), findsOneWidget);
    expect(find.text('Total segments: 2'), findsOneWidget);
    expect(session.infoTotalRemaining.value, 60);
    final buttons = tester.widgetList<AppLiquidGlassButton>(
      find.byType(AppLiquidGlassButton),
    );
    expect(
      buttons.singleWhere((button) => button.label == 'Edit').onPressed,
      isNull,
    );
    expect(
      buttons.singleWhere((button) => button.label == 'Start').onPressed,
      isNull,
    );
    await session.toggleInfo();
    expect(port.commands, isEmpty);
    repository.pending!.complete(Result.ok(fixture(1)));
    await loading;
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('rhythm-info-loading')), findsNothing);
    expect(session.infoReady.value, isTrue);
    expect(session.infoRhythm.value!.hasCompleteProgram, isFalse);
    expect(repository.downloads, 0);
    expect(port.commands, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('详情只取短预览，Start 才加载完整程序', () async {
    await session.select(Rhythm(id: 1, deviceModelId: 1));
    expect(repository.loads, 1);
    expect(repository.downloads, 0);
    expect(session.infoRhythm.value!.hasCompleteProgram, isFalse);
    expect(session.infoRhythm.value!.previewSegments, hasLength(2));
    expect(port.commands, isEmpty);
    await session.toggleInfo();
    expect(repository.downloads, 1);
    expect(playback.active, isTrue);
  });
  test('详情加载失败可重试，失败及加载期间不启动设备', () async {
    repository.pending = Completer();
    final loading = session.select(Rhythm(id: 1, deviceModelId: 1));
    repository.pending!.complete(
      const Result.failure(
        AppFailure(code: FailureCode.network, message: 'Download failed'),
      ),
    );
    await loading;
    expect(session.infoLoading.value, isFalse);
    expect(session.infoReady.value, isFalse);
    expect(session.infoError.value, 'Download failed');
    await session.toggleInfo();
    expect(port.commands, isEmpty);
    repository.pending = null;
    await session.retryInfo();
    expect(repository.loads, 2);
    expect(session.infoReady.value, isTrue);
    expect(session.infoError.value, isNull);
  });
  test('离开后的JSON响应不覆盖新选择或结束新页面loading', () async {
    repository.pending = Completer();
    final old = session.select(Rhythm(id: 1, deviceModelId: 1));
    final pending = repository.pending!;
    session.leaveInfo();
    final selected = fixture(2);
    await session.select(selected);
    pending.complete(Result.ok(fixture(1)));
    await old;
    expect(session.infoRhythm.value, same(selected));
    expect(session.infoLoading.value, isFalse);
    expect(session.infoReady.value, isTrue);
    expect(port.commands, isEmpty);
  });
  test('预览无指令，其他旧会话不能覆盖选择，同会话返回保留暂停', () async {
    final a = fixture(1), b = fixture(2);
    await session.select(a);
    expect(port.commands, isEmpty);
    await session.toggleInfo();
    expect(playback.active, isTrue);
    await session.select(b);
    await playback.pause();
    expect(session.infoRhythm.value, same(b));
    expect(session.infoPhase.value, RhythmPlaybackPhase.idle);
    await session.select(a);
    expect(session.infoPhase.value, RhythmPlaybackPhase.paused);
    final n = port.commands.length;
    session.leaveInfo();
    expect(playback.active, isTrue);
    expect(port.commands.length, n);
    await session.toggleInfo();
    expect(playback.active, isFalse);
    expect(session.infoRhythm.value, same(a));
    expect(session.infoFinished.value, isTrue);
    // 停止完成值早于后台资源清理结束，模拟用户下一帧点击。
    await Future<void>.delayed(Duration.zero);
    await session.toggleInfo();
    expect(playback.snapshot.index, 0);
    expect(playback.snapshot.phase, RhythmPlaybackPhase.running);
  });
  test('返回活动会话时刷新能力不阻止立即停止设备', () async {
    final selected = fixture(1);
    await session.select(selected);
    await session.toggleInfo();
    catalog.pending = Completer();
    final loading = session.select(selected);
    expect(session.infoLoading.value, isFalse);
    expect(session.infoReady.value, isTrue);
    await session.toggleInfo();
    expect(playback.active, isFalse);
    catalog.pending!.complete(
      const Result.failure(
        AppFailure(
          code: FailureCode.network,
          message: 'Capabilities unavailable',
        ),
      ),
    );
    await loading;
  });
  test('异步启动防连击，离开页面使等待能力请求失效', () async {
    await session.select(fixture(1));
    catalog.pending = Completer();
    final start = session.toggleInfo();
    await session.toggleInfo();
    session.leaveInfo();
    catalog.pending!.complete(const Result.ok(caps));
    await start;
    expect(port.commands, isEmpty);
    expect(session.infoBusy.value, isFalse);
  });
  test('过期预览能力不覆盖新选择', () async {
    catalog.pending = Completer();
    final old = session.select(fixture(1));
    final pending = catalog.pending!;
    catalog.pending = null;
    final b = fixture(2);
    await session.select(b);
    pending.complete(const Result.ok([]));
    await old;
    expect(session.infoRhythm.value, same(b));
    expect(session.capabilities, caps);
  });
  test('断连停止失败保留进度，不隐式重启或改绑同型号设备', () async {
    await session.select(fixture(1));
    await session.toggleInfo();
    port.target = null;
    port.eventsController.add(const RhythmDeviceEvent(null));
    await session.toggleInfo();
    expect(playback.active, isTrue);
    expect(session.infoPhase.value, RhythmPlaybackPhase.interrupted);
    expect(session.infoFinished.value, isFalse);
    port.target = const RhythmDeviceTarget(
      modelId: 1,
      remoteId: 'b',
      name: 'Other',
    );
    expect(await playback.resume(), isFalse);
    expect(playback.snapshot.phase, RhythmPlaybackPhase.interrupted);
  });
  test('领域完成停止并清空执行器，但详情保留节奏供重新开始', () async {
    final a = fixture(1, seconds: 1, count: 1);
    await session.select(a);
    await session.toggleInfo();
    await Future<void>.delayed(const Duration(milliseconds: 1450));
    expect(playback.snapshot.phase, RhythmPlaybackPhase.completed);
    expect(playback.snapshot.rhythm, isNull);
    expect(session.infoRhythm.value, same(a));
    expect(session.infoFinished.value, isTrue);
    await session.toggleInfo();
    expect(session.infoPhase.value, RhythmPlaybackPhase.running);
    expect(session.infoFinished.value, isFalse);
  });
  testWidgets('详情按钮准确文案，停止与完成不关闭页面，窄屏大字无溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await session.select(fixture(1));
    await tester.pumpWidget(
      const GetMaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: RhythmInfoPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Start'), findsOneWidget);
    expect(port.commands, isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.text('Start'));
      await Future<void>.delayed(const Duration(milliseconds: 1));
    });
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Stop'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Stop'));
      await Future<void>.delayed(const Duration(milliseconds: 1));
    });
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Restart'), findsOneWidget);
    expect(find.byType(RhythmInfoPage), findsOneWidget);
    session.infoPhase.value = RhythmPlaybackPhase.completed;
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(RhythmInfoPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => playback.dispose());
  });
  testWidgets('片段切换一次轻触，计时/重建/重启无轻触，减少动态效果无位移', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final a = fixture(1, count: 3);
    Future<void> show(
      int index,
      int remaining, {
      bool reduced = false,
      Rhythm? rhythm,
      RhythmPlaybackPhase phase = RhythmPlaybackPhase.running,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(
              body: RhythmSegmentQueue(
                rhythm: rhythm ?? a,
                index: index,
                remaining: remaining,
                phase: phase,
                capabilities: caps,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await show(0, 30);
    await show(0, 29);
    expect(calls, isEmpty);
    await show(1, 30);
    expect(calls.length, 1);
    expect(calls.single.arguments, 'HapticFeedbackType.lightImpact');
    await tester.pump(const Duration(milliseconds: 400));
    await show(1, 29);
    await show(0, 30);
    expect(calls.length, 1);
    await show(1, 30, reduced: true);
    expect(calls.length, 2);
    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    await show(2, 30, phase: RhythmPlaybackPhase.paused);
    expect(calls.length, 2);
    expect(tester.binding.transientCallbackCount, 0);
    await show(0, 30, rhythm: fixture(2, count: 3));
    expect(calls.length, 2);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('叠放卡组预览连续提升，旧卡上退，末段收拢且保留自然高度', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final a = Rhythm(
      id: 7,
      deviceModelId: 1,
      name: 'Dynamic deck fixture',
      segments: [
        RhythmStep(durationSec: 30, channels: []).encode(),
        RhythmStep(
          durationSec: 30,
          channels: [
            for (final channel in RhythmChannel.values)
              RhythmChannelSetting(
                channel: channel,
                on: true,
                mode: channel == RhythmChannel.heat ? null : 1,
              ),
          ],
        ).encode(),
        RhythmStep(durationSec: 30, channels: []).encode(),
      ],
    );
    final deckCaps = [
      for (final channel in RhythmChannel.values)
        RhythmChannelCapability(
          channel: channel,
          modes: ['A long backend mode name that wraps naturally'],
          variableSpeed: true,
        ),
    ];
    const capture = ValueKey('deck-capture');
    Finder card(int index) => find.byKey(ValueKey(('segment', a, index)));
    Future<void> show(
      int index, {
      bool reduced = false,
      double scale = 1,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: reduced,
              textScaler: TextScaler.linear(scale),
            ),
            child: RepaintBoundary(
              key: capture,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: RhythmSegmentQueue(
                      rhythm: a,
                      index: index,
                      remaining: 30,
                      phase: RhythmPlaybackPhase.running,
                      capabilities: deckCaps,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> snapshot(String name) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(capture),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final file = File('build/ui/rhythm/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    await show(0);
    final current = tester.getRect(card(0));
    final preview = tester.getRect(card(1));
    expect(preview.top, current.bottom - 32);
    expect(preview.left, current.left + 12);
    expect(preview.right, current.right - 12);
    await snapshot('info_deck_rest_402x874_text1.0');
    await show(1);
    expect(tester.getTopLeft(card(1)), preview.topLeft);
    await tester.pump(const Duration(milliseconds: 120));
    final firstY = tester.getTopLeft(card(1)).dy;
    expect(firstY, lessThan(preview.top));
    expect(firstY, greaterThan(current.top));
    expect(tester.getTopLeft(card(0)).dy, lessThan(current.top));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getTopLeft(card(1)).dy, lessThan(firstY));
    await snapshot('info_deck_mid_402x874_text1.0');
    await tester.pump(const Duration(milliseconds: 240));
    expect(card(0), findsNothing);
    expect(tester.getTopLeft(card(1)), current.topLeft);
    expect(tester.getSize(card(1)).height, greaterThan(current.height));
    expect(
      find.text('A long backend mode name that wraps naturally'),
      findsNWidgets(3),
    );
    expect(
      tester.getTopLeft(card(2)).dy,
      tester.getBottomLeft(card(1)).dy - 32,
    );
    await snapshot('info_deck_promoted_402x874_text1.0');
    await show(2);
    await tester.pump(const Duration(milliseconds: 480));
    expect(card(1), findsNothing);
    expect(tester.getTopLeft(card(2)), current.topLeft);
    // 减少动态效果也在动画途中立即生效。
    await show(0);
    await show(1);
    await tester.pump(const Duration(milliseconds: 100));
    await show(1, reduced: true);
    expect(card(0), findsNothing);
    expect(tester.getTopLeft(card(1)), current.topLeft);
    expect(tester.binding.transientCallbackCount, 0);
    tester.view.physicalSize = const Size(320, 640);
    await show(0, scale: 2);
    final large = tester.getRect(card(0));
    expect(large.height, greaterThan(current.height));
    expect(tester.getTopLeft(card(1)).dy, large.bottom - 32);
    await snapshot('info_deck_rest_320x640_text2.0');
    await show(1, scale: 2);
    await tester.pump(const Duration(milliseconds: 240));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 240));
    expect(
      tester.getBottomLeft(card(2)).dy,
      tester.getBottomLeft(find.byType(RhythmSegmentQueue)).dy,
    );
    expect(tester.takeException(), isNull);
  });
}
