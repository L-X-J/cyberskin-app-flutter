// 真实片段弹层与草稿同步，不访问 API/BLE。
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm_program.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_catalog.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_device_port.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_repository.dart';
import 'package:cyberskin_app/features/rhythm/domain/services/rhythm_playback.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/rhythm_edit_controller.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_duration_wheel.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_segment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Repository implements RhythmRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected IO');
}
class _Catalog implements RhythmCatalog {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected IO');
}
class _Port implements RhythmDevicePort {
  @override
  Stream<RhythmDeviceEvent> get events => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected BLE');
}

void main() {
  testWidgets('Continue 保留滚轮选择，编辑恢复非预设秒数及 20m', (tester) async {
    Get.testMode = true;
    final playback = RhythmPlayback(_Port());
    final controller = RhythmEditController(_Repository(), _Catalog(), playback, null);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await playback.dispose();
      Get.reset();
    });
    controller.capabilities.add(const RhythmChannelCapability(channel: RhythmChannel.thrust, modes: [], variableSpeed: true));
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: TextButton(
      onPressed: () => Get.bottomSheet<void>(RhythmSegmentSheet(controller: controller)), child: const Text('Open'),
    ))));
    await tester.tap(find.text('Open')); await tester.pumpAndSettle();
    // 当前滚轮没有 Custom 输入入口，使用真实邻项选择。
    await tester.tap(find.text('5s')); await tester.pumpAndSettle();
    expect(tester.widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel)).value, 5);
    await tester.tap(find.text('Continue')); await tester.pumpAndSettle();
    expect(RhythmStep.decode(controller.segments.single).durationSec, 5);
    expect(tester.widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel)).value, 5);
    await tester.tap(find.text('Continue')); await tester.pumpAndSettle();
    expect(controller.segments.length, 2);
    Get.back<void>(); await tester.pumpAndSettle();
    // 历史非预设秒数仍应恢复，并能通过真实滚轮切换到 20m。
    controller.segments[0] = RhythmStep(durationSec: 1199, channels: []).encode();
    Get.bottomSheet<void>(RhythmSegmentSheet(controller: controller, index: 0)); await tester.pumpAndSettle();
    expect(tester.widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel)).value, 1199);
    await tester.tap(find.text('20m')); await tester.pumpAndSettle();
    expect(tester.widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel)).value, 1200);
    await tester.tap(find.text('Confirm')); await tester.pumpAndSettle();
    expect(RhythmStep.decode(controller.segments.first).durationSec, 1200);
    Get.bottomSheet<void>(RhythmSegmentSheet(controller: controller, index: 0)); await tester.pumpAndSettle();
    expect(tester.widget<RhythmDurationWheel>(find.byType(RhythmDurationWheel)).value, 1200);
    expect(find.text('20m'), findsOneWidget);
    await tester.tap(find.text('Confirm')); await tester.pumpAndSettle();
    expect(controller.segments.length, 2);
    expect(tester.takeException(), isNull);
  });
}
