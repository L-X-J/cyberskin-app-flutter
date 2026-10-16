import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/theme/app_effects.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('highlighted surface omits the unsupported top inner highlight', () {
    const button = AppLiquidGlassButton(label: 'Continue', onPressed: null);

    expect(button.innerShadows, hasLength(1));
    expect(
      button.innerShadows.single,
      same(AppEffects.liquidGlassButtonInnerGlow),
    );
  });

  testWidgets('supports a leading icon without changing the text button mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppLiquidGlassButton(
          label: '67%',
          leadingIcon: Icons.battery_full_outlined,
          onPressed: () {},
          variant: AppLiquidGlassButtonVariant.translucent,
          height: 32,
          textStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );

    expect(find.byIcon(Icons.battery_full_outlined), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
  });

  testWidgets('custom content retains the translucent glass surface contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppLiquidGlassButton(
          label: 'Profile',
          onPressed: () {},
          variant: AppLiquidGlassButtonVariant.translucent,
          width: 50,
          height: 50,
          borderRadius: 25,
          child: const Icon(Icons.person_outline),
        ),
      ),
    );

    final button = tester.widget<AppLiquidGlassButton>(
      find.byType(AppLiquidGlassButton),
    );
    final glassButton = tester.widget<LGButton>(find.byType(LGButton));
    expect(button.fillColor, const Color(0x1FFFFFFF));
    expect(button.innerShadows, isEmpty);
    expect(glassButton.style, LGButtonStyle.filled);
    expect(glassButton.settings?.glassColor, Colors.transparent);
    expect(glassButton.settings?.lightIntensity, greaterThan(0));
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.bySemanticsLabel('Profile'), findsOneWidget);
  });

  testWidgets('translucent compact actions retain design geometry', (
    tester,
  ) async {
    var activations = 0;
    const captureKey = ValueKey('compact-glass-actions-capture');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: captureKey,
            child: ColoredBox(
              color: const Color(0xFF733691),
              child: SizedBox(
                width: 176,
                height: 80,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLiquidGlassButton(
                        label: 'Bluetooth scan',
                        icon: Icons.bluetooth,
                        onPressed: () => activations++,
                        variant: AppLiquidGlassButtonVariant.translucent,
                        width: 40,
                        height: 40,
                        borderRadius: 12,
                        iconSize: 16,
                      ),
                      const SizedBox(width: 8),
                      AppLiquidGlassButton(
                        label: 'Stop',
                        onPressed: () => activations++,
                        variant: AppLiquidGlassButtonVariant.translucent,
                        width: 104,
                        height: 40,
                        borderRadius: 12,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final buttons = find.byType(AppLiquidGlassButton);
    expect(buttons, findsNWidgets(2));
    expect(tester.getSize(buttons.at(0)), const Size(40, 40));
    expect(tester.getSize(buttons.at(1)), const Size(104, 40));
    expect(
      tester.widget<AppLiquidGlassButton>(buttons.at(0)).fillColor,
      const Color(0x1FFFFFFF),
    );
    await tester.tap(find.byType(LGButton).first);
    await tester.tap(find.byType(LGButton).last);
    expect(activations, 2);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = Directory('build/ui')..createSync(recursive: true);
        File('${output.path}/home_compact_glass_actions_176x80.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  });

  testWidgets('translucent background tint stays visible on black', (
    tester,
  ) async {
    const captureKey = ValueKey('translucent-glass-black-capture');
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: captureKey,
            child: ColoredBox(
              color: Colors.black,
              child: SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: AppLiquidGlassButton(
                    label: 'Action',
                    onPressed: () {},
                    variant: AppLiquidGlassButtonVariant.translucent,
                    width: 40,
                    height: 40,
                    borderRadius: 12,
                    icon: Icons.stop,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    final pixels = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = Directory('build/ui')..createSync(recursive: true);
        File('${output.path}/liquid_glass_translucent_black_80x80.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
        return rgba;
      } finally {
        image.dispose();
      }
    });
    int redAt(int x, int y) => pixels!.getUint8((y * 80 + x) * 4);
    expect(redAt(40, 40), inInclusiveRange(20, 40));
    expect(redAt(20, 40), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  for (final variant in AppLiquidGlassButtonVariant.values) {
    testWidgets(
      '$variant supports touch and keyboard and blocks loading activation',
      (tester) async {
        var activated = 0;
        Future<void> render({bool loading = false}) => tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 353,
                child: AppLiquidGlassButton(
                  label: 'Continue',
                  variant: variant,
                  isLoading: loading,
                  onPressed: () => activated++,
                ),
              ),
            ),
          ),
        );
        await render();
        final button = tester.widget<LGButton>(find.byType(LGButton));
        expect(button.useOwnLayer, isTrue);
        expect(button.quality, LGQuality.standard);
        expect(button.style, LGButtonStyle.filled);
        expect(button.settings?.glassColor, Colors.transparent);
        expect(button.settings?.thickness, 30);
        expect(button.settings?.lightIntensity, 0.65);
        await tester.tap(find.byType(LGButton));
        expect(activated, 1);
        Focus.of(tester.element(find.byType(LGButton))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(activated, 2);
        await render(loading: true);
        await tester.tap(find.byType(LGButton));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(activated, 2);
        expect(
          tester.getSize(find.byType(AppLiquidGlassButton)),
          const Size(353, 58),
        );
      },
    );
  }

  testWidgets('auto-fits content width and clamps to maxWidth', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Column(
            children: [
              AppLiquidGlassButton(
                label: 'Short',
                leadingIcon: Icons.star,
                onPressed: () {},
                maxWidth: 200,
                height: 32,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(fontSize: 12),
              ),
              AppLiquidGlassButton(
                label: 'A very long label that exceeds the specified maximum width limit',
                leadingIcon: Icons.star,
                onPressed: () {},
                maxWidth: 200,
                height: 32,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    final buttons = find.byType(AppLiquidGlassButton);
    final shortWidth = tester.getSize(buttons.first).width;
    final longWidth = tester.getSize(buttons.last).width;

    expect(shortWidth, lessThan(200));
    expect(longWidth, equals(200));
  });
}
