import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/app/widgets/app_flower_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a sized decorative flower that rotates continuously', (
    tester,
  ) async {
    const captureKey = ValueKey('flower-loading-capture');
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: captureKey,
            child: ColoredBox(
              color: Colors.black,
              child: AppFlowerLoadingIndicator(
                size: 54,
                color: Color(0xFFFFB8F6),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final indicator = find.byType(AppFlowerLoadingIndicator);
    final rotation = find.byType(RotationTransition);
    final configuration = tester.widget<AppFlowerLoadingIndicator>(indicator);
    expect(tester.getSize(indicator), const Size.square(54));
    expect(configuration.size, 54);
    expect(configuration.color, const Color(0xFFFFB8F6));
    expect(rotation, findsOneWidget);
    expect(
      find.descendant(
        of: indicator,
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: indicator, matching: find.byType(ExcludeSemantics)),
      findsOneWidget,
    );

    final initialTurns = tester
        .widget<RotationTransition>(rotation)
        .turns
        .value;
    await tester.pump(const Duration(milliseconds: 300));
    final activeTurns = tester.widget<RotationTransition>(rotation).turns.value;
    expect(activeTurns, isNot(initialTurns));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = Directory('build/ui')..createSync(recursive: true);
        File('${output.path}/app_flower_loading_indicator_54x54.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });

    expect(tester.takeException(), isNull);
  });
}
