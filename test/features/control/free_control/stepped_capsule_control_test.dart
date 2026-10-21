// 分档胶囊控件刷新回归测试：验证父级重建不会把控件内部档位重置回初始值。

import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/stepped_capsule_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 构造一个 6 档伸缩通道的分档配置。
FreeControlComponentConfig _config({int gearCurrent = 4}) =>
    FreeControlComponentConfig(
      type: FreeControlComponentType.telescopic,
      variant: 'telescopic_mode_3x1',
      rows: 3,
      cols: 1,
      row: 0,
      col: 0,
      order: 1,
      gearMax: 6,
      gearCurrent: gearCurrent,
    );

/// 用给定档位渲染一个分档胶囊。
Widget _host(FreeControlComponentConfig config) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SteppedCapsuleControl(config: config, height: 312),
    ),
  ),
);

void main() {
  testWidgets('父级重建且 gearCurrent 不变时，控件内部档位不应被重置', (tester) async {
    await tester.pumpWidget(_host(_config(gearCurrent: 6)));
    await tester.pumpAndSettle();

    // 模拟父级 Obx 重建：每次都用新的 config 实例，但档位值保持不变。
    await tester.pumpWidget(_host(_config(gearCurrent: 6)));
    await tester.pumpAndSettle();

    final dynamic state = tester.state(find.byType(SteppedCapsuleControl));
    expect(state.currentGear, 6);
  });

  testWidgets('gearCurrent 真正变化时控件档位跟随设备上报', (tester) async {
    await tester.pumpWidget(_host(_config(gearCurrent: 2)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(_config(gearCurrent: 5)));
    await tester.pumpAndSettle();

    final dynamic state = tester.state(find.byType(SteppedCapsuleControl));
    expect(state.currentGear, 5);
  });

  testWidgets('拖拽过程中只更新显示不发回调，抬手且值变化才发一次', (tester) async {
    final gears = <int>[];
    Widget host(FreeControlComponentConfig config) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SteppedCapsuleControl(
            config: config,
            height: 312,
            onGearChanged: gears.add,
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(_config(gearCurrent: 6)));
    await tester.pumpAndSettle();
    expect(gears, isEmpty);

    // 从顶部 6 档向下滑：拖拽途中不发，抬手后只发一次最终值（滑到底部为 0 档停止）。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SteppedCapsuleControl)),
    );
    for (var i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(gears, isEmpty, reason: '拖拽过程中不应发送回调');
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(gears.length, 1, reason: '抬手后应只发一次回调');
    expect(gears.single, lessThan(6), reason: '应从起始档位 6 发生变化');
  });

  testWidgets('拖拽后值回到起始档位时不发回调', (tester) async {
    final gears = <int>[];
    Widget host(FreeControlComponentConfig config) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SteppedCapsuleControl(
            config: config,
            height: 312,
            onGearChanged: gears.add,
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(_config(gearCurrent: 6)));
    await tester.pumpAndSettle();

    // 起始档位 6：先向下拖（中途档位变化但不发），再向上拖回顶部归位到 6 档，
    // 抬手时最终值 == 起始值，不应触发回调。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SteppedCapsuleControl)),
    );
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    expect(gears, isEmpty);
    await gesture.moveBy(const Offset(0, -320));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(gears, isEmpty, reason: '回到起始档位时不应发送回调');
  });
}
