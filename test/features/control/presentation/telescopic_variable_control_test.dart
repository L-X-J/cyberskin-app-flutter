import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/telescopic_variable_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelescopicVariableControl', () {
    testWidgets('renders the thrust-c baseline', (tester) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_variable_3x1',
        rows: 3,
        cols: 1,
        variableSpeedSupported: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 355,
              child: TelescopicVariableControl(config: config),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Telescopic'), findsOneWidget);
      expect(find.text('Variable Speed'), findsOneWidget);
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('dispatches telescopic variable variants', (tester) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_variable_3x1',
        rows: 3,
        cols: 1,
        variableSpeedSupported: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 355,
              child: FreeControlComponentPlaceholder(config: config),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TelescopicVariableControl), findsOneWidget);
      expect(find.text('82%'), findsOneWidget);
    });

    testWidgets('maps a vertical tap to a percentage', (tester) async {
      int? changed;
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_variable_3x1',
        rows: 3,
        cols: 1,
        variableSpeedSupported: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 355,
              child: TelescopicVariableControl(
                config: config,
                onSpeedChanged: (value) => changed = value,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final capsule = tester.getRect(
        find.byKey(const ValueKey('telescopic_variable_capsule_area')),
      );
      await tester.tapAt(Offset(capsule.center.dx, capsule.center.dy));
      await tester.pumpAndSettle();

      expect(changed, 50);
      expect(find.text('50%'), findsOneWidget);
    });
  });
}
