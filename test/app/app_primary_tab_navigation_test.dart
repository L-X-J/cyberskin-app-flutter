import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/app/widgets/app_lg_bottom_bar.dart';
import 'package:cyberskin_app/app/widgets/app_primary_tab_navigation.dart';
import 'package:cyberskin_app/app/widgets/app_scaffold.dart';
import 'package:cyberskin_app/core/theme/app_device_control_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var fontLoaded = false;
  Future<void> render(
    WidgetTester tester, {
    AppTab selected = AppTab.home,
    ValueChanged<AppTab>? onSelected,
    double width = 402,
    double scale = 1,
    double? localWidth,
  }) async {
    if (!fontLoaded) {
      await tester.runAsync(() async {
        final file = File(
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        );
        await (FontLoader('NavigationPreview')..addFont(
              Future.value(ByteData.sublistView(await file.readAsBytes())),
            ))
            .load();
        final icons = File(
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(await icons.readAsBytes())),
            ))
            .load();
      });
      fontLoaded = true;
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'NavigationPreview',
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 200),
            textScaler: TextScaler.linear(scale),
          ),
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('navigation-capture'),
              child: SizedBox(
                width: width,
                height: 200,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF182A37), Color(0xFF38213E)],
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: localWidth,
                      child: AppPrimaryTabNavigation(
                        selectedTab: selected,
                        onSelected: onSelected ?? (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('navigation-capture')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/ui').createSync(recursive: true);
        await File('build/ui/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  testWidgets('real horizontal rows retain shared glass and 211x68 geometry', (
    tester,
  ) async {
    await render(tester);
    expect(tester.getSize(find.byType(AppLGBottomBar)), const Size(211, 68));
    final glass = tester.widget<LGContainer>(find.byType(LGContainer));
    expect(glass.quality, LGQuality.standard);
    expect(glass.useOwnLayer, isTrue);
    expect(glass.settings, AppDeviceControlStyle.glass);
    expect(find.byType(OverflowBox), findsNothing);
    for (final pair in [
      (Icons.home_outlined, 'Device'),
      (Icons.play_circle_outline, 'Video'),
    ]) {
      final icon = tester.getRect(find.byIcon(pair.$1));
      final text = tester.getRect(find.text(pair.$2));
      expect(icon.right, lessThan(text.left));
      expect(icon.center.dy, closeTo(text.center.dy, 0.1));
      expect(text.width, greaterThan(30));
    }
    expect(tester.takeException(), isNull);
    await capture(tester, 'primary_navigation_device_402x200_text1.0');
    await render(tester, selected: AppTab.video);
    await capture(tester, 'primary_navigation_video_402x200_text1.0');
  });

  testWidgets(
    'both buttons emit callbacks and external selection controls semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final calls = <AppTab>[];
      await render(tester, onSelected: calls.add);
      await tester.tap(find.text('Video'));
      await tester.tap(find.text('Device'));
      expect(calls, [AppTab.video, AppTab.home]);
      expect(
        tester
            .widget<AppLGBottomBar>(find.byType(AppLGBottomBar))
            .selectedIndex,
        0,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Device')),
        matchesSemantics(
          label: 'Device',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await render(tester, selected: AppTab.video, onSelected: calls.add);
      expect(
        tester
            .widget<AppLGBottomBar>(find.byType(AppLGBottomBar))
            .selectedIndex,
        1,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Video'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );
      expect(calls.length, 2);
      semantics.dispose();
    },
  );

  testWidgets('Tab traversal, Enter and Space activate the actual buttons', (
    tester,
  ) async {
    final calls = <AppTab>[];
    await render(tester, onSelected: calls.add);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(calls, [AppTab.home, AppTab.video]);
  });

  for (final scenario in [
    (220.0, 1.0, null),
    (320.0, 3.0, null),
    (402.0, 1.0, 140.0),
    (1024.0, 1.0, null),
  ]) {
    testWidgets(
      'fits viewport ${scenario.$1}, scale ${scenario.$2}, constraint ${scenario.$3}',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final calls = <AppTab>[];
        await render(
          tester,
          width: scenario.$1,
          scale: scenario.$2,
          localWidth: scenario.$3,
          onSelected: calls.add,
        );
        final compact =
            scenario.$1 < 224 || scenario.$2 > 1.25 || scenario.$3 != null;
        expect(find.text('Device'), compact ? findsNothing : findsOneWidget);
        expect(find.bySemanticsLabel('Device'), findsOneWidget);
        expect(find.bySemanticsLabel('Video'), findsOneWidget);
        final size = tester.getSize(find.byType(AppLGBottomBar));
        expect(
          size.width,
          lessThanOrEqualTo(
            scenario.$3 ?? AppPrimaryTabNavigation.widthFor(scenario.$1),
          ),
        );
        expect(size.height, 68);
        await tester.tap(find.byIcon(Icons.play_circle_outline));
        expect(calls, [AppTab.video]);
        expect(tester.takeException(), isNull);
        semantics.dispose();
        await capture(
          tester,
          'primary_navigation_${scenario.$3 == null ? 'viewport' : 'constrained'}_${scenario.$1.toInt()}x200_text${scenario.$2}',
        );
      },
    );
  }
}
