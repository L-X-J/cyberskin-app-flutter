// 时长滚轮局部回归；真实 Flutter 截图不作为 Golden 基线。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_duration_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _capture = ValueKey('duration-capture');
Future<void> _pump(
  WidgetTester tester, {
  int initial = 3,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
  ValueChanged<int>? onChanged,
}) async {
  var value = initial;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: direction,
          child: RepaintBoundary(
            key: _capture,
            child: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: StatefulBuilder(
                    builder: (context, setState) => RhythmDurationWheel(
                      value: value,
                      onChanged: (next) {
                        setState(() => value = next);
                        onChanged?.call(next);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PageController _controller(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!;
void _center(WidgetTester tester, String label) {
  expect(
    _controller(tester).page!,
    closeTo(_controller(tester).page!.round(), .001),
  );
  expect(
    tester.getCenter(find.text(label)).dx,
    closeTo(tester.getCenter(find.byType(RhythmDurationWheel)).dx, .1),
  );
}

void main() {
  test('用户确认预设与自定义秒数文案', () {
    expect(rhythmDurationPresets, [
      1,
      3,
      5,
      10,
      30,
      60,
      120,
      for (var m = 3; m <= 20; m++) m * 60,
    ]);
    expect(formatRhythmDuration(121), '121s');
    expect(formatRhythmDuration(1200), '20m');
  });
  testWidgets('初值、自定义与外部更新准确居中', (tester) async {
    await _pump(tester);
    _center(tester, '3s');
    await _pump(tester, initial: 121);
    _center(tester, '121s');
    await _pump(tester, initial: 1200);
    _center(tester, '20m');
    expect(tester.takeException(), isNull);
  });
  testWidgets('切档触发选择震感，初始、外部同步和循环回位不重复触发', (tester) async {
    final feedback = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          feedback.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await _pump(tester, initial: 1200);
    expect(feedback, isEmpty);
    await tester.tap(find.text('1s'));
    await tester.pumpAndSettle();
    expect(feedback, ['HapticFeedbackType.selectionClick']);
    await tester.pumpAndSettle();
    expect(feedback, hasLength(1));

    await _pump(tester, initial: 10);
    expect(feedback, hasLength(1));
    await tester.drag(find.byType(PageView), const Offset(-64, 0));
    await tester.pumpAndSettle();
    expect(feedback.length, greaterThan(1));
    expect(feedback, everyElement('HapticFeedbackType.selectionClick'));
  });
  testWidgets('邻项点击和键盘双向跨循环', (tester) async {
    var value = 1200;
    await _pump(tester, initial: value, onChanged: (next) => value = next);
    await tester.tap(find.text('1s'));
    await tester.pumpAndSettle();
    expect(value, 1);
    _center(tester, '1s');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 1200);
    _center(tester, '20m');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 1);
  });
  testWidgets('拖动吸附与多周期重定位', (tester) async {
    var value = 1;
    await _pump(tester, initial: value, onChanged: (next) => value = next);
    for (var i = 0; i < 4; i++) {
      _controller(tester).jumpToPage(
        _controller(tester).page!.round() +
            rhythmDurationPresets.length * 3 +
            1,
      );
      await tester.pumpAndSettle();
    }
    expect(value, 30);
    await tester.drag(find.byType(PageView), const Offset(-83, 0));
    await tester.pumpAndSettle();
    expect(
      _controller(tester).page!,
      closeTo(_controller(tester).page!.round(), .001),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('单一辅助节点可增减跨循环', (tester) async {
    final handle = tester.ensureSemantics();
    var value = 1200;
    await _pump(tester, initial: value, onChanged: (next) => value = next);
    final node = tester.getSemantics(find.bySemanticsLabel('Duration'));
    expect(node.value, '1200 seconds');
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      ui.SemanticsAction.increase,
    );
    await tester.pumpAndSettle();
    expect(value, 1);
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      node.id,
      ui.SemanticsAction.decrease,
    );
    await tester.pumpAndSettle();
    expect(value, 1200);
    handle.dispose();
  });
  testWidgets('基准、窄屏双倍字、宽屏 RTL 截图', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final s in [
      (402.0, 874.0, 1.0, TextDirection.ltr),
      (320.0, 640.0, 2.0, TextDirection.ltr),
      (800.0, 420.0, 1.0, TextDirection.rtl),
    ]) {
      tester.view.physicalSize = Size(s.$1, s.$2);
      await _pump(tester, initial: 1200, scale: s.$3, direction: s.$4);
      _center(tester, '20m');
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_capture),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final file = File(
          'build/ui/rhythm/duration_20m_${s.$1.toInt()}x${s.$2.toInt()}_text${s.$3}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      });
    }
  });
}
