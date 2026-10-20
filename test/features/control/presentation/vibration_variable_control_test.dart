import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/vibration_variable_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VibrationVariableControl', () {
    testWidgets(
      'renders title, vibration icon, subtitle, 100%/0% scale bar, and 12% indicator by default (matching vibration-c.png)',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_3x1',
          label: 'Vibration',
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
                child: VibrationVariableControl(config: config),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证标题、副标题与震动图标
        expect(find.text('Vibration'), findsOneWidget);
        expect(find.text('Variable Speed'), findsOneWidget);
        expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);

        // 验证左侧 100% 与 0% 刻度指示标签
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);

        // 验证右侧上方默认展示 12%（对齐 vibration-c.png 设计图基准）
        expect(find.text('12%'), findsOneWidget);
      },
    );

    testWidgets('supports dynamic initialPercentage and updates indicator', (
      tester,
    ) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_variable_3x1',
        label: 'Vibration',
        rows: 3,
        cols: 1,
        gearCurrent: 75,
        variableSpeedSupported: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 355,
              child: VibrationVariableControl(
                config: config,
                initialPercentage: 75,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets(
      'vertical tap on capsule calculates correct percentage and updates indicator',
      (tester) async {
        int? changedPercent;
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_3x1',
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
                child: VibrationVariableControl(
                  config: config,
                  initialPercentage: 10,
                  onGearChanged: (val) => changedPercent = val,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 寻找竖向胶囊手势区域
        final capsuleFinder = find.byKey(
          const ValueKey('vibration_variable_capsule_area'),
        );
        expect(capsuleFinder, findsOneWidget);

        final capsuleRect = tester.getRect(capsuleFinder);

        // 点击垂直中间位置（对应 50%）
        await tester.tapAt(
          Offset(
            capsuleRect.center.dx,
            capsuleRect.top + capsuleRect.height * 0.5,
          ),
        );
        await tester.pumpAndSettle();

        expect(changedPercent, equals(50));
        expect(find.text('50%'), findsOneWidget);
      },
    );

    testWidgets(
      'vertical dragging updates percentage immediately from bottom to top',
      (tester) async {
        final percentValues = <int>[];
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_3x1',
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
                child: VibrationVariableControl(
                  config: config,
                  initialPercentage: 12,
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

        // 从底部 20% 高度位置向上拖拽至 80% 高度位置
        // 注意：垂直方向 y 越小（越靠上）百分比越大
        final startOffset = Offset(
          capsuleRect.center.dx,
          capsuleRect.bottom - capsuleRect.height * 0.20,
        );
        final gesture = await tester.startGesture(startOffset);
        await tester.pump();

        // 向上移动至 50%
        await gesture.moveTo(
          Offset(
            capsuleRect.center.dx,
            capsuleRect.bottom - capsuleRect.height * 0.50,
          ),
        );
        await tester.pump();

        // 向上移动至 80%
        await gesture.moveTo(
          Offset(
            capsuleRect.center.dx,
            capsuleRect.bottom - capsuleRect.height * 0.80,
          ),
        );
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(percentValues, contains(50));
        expect(percentValues, contains(80));
        expect(find.text('80%'), findsOneWidget);
      },
    );

    testWidgets(
      'FreeControlComponentPlaceholder dispatches VibrationVariableControl for vibration_variable_3x1',
      (tester) async {
        const config = FreeControlComponentConfig(
          type: FreeControlComponentType.vibration,
          variant: 'vibration_variable_3x1',
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

        expect(find.byType(VibrationVariableControl), findsOneWidget);
        expect(find.text('Variable Speed'), findsOneWidget);
        expect(find.text('12%'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
      },
    );

    testWidgets('handles boundary values 0% and 100%', (tester) async {
      const config = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_variable_3x1',
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
              child: VibrationVariableControl(
                config: config,
                initialPercentage: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsNWidgets(2)); // 刻度 0% 与大数字 0%

      // 更新为 100%
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 172,
              height: 355,
              child: VibrationVariableControl(
                config: config,
                initialPercentage: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsNWidgets(2)); // 刻度 100% 与大数字 100%
    });
  });
}
