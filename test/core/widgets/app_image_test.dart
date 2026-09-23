import 'package:cyberskin_app/core/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows placeholder for an empty URL', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppImage.load(null, placeholder: const Text('No image')),
      ),
    );

    expect(find.text('No image'), findsOneWidget);
  });

  testWidgets('forwards tap callbacks for image placeholders', (tester) async {
    var tapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AppImage.load(
          '',
          placeholder: const ColoredBox(
            key: ValueKey<String>('placeholder'),
            color: Colors.transparent,
            child: SizedBox(width: 20, height: 20),
          ),
          onTap: () => tapCount++,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('placeholder')));
    expect(tapCount, 1);
  });

  testWidgets('does not open an empty gallery', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                AppImage.showGallery(context, urls: const <String>[]),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });
}
