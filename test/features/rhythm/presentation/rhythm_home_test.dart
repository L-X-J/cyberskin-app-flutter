// 节奏列表动画纯内存回归，不连接 BLE/API。
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:cyberskin_app/core/widgets/app_lottie_background.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_repository.dart';
import 'package:cyberskin_app/features/rhythm/domain/services/rhythm_playback.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/home/rhythm_home_controller.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/home/rhythm_home_page.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/home/widgets/rhythm_list_entrance.dart';
import 'package:cyberskin_app/features/rhythm/presentation/rhythm_session_controller.dart';
import 'package:cyberskin_app/features/rhythm/presentation/widgets/rhythm_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'rhythm_info_test.dart' as fixtures;

// 背景保留真实组件，用空动画隔离 Lottie 无限播放和素材解码；不验证素材本身。
class _Assets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('init_bg.json')) {
      return ByteData.sublistView(
        Uint8List.fromList(
          utf8.encode(
            '{"v":"5.7.4","fr":30,"ip":0,"op":30,"w":402,"h":874,"layers":[]}',
          ),
        ),
      );
    }
    return rootBundle.load(key);
  }
}

class _Repository implements RhythmRepository {
  int loads = 0;
  @override
  Future<Result<List<Rhythm>>> list({int? deviceModelId}) async {
    loads++;
    return Result.ok(
      List.generate(
        20,
        (i) =>
            Rhythm(id: i, name: 'Rhythm $i', deviceModelName: 'Fixture device'),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late fixtures.Port port;
  late RhythmPlayback playback;
  late RhythmHomeController controller;
  late _Repository repository;
  final boundaryKey = GlobalKey();
  setUp(() {
    Get.testMode = true;
    port = fixtures.Port();
    playback = RhythmPlayback(port);
    Get.put(RhythmSessionController(playback, fixtures.Catalog()));
    repository = _Repository();
    controller = Get.put(RhythmHomeController(repository));
  });
  tearDown(() async {
    await playback.dispose();
    await port.eventsController.close();
    Get.reset();
  });
  Future<void> show(
    WidgetTester tester, {
    double scale = 1,
    bool reduced = false,
    EdgeInsets padding = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: tester.view.physicalSize,
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduced,
            padding: padding,
          ),
          child: DefaultAssetBundle(
            bundle: _Assets(),
            child: RepaintBoundary(
              key: boundaryKey,
              child: const RhythmHomePage(),
            ),
          ),
        ),
      ),
    );
  }

  // Lottie 背景持续播放，使用有限帧推进交互动画，不等待装饰动画停止。
  Future<void> finishAnimations(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Finder fade() => find
      .descendant(
        of: find.byType(RhythmListEntrance).first,
        matching: find.byType(FadeTransition),
      )
      .first;
  Future<void> snapshot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/ui/rhythm/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('入场中间态/终态、刷新、折叠恢复和滚动不重播', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester);
    await tester.pump();
    expect(tester.widget<FadeTransition>(fade()).opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<FadeTransition>(fade()).opacity.value,
      inExclusiveRange(0, 1),
    );
    await snapshot(tester, 'home_entrance_mid_402x874_text1.0');
    await finishAnimations(tester);
    expect(tester.widget<FadeTransition>(fade()).opacity.value, 1);
    await snapshot(tester, 'home_expanded_402x874_text1.0');
    final scroll = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    scroll.jumpTo(240);
    await finishAnimations(tester);
    expect(
      tester.widget<RhythmTitle>(find.byType(RhythmTitle)).style.fontSize,
      18,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('rhythm-subtitle-opacity')),
          )
          .opacity,
      0,
    );
    await snapshot(tester, 'home_collapsed_402x874_text1.0');
    await controller.refreshList();
    await finishAnimations(tester);
    expect(scroll.offset, 240);
    scroll.jumpTo(1200);
    await finishAnimations(tester);
    scroll.jumpTo(0);
    await tester.pump();
    expect(tester.widget<FadeTransition>(fade()).opacity.value, 1);
    expect(
      tester.widget<RhythmTitle>(find.byType(RhythmTitle)).style.fontSize,
      28,
    );
    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await finishAnimations(tester);
    expect(repository.loads, greaterThanOrEqualTo(3));
    expect(port.commands, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('大字体窄屏、在途减少动画立即终态', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, scale: 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await show(tester, scale: 2, reduced: true);
    await tester.pump();
    expect(tester.widget<FadeTransition>(fade()).opacity.value, 1);
    expect(
      tester
          .widget<HeroMode>(
            find
                .ancestor(
                  of: find.byType(Hero),
                  matching: find.byType(HeroMode),
                )
                .first,
          )
          .enabled,
      isFalse,
    );
    await snapshot(tester, 'home_expanded_320x640_text2.0');
    tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!
        .jumpTo(320);
    await finishAnimations(tester);
    await snapshot(tester, 'home_collapsed_320x640_text2.0');
    expect(tester.takeException(), isNull);
    expect(port.commands, isEmpty);
  });
  for (final scenario in [
    (size: const Size(402, 874), scale: 1.0),
    (size: const Size(1024, 768), scale: 1.0),
    (size: const Size(320, 640), scale: 2.0),
  ]) {
    testWidgets('全宽顶部磨砂、安全区和按钮下余量 ${scenario.size}', (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const padding = EdgeInsets.fromLTRB(10, 47, 10, 24);
      await show(tester, scale: scenario.scale, padding: padding);
      await finishAnimations(tester);
      final frost = find.byKey(const ValueKey('rhythm-header-frost'));
      expect(frost, findsNothing);
      expect(find.byType(AppLottieBackground), findsOneWidget);
      final scroll = tester
          .widget<CustomScrollView>(find.byType(CustomScrollView))
          .controller!;
      scroll.jumpTo(500);
      await finishAnimations(tester);
      final rect = tester.getRect(frost);
      final back = find.byWidgetPredicate(
        (widget) => widget is AppLiquidGlassButton && widget.label == 'Back',
      );
      final button = tester.getRect(back);
      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.width, scenario.size.width);
      expect(button.top, greaterThanOrEqualTo(padding.top));
      expect(rect.bottom - button.bottom, greaterThanOrEqualTo(16));
      expect(back.hitTestable(), findsOneWidget);
      final viewport = tester.getRect(find.byType(CustomScrollView));
      final expectedWidth =
          (scenario.size.width - padding.horizontal).clamp(0, 600) - 44;
      expect(viewport.width, expectedWidth);
      expect(button.left, viewport.left);
      // 磨砂是标题的后绘制兄弟，而不是标题的祖先，标题不会被二次模糊。
      expect(
        find.ancestor(of: back, matching: find.byType(BackdropFilter)),
        findsNothing,
      );
      expect(
        find.descendant(of: frost, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
      await snapshot(
        tester,
        'home_frost_${scenario.size.width.toInt()}x${scenario.size.height.toInt()}_text${scenario.scale}',
      );
      expect(tester.takeException(), isNull);
      expect(port.commands, isEmpty);
    });
  }

  testWidgets('Hero 标签连接并完成往返飞行', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(
          body: RhythmTitle(compact: true, style: TextStyle(fontSize: 16)),
        ),
      ),
    );
    expect(tester.widget<Hero>(find.byType(Hero)).tag, RhythmTitle.heroTag);
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: RhythmTitle(style: TextStyle(fontSize: 28))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    await finishAnimations(tester);
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    await finishAnimations(tester);
    expect(find.text('Custom\nrhythm'), findsOneWidget);
  });
}
