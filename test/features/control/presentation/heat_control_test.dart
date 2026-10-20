import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/heat_bar_control.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/heat_toggle_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and toggles heat 1x1 control', (tester) async {
    var changed = false;
    const config = FreeControlComponentConfig(
      type: FreeControlComponentType.heat,
      variant: 'heat_toggle_1x1',
      rows: 1,
      cols: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 172,
            height: 105,
            child: HeatToggleControl(
              config: config,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heat'), findsOneWidget);
    expect(find.text('OFF'), findsOneWidget);
    await tester.tap(find.text('OFF'));
    await tester.pumpAndSettle();

    expect(changed, isTrue);
    expect(find.text('ON'), findsOneWidget);
  });

  testWidgets('placeholder dispatches heat bar control', (tester) async {
    const config = FreeControlComponentConfig(
      type: FreeControlComponentType.heat,
      variant: 'heat_bar_1x2',
      rows: 1,
      cols: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 358,
            height: 105,
            child: FreeControlComponentPlaceholder(config: config),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HeatBarControl), findsOneWidget);
    expect(find.text('Not enabled'), findsOneWidget);
    expect(find.text('OFF'), findsOneWidget);
  });
}
