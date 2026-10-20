import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/telescopic_horizontal_variable_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders thrust-d and dispatches horizontal interaction', (
    tester,
  ) async {
    const config = FreeControlComponentConfig(
      type: FreeControlComponentType.telescopic,
      variant: 'telescopic_variable_1x2',
      rows: 1,
      cols: 2,
      variableSpeedSupported: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 358,
            height: 135,
            child: FreeControlComponentPlaceholder(config: config, height: 135),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TelescopicHorizontalVariableControl), findsOneWidget);
    expect(find.text('Telescopic'), findsOneWidget);
    expect(find.text('Variable Speed'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Gear  22 %'),
      ),
      findsOneWidget,
    );

    final capsule = tester.getRect(
      find.byKey(const ValueKey('telescopic_variable_capsule_area')),
    );
    await tester.tapAt(
      Offset(capsule.left + capsule.width * 0.5, capsule.center.dy),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Gear  50 %'),
      ),
      findsOneWidget,
    );
  });
}
