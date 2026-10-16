import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/vibration_stepped_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VibrationSteppedControl', () {
    testWidgets(
      'renders title, vibration icon, and dynamic gear labels based on gearMax',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_mode_3x1',
          label: 'Vibration',
          gearMax: 6,
          gearCurrent: 3,
          rows: 3,
          cols: 1,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 172,
                height: 312,
                child: VibrationSteppedControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证标题与震动图标
        expect(find.text('Vibration'), findsOneWidget);
        expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);

        // 验证动态生成的 1 ~ 6 档位数字全部存在
        for (var i = 1; i <= 6; i++) {
          expect(find.text('$i'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'supports dynamic gearMax = 4 from backend config (Option A sample)',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_mode_3x1',
          label: 'Vibration',
          gearMax: 4,
          gearCurrent: 1,
          rows: 3,
          cols: 1,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 172,
                height: 312,
                child: VibrationSteppedControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (var i = 1; i <= 4; i++) {
          expect(find.text('$i'), findsOneWidget);
        }
        expect(find.text('5'), findsNothing);
        expect(find.text('6'), findsNothing);
      },
    );

    testWidgets(
      'tapping gear number updates active gear and triggers onGearChanged',
      (tester) async {
        int? changedGear;
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_mode_3x1',
          gearMax: 6,
          gearCurrent: 1,
          rows: 3,
          cols: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 172,
                height: 312,
                child: VibrationSteppedControl(
                  config: config,
                  onGearChanged: (gear) => changedGear = gear,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 点击数字 5
        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();

        expect(changedGear, 5);
      },
    );

    testWidgets('tapping on capsule area calculates correct gear', (
      tester,
    ) async {
      int? changedGear;
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_mode_3x1',
        gearMax: 6,
        gearCurrent: 1,
        rows: 3,
        cols: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 312,
              child: VibrationSteppedControl(
                config: config,
                onGearChanged: (gear) => changedGear = gear,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final capsuleFinder = find.byKey(
        const ValueKey('vibration_capsule_area'),
      );
      expect(capsuleFinder, findsOneWidget);

      final capsuleBox = tester.getRect(capsuleFinder);
      await tester.tapAt(Offset(capsuleBox.center.dx, capsuleBox.top + 10));
      await tester.pumpAndSettle();

      expect(changedGear, 6);
    });

    testWidgets('dragging across slots updates gear immediately', (
      tester,
    ) async {
      final changedGears = <int>[];
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_mode_3x1',
        gearMax: 6,
        gearCurrent: 1,
        rows: 3,
        cols: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 312,
              child: VibrationSteppedControl(
                config: config,
                onGearChanged: (gear) => changedGears.add(gear),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final capsuleFinder = find.byKey(
        const ValueKey('vibration_capsule_area'),
      );
      final capsuleBox = tester.getRect(capsuleFinder);

      // 从底部（档位 1）向上滑动到顶部（档位 6）
      final gesture = await tester.startGesture(
        Offset(capsuleBox.center.dx, capsuleBox.bottom - 10),
      );
      await tester.pump();

      await gesture.moveTo(Offset(capsuleBox.center.dx, capsuleBox.top + 10));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(changedGears, isNotEmpty);
      expect(changedGears.last, 6);
    });
  });
}
