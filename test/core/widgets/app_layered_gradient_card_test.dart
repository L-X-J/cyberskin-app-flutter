import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/widgets/app_layered_gradient_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [146.0, 170.0, 240.0]) {
    testWidgets('surface fits width $width with enlarged text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Center(
              child: SizedBox(
                width: width,
                child: const AppLayeredGradientCard(
                  baseColor: Color(0xFFD94126),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('A longer model name'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(AppLayeredGradientCard)).width, width);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('content sizes the card in an unbounded scroll view', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: const [
            AppLayeredGradientCard(
              baseColor: Colors.red,
              child: SizedBox(height: 90, child: Text('Model')),
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppLayeredGradientCard)).height, 90);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radial layer darkens the top and leaves foreground sharp', (
    tester,
  ) async {
    final pixels = await _render(
      tester,
      const AppLayeredGradientCard(
        baseColor: Color(0xFFD94126),
        height: 170,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
    expect(_channel(pixels, 85, 25), lessThan(_channel(pixels, 85, 140)));
    expect(_channel(pixels, 85, 85), 255);
    expect(_channel(pixels, 74, 85), lessThan(255));
    // 圆角外部仍是背景；模糊不泄漏到卡片外。
    expect(_channel(pixels, 0, 0), 0);
    await _render(
      tester,
      const AppLayeredGradientCard(
        baseColor: Color(0xFFD94126),
        height: 170,
        child: SizedBox.shrink(),
      ),
      output: 'layered_gradient_card_red_170x170_text1.0',
    );
  });

  testWidgets('opaque top layer covers base and inner shadow', (tester) async {
    final pixels = await _render(
      tester,
      const AppLayeredGradientCard(
        baseColor: Colors.blue,
        topGradientColors: [Colors.green, Colors.green],
        topLayerBlur: 0,
        innerShadowColor: Colors.red,
        height: 170,
        child: SizedBox.shrink(),
      ),
    );
    expect(_channel(pixels, 85, 85), 76);
    expect(_channel(pixels, 85, 85, 1), 175);
    expect(_channel(pixels, 85, 85, 2), 80);
  });

  testWidgets('blur softens the gradient layer and exposes the inset edge', (
    tester,
  ) async {
    const colors = [Colors.black, Colors.white];
    final sharp = await _render(
      tester,
      const AppLayeredGradientCard(
        baseColor: Colors.red,
        topGradientColors: colors,
        topGradientStops: [0.49, 0.5],
        topLayerBlur: 0,
        height: 170,
        child: SizedBox.shrink(),
      ),
    );
    final blurred = await _render(
      tester,
      const AppLayeredGradientCard(
        baseColor: Colors.red,
        topGradientColors: colors,
        topGradientStops: [0.49, 0.5],
        height: 170,
        child: SizedBox.shrink(),
      ),
    );
    // 阶跃渐变附近出现中间色，证明滤镜模糊的是渐变自身。
    expect(
      _channel(blurred, 85, 80, 1),
      greaterThan(_channel(sharp, 85, 80, 1)),
    );
    expect(_channel(blurred, 85, 90, 1), lessThan(_channel(sharp, 85, 90, 1)));
    expect(
      _channel(blurred, 85, 165, 1),
      lessThan(_channel(sharp, 85, 165, 1)),
    );
  });

  testWidgets('inner shadow is inset and respects vertical offset', (
    tester,
  ) async {
    final pixels = await _render(
      tester,
      const AppLayeredGradientCard(
        baseColor: Colors.black,
        topGradientColors: [Colors.transparent, Colors.transparent],
        innerShadowColor: Colors.white,
        innerShadowOffset: Offset(0, 8),
        height: 170,
        child: SizedBox.shrink(),
      ),
    );
    expect(_channel(pixels, 85, 4), greaterThan(_channel(pixels, 85, 165)));
    expect(_channel(pixels, 85, 4), greaterThan(_channel(pixels, 85, 85)));
    expect(_channel(pixels, 0, 0), 0);
  });
}

int _channel(ByteData pixels, int x, int y, [int channel = 0]) =>
    pixels.getUint8((y * 170 + x) * 4 + channel);

Future<ByteData> _render(
  WidgetTester tester,
  Widget card, {
  String? output,
}) async {
  const key = ValueKey('card-capture');
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.black,
            child: SizedBox(width: 170, child: card),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      if (output != null) {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/ui').createSync(recursive: true);
        File('build/ui/$output.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }
      return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    } finally {
      image.dispose();
    }
  }))!;
}
