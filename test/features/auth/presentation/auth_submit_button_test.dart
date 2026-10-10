import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:cyberskin_app/features/auth/presentation/auth_submit_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'disables submission while loading and exposes loading semantics',
    (tester) async {
      var submitted = 0;
      Future<void> render({required bool loading}) => tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 353,
              child: AuthSubmitButton(
                label: 'Next',
                isLoading: loading,
                onPressed: () => submitted++,
              ),
            ),
          ),
        ),
      );
      await render(loading: false);
      await tester.tap(find.byType(LGButton));
      expect(submitted, 1);
      await render(loading: true);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byType(LGButton));
      expect(submitted, 1);
      expect(find.bySemanticsLabel('Next, loading'), findsOneWidget);
      expect(tester.getSize(find.byType(LGButton)), const Size(58, 58));
      expect(find.text('Next'), findsNothing);
      await render(loading: false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(find.byType(LGButton)), const Size(353, 58));
    },
  );

  for (final variant in AppLiquidGlassButtonVariant.values) {
    testWidgets(
      '$variant renders translucent fill and keeps shadows inside the pill',
      (tester) async {
        // FVM 环境下使用 SDK 自带字体生成可读预览；其他环境仍可验证像素和裁切。
        await tester.runAsync(() async {
          final font = File(
            '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
          );
          if (font.existsSync()) {
            final loader = FontLoader('AuthButtonPreview')
              ..addFont(
                Future.value(ByteData.sublistView(await font.readAsBytes())),
              );
            await loader.load();
          }
        });
        const captureKey = ValueKey('submit-button-capture');
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'AuthButtonPreview'),
            home: Center(
              child: RepaintBoundary(
                key: captureKey,
                child: ColoredBox(
                  color: Colors.black,
                  child: SizedBox(
                    width: 393,
                    height: 98,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: variant == AppLiquidGlassButtonVariant.highlighted
                          ? AuthSubmitButton(
                              label: 'Next',
                              isLoading: false,
                              onPressed: () {},
                            )
                          : AppLiquidGlassButton(
                              label: 'Continue',
                              variant: variant,
                              onPressed: () {},
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
        // toImage 使用真实 raster 异步任务，必须离开 Widget test 的假时间域。
        final pixels = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final rgba = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final output = Directory('build/ui')..createSync(recursive: true);
            final name = variant == AppLiquidGlassButtonVariant.highlighted
                ? 'auth_submit_button_353x58'
                : 'liquid_glass_button_subtle_353x58';
            File('${output.path}/$name.png')
                .writeAsBytesSync(png!.buffer.asUint8List());
            return rgba;
          } finally {
            image.dispose();
          }
        });
        int redAt(int x, int y) => pixels!.getUint8((y * 393 + x) * 4);
        expect(redAt(10, 49), 0);
        expect(redAt(382, 49), 0);
        expect(redAt(196, 10), 0);
        expect(redAt(196, 87), 0);
        expect(redAt(21, 21), 0);
        // 中央保留背景透出；设计未提供白色上缘内高光。
        if (variant == AppLiquidGlassButtonVariant.highlighted) {
          expect(redAt(100, 49), inInclusiveRange(41, 90));
          expect(redAt(100, 23), lessThanOrEqualTo(redAt(100, 74) + 2));
        } else if (variant == AppLiquidGlassButtonVariant.subtle) {
          expect(redAt(100, 49), inInclusiveRange(24, 60));
          int blueAt(int x, int y) => pixels!.getUint8((y * 393 + x) * 4 + 2);
          expect(blueAt(100, 23), greaterThan(blueAt(100, 49)));
        }
      },
    );
  }
}
