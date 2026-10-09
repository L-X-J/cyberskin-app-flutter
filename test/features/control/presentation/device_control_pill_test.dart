import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/theme/app_device_control_style.dart';
import 'package:cyberskin_app/features/control/domain/device_quick_control.dart';
import 'package:cyberskin_app/features/control/presentation/widgets/device_control_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var fontLoaded = false;
  Future<void> render(
    WidgetTester tester,
    DeviceQuickControlState state, {
    VoidCallback? onPressed,
    bool hasSession = true,
    double textScale = 1,
    double width = 402,
  }) async {
    if (!fontLoaded) {
      await tester.runAsync(() async {
        final file = File(
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
        );
        final font = FontLoader('ControlPreview')
          ..addFont(
            Future.value(ByteData.sublistView(await file.readAsBytes())),
          );
        await font.load();
      });
      fontLoaded = true;
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'ControlPreview',
        ),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('control-capture'),
              child: ColoredBox(
                color: Colors.black,
                child: SizedBox(
                  width: width,
                  height: 200,
                  child: Center(
                    child: DeviceControlPill(
                      state: state,
                      hasSession: hasSession,
                      onPressed: onPressed ?? () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  for (final state in DeviceQuickControlState.values) {
    testWidgets(
      '$state renders glass, correct action icons and stable dimensions',
      (tester) async {
        await render(tester, state);
        expect(find.byType(LGContainer), findsOneWidget);
        final container = tester.widget<LGContainer>(find.byType(LGContainer));
        expect(container.quality, LGQuality.standard);
        expect(container.useOwnLayer, isTrue);
        final size = tester.getSize(find.byType(LGContainer));
        expect(size.width, closeTo(AppDeviceControlStyle.baseSize.width, 0.1));
        expect(
          size.height,
          closeTo(AppDeviceControlStyle.baseSize.height, 0.1),
        );
        if (state == DeviceQuickControlState.connecting) {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        } else {
          final assets = tester
              .widgetList<SvgPicture>(find.byType(SvgPicture))
              .map((svg) => (svg.bytesLoader as SvgAssetLoader).assetName);
          expect(
            assets,
            contains(switch (state) {
              DeviceQuickControlState.disconnected =>
                AppDeviceControlStyle.disconnectedAsset,
              DeviceQuickControlState.paused => AppDeviceControlStyle.playAsset,
              _ => AppDeviceControlStyle.pauseAsset,
            }),
          );
          if (state == DeviceQuickControlState.runningLowBattery) {
            expect(find.text('Low battery'), findsOneWidget);
            expect(assets, contains(AppDeviceControlStyle.batteryAsset));
          }
        }
        expect(tester.takeException(), isNull);
        if (state != DeviceQuickControlState.connecting) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('control-capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            try {
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              Directory('build/ui').createSync(recursive: true);
              await File(
                'build/ui/device_control_${state.name}_402x200_text1.0.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              final rgba = await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              // 黑色背景上玻璃填充必须产生真实像素，不能只是透明空框。
              var visible = 0;
              for (var i = 0; i < rgba!.lengthInBytes; i += 4) {
                if (rgba.getUint8(i) +
                        rgba.getUint8(i + 1) +
                        rgba.getUint8(i + 2) >
                    30) {
                  visible++;
                }
              }
              expect(visible, greaterThan(300));
            } finally {
              image.dispose();
            }
          });
        }
      },
    );
  }

  testWidgets(
    'touch, keyboard, disconnected and waiting actions share activation rules',
    (tester) async {
      var actions = 0;
      await render(
        tester,
        DeviceQuickControlState.running,
        onPressed: () => actions++,
      );
      await tester.tap(find.byType(DeviceControlPill));
      expect(actions, 1);
      final focus = tester.widget<FocusableActionDetector>(
        find.byType(FocusableActionDetector).first,
      );
      Actions.invoke(
        tester.element(find.byType(GestureDetector).last),
        const ActivateIntent(),
      );
      expect(actions, 2);
      expect(focus.enabled, isTrue);
      await render(
        tester,
        DeviceQuickControlState.connecting,
        onPressed: () => actions++,
      );
      await tester.tap(find.byType(DeviceControlPill));
      expect(actions, 2);
      await render(
        tester,
        DeviceQuickControlState.disconnected,
        onPressed: () => actions++,
      );
      await tester.tap(find.byType(DeviceControlPill));
      expect(actions, 3);
      await render(tester, DeviceQuickControlState.paused, hasSession: false);
      expect(find.text('Tap to start'), findsOneWidget);
      expect(find.text('Tap to resume'), findsNothing);
    },
  );

  for (final scale in [1.5, 2.0, 3.0]) {
    testWidgets(
      'all states fit 320px at text scale $scale without shrinking text',
      (tester) async {
        Size? previous;
        for (final state in DeviceQuickControlState.values) {
          await render(tester, state, textScale: scale, width: 320);
          final size = tester.getSize(find.byType(LGContainer));
          expect(size.width, lessThanOrEqualTo(320));
          expect(size.height, greaterThanOrEqualTo(68));
          if (previous != null) expect(size, previous);
          previous = size;
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
