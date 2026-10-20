import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/suck_toggle_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and toggles suck 1x1 control', (tester) async {
    var changed = true;
    const config = FreeControlComponentConfig(
      type: FreeControlComponentType.suck,
      variant: 'suck_toggle_1x1',
      rows: 1,
      cols: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 172,
            height: 105,
            child: SuckToggleControl(
              config: config,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suck'), findsOneWidget);
    expect(find.text('ON'), findsOneWidget);
    await tester.tap(find.text('ON'));
    await tester.pumpAndSettle();

    expect(changed, isFalse);
    expect(find.text('OFF'), findsOneWidget);
  });

  testWidgets('placeholder dispatches suck toggle control', (tester) async {
    const config = FreeControlComponentConfig(
      type: FreeControlComponentType.suck,
      variant: 'suck_toggle_1x1',
      rows: 1,
      cols: 1,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 172,
            height: 105,
            child: FreeControlComponentPlaceholder(config: config),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SuckToggleControl), findsOneWidget);
  });
}
