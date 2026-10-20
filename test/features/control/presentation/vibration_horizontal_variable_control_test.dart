import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/vibration_horizontal_variable_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VibrationHorizontalVariableControl', () {
    testWidgets(
      'renders title, vibration icon, subtitle, and Gear 62 % indicator by default (matching vibration-d.png)',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_1x2',
          label: 'Vibration',
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
                child: VibrationHorizontalVariableControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证标题、副标题与震动图标
        expect(find.text('Vibration'), findsOneWidget);
        expect(find.text('Variable Speed'), findsOneWidget);
        expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);

        // 验证右侧默认展示 Gear 62 %（对齐 vibration-d.png 设计图基准）
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Gear  62 %'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('supports dynamic initialPercentage and updates indicator', (
      tester,
    ) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_variable_1x2',
        label: 'Vibration',
        rows: 1,
        cols: 2,
        gearCurrent: 85,
        variableSpeedSupported: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 358,
              height: 135,
              child: VibrationHorizontalVariableControl(
                config: config,
                initialPercentage: 85,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Gear  85 %'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'horizontal tap on capsule calculates correct percentage and updates indicator',
      (tester) async {
        int? changedPercent;
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_1x2',
          rows: 1,
          cols: 2,
          variableSpeedSupported: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 358,
                height: 135,
                child: VibrationHorizontalVariableControl(
                  config: config,
                  initialPercentage: 10,
                  onGearChanged: (val) => changedPercent = val,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 寻找胶囊手势区域
        final capsuleFinder = find.byKey(
          const ValueKey('vibration_variable_capsule_area'),
        );
        expect(capsuleFinder, findsOneWidget);

        final capsuleRect = tester.getRect(capsuleFinder);

        // 点击 50% 处
        await tester.tapAt(
          Offset(
            capsuleRect.left + capsuleRect.width * 0.5,
            capsuleRect.center.dy,
          ),
        );
        await tester.pumpAndSettle();

        expect(changedPercent, equals(50));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Gear  50 %'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'horizontal dragging updates percentage immediately and invokes callback',
      (tester) async {
        final percentValues = <int>[];
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_1x2',
          rows: 1,
          cols: 2,
          variableSpeedSupported: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 358,
                height: 135,
                child: VibrationHorizontalVariableControl(
                  config: config,
                  initialPercentage: 20,
                  onSpeedChanged: (val) => percentValues.add(val),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final capsuleFinder = find.byKey(
          const ValueKey('vibration_variable_capsule_area'),
        );
        final capsuleRect = tester.getRect(capsuleFinder);

        // 从 20% 位置拖拽至 75%
        final startOffset = Offset(
          capsuleRect.left + capsuleRect.width * 0.20,
          capsuleRect.center.dy,
        );
        final gesture = await tester.startGesture(startOffset);
        await tester.pump();

        // 拖动至 40%
        await gesture.moveTo(
          Offset(
            capsuleRect.left + capsuleRect.width * 0.40,
            capsuleRect.center.dy,
          ),
        );
        await tester.pump();

        // 拖动至 75%
        await gesture.moveTo(
          Offset(
            capsuleRect.left + capsuleRect.width * 0.75,
            capsuleRect.center.dy,
          ),
        );
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(percentValues, contains(40));
        expect(percentValues, contains(75));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Gear  75 %'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'FreeControlComponentPlaceholder dispatches VibrationHorizontalVariableControl for vibration_variable_1x2',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_1x2',
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
                child: FreeControlComponentPlaceholder(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(VibrationHorizontalVariableControl), findsOneWidget);
        expect(find.text('Variable Speed'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Gear  62 %'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('handles boundary values 0% and 100%', (tester) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_variable_1x2',
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
              child: VibrationHorizontalVariableControl(
                config: config,
                initialPercentage: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Gear  0 %'),
        ),
        findsOneWidget,
      );

      // 更新为 100%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 358,
              height: 135,
              child: VibrationHorizontalVariableControl(
                config: config,
                initialPercentage: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Gear  100 %'),
        ),
        findsOneWidget,
      );
    });
  });
}
