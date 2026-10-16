import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/telescopic_stepped_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelescopicSteppedControl', () {
    testWidgets(
      'renders title, icon, and dynamic gear labels based on gearMax',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.telescopic,
          variant: 'telescopic_mode_3x1',
          label: 'Telescopic',
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
                child: TelescopicSteppedControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证标题与图标
        expect(find.text('Telescopic'), findsOneWidget);
        expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);

        // 验证动态生成的 1 ~ 6 档位数字全部存在
        for (var i = 1; i <= 6; i++) {
          expect(find.text('$i'), findsOneWidget);
        }
      },
    );

    testWidgets('supports dynamic gearMax = 4 from backend config', (
      tester,
    ) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_mode_3x1',
        label: 'Telescopic',
        gearMax: 4,
        gearCurrent: 2,
        rows: 3,
        cols: 1,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 312,
              child: TelescopicSteppedControl(config: config),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1 ~ 4 存在，5 和 6 不存在
      for (var i = 1; i <= 4; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      expect(find.text('5'), findsNothing);
      expect(find.text('6'), findsNothing);
    });

    testWidgets(
      'tapping gear number updates active gear and triggers onGearChanged',
      (tester) async {
        int? changedGear;
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.telescopic,
          variant: 'telescopic_mode_3x1',
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
                child: TelescopicSteppedControl(
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
        type: FreeControlComponentType.telescopic,
        variant: 'telescopic_mode_3x1',
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
              child: TelescopicSteppedControl(
                config: config,
                onGearChanged: (gear) => changedGear = gear,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 查找胶囊手势区域
      final capsuleFinder = find.byKey(
        const ValueKey('telescopic_capsule_area'),
      );
      expect(capsuleFinder, findsOneWidget);

      // 点击胶囊接近顶部位置（高档位）
      final capsuleBox = tester.getRect(capsuleFinder);
      await tester.tapAt(Offset(capsuleBox.center.dx, capsuleBox.top + 10));
      await tester.pumpAndSettle();

      expect(changedGear, 6);
    });

    testWidgets(
      'parses backend Option A JSON and initializes with defaultValue',
      (tester) async {
        final backendJson = <String, dynamic>{
          'type': 'telescopic',
          'variant': 'telescopic_mode_3x1',
          'row': 1,
          'col': 0,
          'rows': 3,
          'cols': 1,
          'label': 'Telescopic',
          'gearMax': 6,
          'gearMin': 1,
          'defaultValue': 3,
          'variableSpeedSupported': false,
        };

        final config = FreeControlComponentConfig.fromJson(backendJson);
        expect(config, isNotNull);
        expect(config!.gearMax, 6);
        expect(config.gearMin, 1);
        expect(config.defaultValue, 3);
        expect(config.gearCurrent, 3);
        expect(config.rows, 3);
        expect(config.cols, 1);
        expect(config.variableSpeedSupported, isFalse);
        expect(config.displayLabel, 'Telescopic');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 172,
                height: 312,
                child: TelescopicSteppedControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证标题正常
        expect(find.text('Telescopic'), findsOneWidget);

        // 验证 1~6 档位均在
        for (var i = 1; i <= 6; i++) {
          expect(find.text('$i'), findsOneWidget);
        }
      },
    );

    test('fallback works when backend omits optional fields', () {
      final minimalJson = <String, dynamic>{
        'type': 'telescopic',
        'variant': 'telescopic_mode_3x1',
        'row': 0,
        'col': 0,
      };

      final config = FreeControlComponentConfig.fromJson(minimalJson);
      expect(config, isNotNull);
      expect(config!.gearMax, 6);
      expect(config.gearMin, 1);
      expect(config.defaultValue, 1);
      expect(config.gearCurrent, 1);
      expect(config.rows, 3);
      expect(config.cols, 1);
      expect(config.displayLabel, 'Telescopic');
    });

    testWidgets(
      'dragging across slots updates gear immediately and avoids duplicate callbacks',
      (tester) async {
        final gearChanges = <int>[];
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.telescopic,
          variant: 'telescopic_mode_3x1',
          gearMax: 6,
          gearMin: 1,
          defaultValue: 1,
          rows: 3,
          cols: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 172,
                height: 312,
                child: TelescopicSteppedControl(
                  config: config,
                  onGearChanged: gearChanges.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final capsuleFinder = find.byKey(
          const ValueKey('telescopic_capsule_area'),
        );
        final capsuleBox = tester.getRect(capsuleFinder);

        // 从底部往上拖拽
        final gesture = await tester.startGesture(
          Offset(capsuleBox.center.dx, capsuleBox.bottom - 10),
        );
        await tester.pump();

        // 向上移动（在同一格子内移动不产生多余回调）
        await gesture.moveBy(const Offset(0, -5));
        await tester.pump();
        final countInSameSlot = gearChanges.length;

        await gesture.moveBy(const Offset(0, -2));
        await tester.pump();
        expect(gearChanges.length, countInSameSlot);

        // 大幅向上移动跨入更高档位
        await gesture.moveBy(const Offset(0, -120));
        await tester.pump();

        expect(gearChanges.length, greaterThan(countInSameSlot));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
