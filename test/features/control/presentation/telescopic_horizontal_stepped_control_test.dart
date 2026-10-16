import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/telescopic_horizontal_stepped_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelescopicHorizontalSteppedControl', () {
    testWidgets(
      'renders title Telescopic, swap_vert icon, and right-aligned Gear indicator based on gearCurrent and gearMax',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.telescopic,
          variant: 'telescopic_mode_1x2',
          label: 'Telescopic',
          gearMax: 6,
          gearCurrent: 4,
          rows: 1,
          cols: 2,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 358,
                height: 135,
                child: TelescopicHorizontalSteppedControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证标题与双向伸缩箭头图标
        expect(find.text('Telescopic'), findsOneWidget);
        expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);

        // 验证右侧 Gear 档位指示器（包含 "Gear  4 / 6"，对齐 thrust-b.png）
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Gear  4 / 6'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('supports dynamic gearMax = 5 from backend config', (
      tester,
    ) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_mode_1x2',
        label: 'Telescopic',
        gearMax: 5,
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
              child: TelescopicHorizontalSteppedControl(config: config),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Gear  3 / 5'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'horizontal tap on capsule calculates correct gear and updates indicator',
      (tester) async {
        int? changedGear;
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.telescopic,
          variant: 'telescopic_mode_1x2',
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
                child: TelescopicHorizontalSteppedControl(
                  config: config,
                  onGearChanged: (gear) => changedGear = gear,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final capsuleFinder = find.byKey(
          const ValueKey('telescopic_horizontal_capsule_area'),
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
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_mode_1x2',
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
              child: TelescopicHorizontalSteppedControl(
                config: config,
                onGearChanged: (gear) => changedGears.add(gear),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final capsuleFinder = find.byKey(
        const ValueKey('telescopic_horizontal_capsule_area'),
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
      'FreeControlComponentPlaceholder dispatches TelescopicHorizontalSteppedControl for telescopic_mode_1x2',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.telescopic,
          variant: 'telescopic_mode_1x2',
          gearMax: 6,
          gearCurrent: 4,
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

        expect(find.byType(TelescopicHorizontalSteppedControl), findsOneWidget);
      },
    );

    testWidgets('renders with standard height 135.0 by default', (
      tester,
    ) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_mode_1x2',
        gearMax: 6,
        gearCurrent: 4,
        rows: 1,
        cols: 2,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 358,
                child: TelescopicHorizontalSteppedControl(config: config),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(
        find.byType(TelescopicHorizontalSteppedControl),
      );
      expect(size.width, 358.0);
      expect(size.height, 135.0);
    });
  });
}
