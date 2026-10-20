import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/suck_multi_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows configured modes only while suck is enabled', (
    tester,
  ) async {
    var enabled = true;
    String? selectedMode;
    const config = FreeControlComponentConfig(
      type: FreeControlComponentType.suck,
      variant: 'suck_multi_2x2',
      rows: 2,
      cols: 2,
      modes: ['Easy Mode', 'Quick Mode', 'one', 'two', 'three'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 358,
            height: 231,
            child: SuckMultiControl(
              config: config,
              height: 231,
              onChanged: (value) => enabled = value,
              onModeChanged: (value) => selectedMode = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Easy Mode'), findsOneWidget);
    expect(find.text('Quick Mode'), findsOneWidget);
    await tester.tap(find.text('Quick Mode'));
    expect(selectedMode, 'Quick Mode');

    await tester.tap(find.text('ON'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(enabled, isFalse);
    expect(find.text('Easy Mode'), findsNothing);
    expect(find.text('Quick Mode'), findsNothing);
  });

  testWidgets('placeholder dispatches suck multi control', (tester) async {
    const config = FreeControlComponentConfig(
      type: FreeControlComponentType.suck,
      variant: 'suck_multi_2x2',
      rows: 2,
      cols: 2,
      modes: ['Easy Mode'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 358,
            height: 231,
            child: FreeControlComponentPlaceholder(config: config),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SuckMultiControl), findsOneWidget);
  });
}
