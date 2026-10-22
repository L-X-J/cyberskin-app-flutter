// 片段弹层的转场、保存保护和固定操作列回归；禁止真实 API/BLE。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm_program.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_catalog.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_device_port.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_repository.dart';
import 'package:cyberskin_app/features/rhythm/domain/services/rhythm_playback.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/rhythm_edit_controller.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_channel_editor.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_duration_wheel.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_segment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Repository implements RhythmRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected IO');
}

class _Catalog implements RhythmCatalog {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected IO');
}

class _Port implements RhythmDevicePort {
  @override
  Stream<RhythmDeviceEvent> get events => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected BLE');
}

const _capture = ValueKey('sheet-capture');
const _outgoing = ValueKey('segment-outgoing');
const _incoming = ValueKey('segment-incoming');

AppLiquidGlassButton _button(WidgetTester tester, String label) => tester
    .widgetList<AppLiquidGlassButton>(find.byType(AppLiquidGlassButton))
    .singleWhere((button) => button.label == label);

Future<RhythmEditController> _open(
  WidgetTester tester, {
  Size size = const Size(402, 874),
  double scale = 1,
  bool reduced = false,
  bool settle = true,
  int? index,
  int count = 0,
  List<String> modes = const [],
}) async {
  Get.testMode = true;
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final playback = RhythmPlayback(_Port());
  final controller = RhythmEditController(
    _Repository(),
    _Catalog(),
    playback,
    null,
  );
  controller.capabilities.addAll([
    for (final channel in RhythmChannel.values)
      RhythmChannelCapability(
        channel: channel,
        modes: modes,
        variableSpeed: true,
      ),
  ]);
  controller.segments.addAll([
    for (var i = 0; i < count; i++)
      RhythmStep(durationSec: 1199, channels: []).encode(),
  ]);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await playback.dispose();
    Get.reset();
  });
  await tester.pumpWidget(
    GetMaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(bottom: 24),
          disableAnimations: reduced,
        ),
        child: RepaintBoundary(key: _capture, child: child!),
      ),
      home: Scaffold(
        body: TextButton(
          onPressed: () => Get.bottomSheet<void>(
            RhythmSegmentSheet(controller: controller, index: index),
            isScrollControlled: true,
            ignoreSafeArea: true,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return controller;
}

Future<void> _capturePng(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('build/ui/rhythm/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('弹层完全打开后组件逐项淡入上浮，重建及 Continue 不重播', (tester) async {
    await _open(tester, settle: false);
    final opacityFinder = find.byKey(const ValueKey('segment-item-opacity-0'));
    final entranceFinder = find.byKey(
      const ValueKey('segment-item-entrance-0'),
    );
    double opacity() => tester.widget<Opacity>(opacityFinder).opacity;
    double offset() =>
        tester.widget<Transform>(entranceFinder).transform.storage[13];
    expect(opacity(), 0);
    expect(offset(), 24);
    final route = ModalRoute.of(
      tester.element(find.byType(RhythmSegmentSheet)),
    )!;
    expect(route.animation!.status, AnimationStatus.forward);
    await tester.pump(const Duration(milliseconds: 100));
    expect(opacity(), 0);
    expect(offset(), 24);
    // 本次大步进只完成路由动画，组件入场此时才启动。
    await tester.pump(const Duration(seconds: 1));
    expect(route.animation!.status, AnimationStatus.completed);
    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 180));
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('segment-item-opacity-1')))
          .opacity,
      lessThan(opacity()),
    );
    expect(opacity(), greaterThan(0));
    expect(opacity(), lessThan(1));
    expect(offset(), greaterThan(0));
    expect(offset(), lessThan(24));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    expect(offset(), 0);
    tester
        .widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel))
        .onChanged(5);
    await tester.pump();
    expect(opacity(), 1);
    expect(offset(), 0);
    _button(tester, 'Continue').onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(opacity(), 1);
    expect(offset(), 0);
    expect(find.byKey(_incoming), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('减少动态效果时 body 首帧直接显示', (tester) async {
    await _open(tester, reduced: true, settle: false);
    expect(
      tester
          .widget<Opacity>(find.byKey(const ValueKey('segment-item-opacity-0')))
          .opacity,
      1,
    );
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('segment-item-entrance-0')),
          )
          .transform
          .storage[13],
      0,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('新增片段即使有模式也默认不选中', (tester) async {
    await _open(tester, modes: ['Alpha', 'Beta']);
    final editors = tester.widgetList<RhythmChannelEditor>(
      find.byType(RhythmChannelEditor),
    );
    expect(editors, hasLength(3));
    for (final editor in editors) {
      expect(editor.setting.mode, isNull);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('Continue 左出右入、同步连击锁及保留秒数和通道配置', (tester) async {
    final controller = await _open(tester);
    // 当前滚轮没有 Custom 输入入口；通过公开回调验证历史非预设秒数保留。
    tester
        .widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel))
        .onChanged(1199);
    final editor = tester
        .widgetList<RhythmChannelEditor>(find.byType(RhythmChannelEditor))
        .first;
    editor.onChanged(
      const RhythmChannelSetting(
        channel: RhythmChannel.thrust,
        on: false,
        value: 73,
      ),
    );
    await tester.pumpAndSettle();
    final submit = _button(tester, 'Continue').onPressed!;
    final header = tester.getTopLeft(find.text('Add device rhythm'));
    final footer = tester.getRect(find.byKey(const ValueKey('segment-footer')));
    submit();
    submit();
    expect(controller.segments, hasLength(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    final outgoing = tester.widget<Transform>(find.byKey(_outgoing));
    final incoming = tester.widget<Transform>(find.byKey(_incoming));
    expect(outgoing.transform.storage[12], lessThan(0));
    expect(incoming.transform.storage[12], greaterThan(0));
    expect(
      outgoing.transform.storage[12].abs(),
      closeTo(incoming.transform.storage[12], 1),
    );
    expect(_button(tester, 'Continue').onPressed, isNull);
    expect(_button(tester, 'Confirm').onPressed, isNull);
    final lock = find.ancestor(
      of: find.byKey(_incoming),
      matching: find.byType(IgnorePointer),
    );
    expect(tester.widget<IgnorePointer>(lock.first).ignoring, isTrue);
    expect(tester.getTopLeft(find.text('Add device rhythm')), header);
    expect(
      tester.getRect(find.byKey(const ValueKey('segment-footer'))),
      footer,
    );
    await _capturePng(tester, 'segment_continue_mid_402x874_text1.0');
    await tester.pumpAndSettle();
    expect(find.byKey(_outgoing), findsNothing);
    expect(
      tester
          .widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel))
          .value,
      1199,
    );
    final saved = RhythmStep.decode(controller.segments.single);
    expect(saved.durationSec, 1199);
    expect(saved.channels.first.on, isFalse);
    expect(saved.channels.first.value, 73);
    final retained = tester
        .widgetList<RhythmChannelEditor>(find.byType(RhythmChannelEditor))
        .first
        .setting;
    expect(retained.on, isFalse);
    expect(retained.value, 73);
    _button(tester, 'Continue').onPressed!();
    await tester.pumpAndSettle();
    expect(controller.segments, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('达到 30 段时显示错误而不转场', (tester) async {
    final controller = await _open(tester, count: 30);
    _button(tester, 'Continue').onPressed!();
    await tester.pumpAndSettle();
    expect(controller.segments, hasLength(30));
    expect(find.text('Maximum 30 segments reached.'), findsOneWidget);
    expect(find.byKey(_outgoing), findsNothing);
    expect(_button(tester, 'Continue').onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final editing in [false, true]) {
    testWidgets('${editing ? '编辑' : '新增'} Confirm 保存关闭且不转场', (tester) async {
      final controller = await _open(
        tester,
        index: editing ? 0 : null,
        count: editing ? 1 : 0,
      );
      if (editing) expect(find.text('Continue'), findsNothing);
      _button(tester, 'Confirm').onPressed!();
      await tester.pump();
      expect(find.byKey(_outgoing), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(RhythmSegmentSheet), findsNothing);
      expect(controller.segments, hasLength(1));
      expect(
        RhythmStep.decode(controller.segments.single).durationSec,
        editing ? 1199 : 3,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('减少动态效果时立即切换并保持交互', (tester) async {
    final controller = await _open(tester, reduced: true);
    _button(tester, 'Continue').onPressed!();
    await tester.pump();
    expect(controller.segments, hasLength(1));
    expect(find.byKey(_outgoing), findsNothing);
    expect(find.byKey(_incoming), findsNothing);
    expect(_button(tester, 'Continue').onPressed, isNotNull);
    _button(tester, 'Continue').onPressed!();
    await tester.pumpAndSettle();
    expect(controller.segments, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  for (final fixture in [(402.0, 874.0, 1.0), (320.0, 640.0, 2.0)]) {
    testWidgets('固定玻璃操作列、底部预留和末通道可达 ${fixture.$1}/text${fixture.$3}', (
      tester,
    ) async {
      await _open(
        tester,
        size: Size(fixture.$1, fixture.$2),
        scale: fixture.$3,
      );
      final footerFinder = find.byKey(const ValueKey('segment-footer'));
      final footer = tester.getRect(footerFinder);
      final body = tester.getRect(find.byKey(const ValueKey('segment-body')));
      final scrollFinder = find.descendant(
        of: find.byType(RhythmSegmentSheet),
        matching: find.byType(SingleChildScrollView),
      );
      final scroll = tester.widget<SingleChildScrollView>(scrollFinder);
      expect(tester.getRect(scrollFinder).bottom, closeTo(body.bottom, .01));
      expect(
        (scroll.padding! as EdgeInsets).bottom,
        closeTo(footer.height, .01),
      );
      final blur = find.ancestor(
        of: footerFinder,
        matching: find.byType(BackdropFilter),
      );
      expect(
        find.ancestor(of: blur, matching: find.byType(ClipRect)),
        findsWidgets,
      );
      final continueRect = tester.getRect(find.text('Continue'));
      final confirmRect = tester.getRect(find.text('Confirm'));
      if (fixture.$3 == 2) {
        expect(confirmRect.top, greaterThan(continueRect.bottom));
      } else {
        expect(confirmRect.top, closeTo(continueRect.top, .01));
      }
      final state = tester.state<ScrollableState>(
        find
            .descendant(of: scrollFinder, matching: find.byType(Scrollable))
            .first,
      );
      state.position.jumpTo(state.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.getRect(footerFinder), footer);
      expect(
        tester.getRect(find.byType(RhythmChannelEditor).last).bottom,
        lessThanOrEqualTo(footer.top),
      );
      expect(tester.takeException(), isNull);
      await _capturePng(
        tester,
        'segment_footer_${fixture.$1.toInt()}x${fixture.$2.toInt()}_text${fixture.$3}',
      );
    });
  }
}
