// 连续变速胶囊控件回归测试：验证拖拽发送时机的「抬手才发」契约。

import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/variable_capsule_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 构造一个震动横向无级变速配置。
FreeControlComponentConfig _config({int? gearCurrent}) =>
    FreeControlComponentConfig(
      type: FreeControlComponentType.vibration,
      variant: 'vibration_variable_1x2',
      cols: 2,
      gearCurrent: gearCurrent,
    );

/// 用给定配置渲染一个横向无级变速胶囊。
Widget _host(
  FreeControlComponentConfig config, {
  ValueChanged<int>? onChanged,
}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 135,
            child: VariableCapsuleControl(
              config: config,
              orientation: Axis.horizontal,
              onValueChanged: onChanged,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('拖拽过程中只更新显示不发回调，抬手且值变化才发一次', (tester) async {
    final values = <int>[];
    await tester.pumpWidget(
      _host(_config(gearCurrent: 62), onChanged: values.add),
    );
    await tester.pumpAndSettle();
    expect(values, isEmpty);

    // 从右侧高百分比向左拖到低百分比：拖拽途中不发，抬手后只发一次最终值。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(VariableCapsuleControl)),
    );
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(values, isEmpty, reason: '拖拽过程中不应发送回调');
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(values.length, 1, reason: '抬手后应只发一次回调');
    expect(values.single, lessThan(62));
  });

  testWidgets('拖拽后值回到起始百分比时不发回调', (tester) async {
    final values = <int>[];
    // 起始 50% 正好对应横向中心，便于从中心 touch-down 后拖回原位。
    await tester.pumpWidget(
      _host(_config(gearCurrent: 50), onChanged: values.add),
    );
    await tester.pumpAndSettle();

    // 从中心向左拖（值降低），再向右拖回中心 50% 归位，抬手时最终值 == 起始值，不发回调。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(VariableCapsuleControl)),
    );
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(values, isEmpty);
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(values, isEmpty, reason: '回到起始百分比时不应发送回调');
  });
}
