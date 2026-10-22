// 自定义时长范围、取消与键盘提交回归。
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_duration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('非法值显示错误，1200 可提交，取消返回空', (tester) async {
    Get.testMode = true;
    int? result;
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: TextButton(
      onPressed: () async { result = await Get.dialog<int>(const RhythmDurationDialog(initialValue: 121)); },
      child: const Text('Custom'),
    ))));
    await tester.tap(find.text('Custom')); await tester.pumpAndSettle();
    expect(find.text('121'), findsOneWidget);
    expect(find.text('1–1200 seconds'), findsOneWidget);
    for (final invalid in ['', '0', '1201']) {
      await tester.enterText(find.byType(TextFormField), invalid);
      await tester.tap(find.text('Confirm')); await tester.pumpAndSettle();
      expect(find.text('Duration must be 1–1200 seconds.'), findsOneWidget);
      expect(find.byType(RhythmDurationDialog), findsOneWidget);
    }
    await tester.enterText(find.byType(TextFormField), '1200');
    await tester.testTextInput.receiveAction(TextInputAction.done); await tester.pumpAndSettle();
    expect(result, 1200);
    expect(find.byType(RhythmDurationDialog), findsNothing);
    await tester.tap(find.text('Custom')); await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel')); await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.pumpWidget(const SizedBox());
    Get.reset();
  });
}
