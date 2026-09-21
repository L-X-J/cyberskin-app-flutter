import 'package:cyberskin_app/app/cyberskin_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on the device route and navigates to video', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CyberskinApp());
    await tester.pumpAndSettle();

    expect(find.text('My Devices'), findsOneWidget);
    expect(find.text('No devices yet'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);

    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();

    expect(find.text('Video experiences'), findsOneWidget);
    expect(
      find.text(
        'Official, browser, and local video sources will be configured here.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Device'));
    await tester.pumpAndSettle();

    expect(find.text('My Devices'), findsOneWidget);
    expect(find.text('No devices yet'), findsOneWidget);
  });
}
