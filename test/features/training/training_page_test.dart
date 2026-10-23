// 训练列表到预览的路由、按钮状态与窗口约束验证。
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/theme/app_theme.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:cyberskin_app/features/control/domain/services/device_program_playback.dart';
import 'package:cyberskin_app/features/training/presentation/pages/home/training_home_controller.dart';
import 'package:cyberskin_app/features/training/presentation/pages/home/training_home_page.dart';
import 'package:cyberskin_app/features/training/presentation/pages/info/training_info_page.dart';
import 'package:cyberskin_app/features/training/presentation/training_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'training_fixtures.dart';

void main() {
  testWidgets(
    'list Hero opens preview, button states and responsive layouts remain usable',
    (tester) async {
      await tester.runAsync(() async {
        final cache = File(Platform.resolvedExecutable)
            .parent
            .parent
            .parent
            .parent;
        for (final font in {
          'Roboto': 'Roboto-Regular.ttf',
          'MaterialIcons': 'MaterialIcons-Regular.otf',
        }.entries) {
          final loader = FontLoader(font.key);
          final bytes = await File(
            '${cache.path}/artifacts/material_fonts/${font.value}',
          ).readAsBytes();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
          await loader.load();
        }
      });
      final port = Port();
      final engine = DeviceProgramPlayback(port);
      final repository = Repository();
      final session = Get.put(
        TrainingSessionController(repository, Catalog(), engine),
        permanent: true,
      );
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.put(TrainingHomeController(repository, Devices(), port));
      final boundaryKey = GlobalKey();
      var scale = 1.0;
      Widget app() => GetMaterialApp(
        theme: AppTheme.dark(),
        initialRoute: '/training',
        getPages: [
          GetPage(name: '/training', page: () => const TrainingHomePage()),
          GetPage(
            name: '/training/info/:id',
            page: () => const TrainingInfoPage(),
          ),
        ],
        builder: (context, child) => RepaintBoundary(
          key: boundaryKey,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              padding: EdgeInsets.only(
                top: tester.view.physicalSize.height >= 800 ? 62 : 24,
                bottom: 34,
              ),
              viewPadding: EdgeInsets.only(
                top: tester.view.physicalSize.height >= 800 ? 62 : 24,
                bottom: 34,
              ),
            ),
            child: child!,
          ),
        ),
      );
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui/training/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 700));
      await capture('list_402x874_text1.0');
      await tester.tap(find.text('Training 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TrainingInfoPage), findsOneWidget);
      expect(session.ready.value, isTrue);
      expect(port.commands, isEmpty);
      await capture('preview_402x874_text1.0');
      Finder button(String label) => find.byWidgetPredicate(
        (w) => w is AppLiquidGlassButton && w.label == label,
      );
      await tester.tap(button('Start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        session.phase.value,
        DeviceProgramPlaybackPhase.running,
        reason: 'error=${session.error.value}; commands=${port.commands}',
      );
      expect(button('Stop'), findsOneWidget);
      await tester.tap(button('Stop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(button('Restart'), findsOneWidget);
      for (final size in [const Size(320, 640), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        scale = 2;
        await tester.pumpWidget(app());
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        expect(button('Restart'), findsOneWidget);
        await capture(
          'detail_${size.width.toInt()}x${size.height.toInt()}_text2.0',
        );
      }
      Get.back<void>();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TrainingHomePage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      session.onClose();
      Get.reset();
      // 取消方法在第一个 await 之前即释放周期计时器；测试框架负责排空微任务。
      unawaited(engine.dispose());
      unawaited(port.controller.close());
      await tester.pump();
    },
  );
}
