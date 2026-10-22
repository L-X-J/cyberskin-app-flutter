// 通道模式反选、草稿保留和序列化回归；不访问 API/BLE。
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm_program.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_channel_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stack 箭头不占位，首行保留三个模式且展开后宽度不变', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RhythmChannelEditor(
              capability: const RhythmChannelCapability(
                channel: RhythmChannel.thrust,
                modes: ['AAA', 'BBB', 'CCC', 'DDD'],
                variableSpeed: true,
              ),
              setting: const RhythmChannelSetting(
                channel: RhythmChannel.thrust,
                on: true,
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('AAA'), findsOneWidget);
    expect(find.text('BBB'), findsOneWidget);
    expect(find.text('CCC'), findsOneWidget);
    expect(find.text('DDD'), findsNothing);
    final firstRowY = tester.getTopLeft(find.text('AAA')).dy;
    expect(tester.getTopLeft(find.text('CCC')).dy, firstRowY);
    final list = find
        .ancestor(of: find.text('AAA'), matching: find.byType(Wrap))
        .first;
    expect(tester.getSize(list).width, 290);
    await tester.tap(find.byTooltip('Expand modes'));
    await tester.pumpAndSettle();
    expect(find.text('DDD'), findsOneWidget);
    expect(tester.getSize(list).width, 290);
    expect(tester.getTopLeft(find.text('CCC')).dy, firstRowY);
    expect(tester.takeException(), isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('窄屏 text$scale 模式首行折叠、展开与收起保留选择', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var setting = const RhythmChannelSetting(
        channel: RhythmChannel.thrust,
        on: true,
        value: 65,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) => RhythmChannelEditor(
                    capability: const RhythmChannelCapability(
                      channel: RhythmChannel.thrust,
                      modes: ['Alpha', 'Beta', 'Gamma', 'Delta'],
                      variableSpeed: true,
                    ),
                    setting: setting,
                    onChanged: (value) => setState(() => setting = value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Expand modes'), findsOneWidget);
      expect(find.text('Delta'), findsNothing);
      expect(setting.mode, isNull);
      final firstButton = tester.getRect(
        find.byType(AppLiquidGlassButton).first,
      );
      final arrow = tester.getRect(find.byTooltip('Expand modes'));
      final modesStack = find
          .ancestor(
            of: find.byTooltip('Expand modes'),
            matching: find.byType(Stack),
          )
          .first;
      expect(tester.getSize(modesStack).width, 290);
      expect(arrow.right, tester.getRect(modesStack).right);
      expect(arrow.center.dy, closeTo(firstButton.center.dy, 1));
      final collapsedHeight = tester
          .getSize(find.byType(RhythmChannelEditor))
          .height;
      await tester.tap(find.byTooltip('Expand modes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final expandingHeight = tester
          .getSize(find.byType(RhythmChannelEditor))
          .height;
      await tester.pumpAndSettle();
      final expandedHeight = tester
          .getSize(find.byType(RhythmChannelEditor))
          .height;
      expect(expandingHeight, greaterThan(collapsedHeight));
      expect(expandingHeight, lessThan(expandedHeight));
      expect(find.text('Delta'), findsOneWidget);
      // 全部模式共享一个 Wrap，箭头是列表外的兄弟，不产生首行专属占位。
      final wraps = find.ancestor(
        of: find.byType(AppLiquidGlassButton).first,
        matching: find.byType(Wrap),
      );
      expect(wraps, findsOneWidget);
      final list = wraps.first;
      expect(
        find.descendant(of: list, matching: find.byType(AppLiquidGlassButton)),
        findsNWidgets(4),
      );
      expect(
        find.descendant(of: list, matching: find.byType(IconButton)),
        findsNothing,
      );
      await tester.tap(find.text('Delta'));
      await tester.pumpAndSettle();
      expect(setting.mode, 4);
      await tester.ensureVisible(find.byTooltip('Collapse modes'));
      await tester.tap(find.byTooltip('Collapse modes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final collapsingHeight = tester
          .getSize(find.byType(RhythmChannelEditor))
          .height;
      expect(collapsingHeight, greaterThan(collapsedHeight));
      expect(collapsingHeight, lessThan(expandedHeight));
      await tester.pumpAndSettle();
      expect(find.text('Delta'), findsNothing);
      expect(setting.mode, 4);
      expect(setting.value, isNull);
      expect(setting.on, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  const capability = RhythmChannelCapability(
    channel: RhythmChannel.thrust,
    modes: ['Mode A', 'Mode B'],
    variableSpeed: true,
  );
  const initial = RhythmChannelSetting(
    channel: RhythmChannel.thrust,
    on: true,
    mode: 1,
    value: 65,
  );

  test('显式清除模式保留其他字段，保存往返不恢复选择', () {
    expect(initial.copyWith(value: 70).mode, 1);
    final cleared = initial.copyWith(clearMode: true);
    expect(cleared.mode, isNull);
    expect(cleared.channel, initial.channel);
    expect(cleared.on, isTrue);
    expect(cleared.value, 65);
    expect(
      RhythmStep(
        durationSec: 3,
        channels: [cleared],
      ).encode().payload['command_data'],
      't:65',
    );
    final step = RhythmStep(durationSec: 3, channels: [cleared]);
    expect(() => step.validate([capability]), returnsNormally);
    expect(RhythmStep.decode(step.encode()).channels.single.mode, isNull);
    expect(initial.mode, 1);
  });

  testWidgets('已选模式可取消，未选可重选，其他模式保持单选', (tester) async {
    var setting = initial;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RhythmChannelEditor(
              capability: capability,
              setting: setting,
              onChanged: (value) => setState(() => setting = value),
            ),
          ),
        ),
      ),
    );

    void expectSelected(String? label) {
      final buttons = tester.widgetList<AppLiquidGlassButton>(
        find.byType(AppLiquidGlassButton),
      );
      for (final button in buttons) {
        expect(
          button.variant,
          button.label == label
              ? AppLiquidGlassButtonVariant.highlighted
              : AppLiquidGlassButtonVariant.translucent,
        );
      }
    }

    expect(find.byTooltip('Expand modes'), findsNothing);
    expectSelected('Mode A');
    for (final label in ['Mode A', 'Mode A', 'Mode B', 'Mode B']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(setting.on, isTrue);
      expect(setting.value, isNull);
      expectSelected(switch (setting.mode) {
        1 => 'Mode A',
        2 => 'Mode B',
        _ => null,
      });
    }
    expect(setting.mode, isNull);
    expect(tester.takeException(), isNull);
  });
}
