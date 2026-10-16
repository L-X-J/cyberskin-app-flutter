import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/vibration_horizontal_stepped_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VibrationHorizontalSteppedControl', () {
    testWidgets(
      'renders title, vibration icon, and right-aligned Gear indicator based on gearCurrent and gearMax',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_mode_1x2',
          label: 'Vibration',
          gearMax: 6,
          gearCurrent: 3,
          rows: 1,
          cols: 2,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 358,
                height: 135,
                child: VibrationHorizontalSteppedControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证标题与震动图标
        expect(find.text('Vibration'), findsOneWidget);
        expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);

        // 验证右侧 Gear 档位指示器（包含 "Gear  ", "3", " / ", "6"）
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Gear  3 / 6'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('supports dynamic gearMax = 4 from backend config', (
      tester,
    ) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_mode_1x2',
        label: 'Vibration',
        gearMax: 4,
        gearCurrent: 2,
        rows: 1,
        cols: 2,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 358,
              height: 135,
              child: VibrationHorizontalSteppedControl(config: config),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Gear  2 / 4'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'horizontal tap on capsule calculates correct gear and updates indicator',
      (tester) async {
        int? changedGear;
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_mode_1x2',
          gearMax: 6,
          gearCurrent: 1,
          rows: 1,
          cols: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 358,
                height: 135,
                child: VibrationHorizontalSteppedControl(
                  config: config,
                  onGearChanged: (gear) => changedGear = gear,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final capsuleFinder = find.byKey(
          const ValueKey('vibration_horizontal_capsule_area'),
        );
        expect(capsuleFinder, findsOneWidget);

        final capsuleBox = tester.getRect(capsuleFinder);
        // 点击第 5 档区域（接近右侧，约 5/6 位置）
        final targetX = capsuleBox.left + capsuleBox.width * (5.0 / 6.0 - 0.05);
        await tester.tapAt(Offset(targetX, capsuleBox.center.dy));
        await tester.pumpAndSettle();

        expect(changedGear, 5);

        // 验证顶部 Gear 文本同步更新为 5 / 6
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Gear  5 / 6'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('horizontal dragging across slots updates gear immediately', (
      tester,
    ) async {
      final changedGears = <int>[];
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_mode_1x2',
        gearMax: 6,
        gearCurrent: 1,
        rows: 1,
        cols: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 358,
              height: 135,
              child: VibrationHorizontalSteppedControl(
                config: config,
                onGearChanged: (gear) => changedGears.add(gear),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final capsuleFinder = find.byKey(
        const ValueKey('vibration_horizontal_capsule_area'),
      );
      final capsuleBox = tester.getRect(capsuleFinder);

      // 从左侧（档位 1）向右侧（档位 6）横向拖动
      final gesture = await tester.startGesture(
        Offset(capsuleBox.left + 5, capsuleBox.center.dy),
      );
      await tester.pump();

      await gesture.moveTo(Offset(capsuleBox.right - 5, capsuleBox.center.dy));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(changedGears, isNotEmpty);
      expect(changedGears.last, 6);

      // 验证顶部 Gear 文本为 6 / 6
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Gear  6 / 6'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'FreeControlComponentPlaceholder dispatches VibrationHorizontalSteppedControl for vibration_mode_1x2',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_mode_1x2',
          gearMax: 6,
          gearCurrent: 2,
          rows: 1,
          cols: 2,
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

        expect(find.byType(VibrationHorizontalSteppedControl), findsOneWidget);
      },
    );

    testWidgets('renders with standard height 135.0 by default', (
      tester,
    ) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_mode_1x2',
        gearMax: 6,
        gearCurrent: 2,
        rows: 1,
        cols: 2,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 358,
                child: VibrationHorizontalSteppedControl(config: config),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(
        find.byType(VibrationHorizontalSteppedControl),
      );
      expect(size.width, 358.0);
      expect(size.height, 135.0);
    });
  });
}
