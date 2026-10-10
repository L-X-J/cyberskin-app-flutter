import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/home/presentation/home_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(() => Get.reset());

  testWidgets('switching connection state does not crash semantics flush', (
    tester,
  ) async {
    final session = Get.put(SessionController());
    final controller = Get.put(HomeController(session));

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const HomePage(),
      ),
    );
    // Enable the semantics tree so flushSemantics runs on every frame.
    final handle = tester.ensureSemantics();
    await tester.pump();

    // Flip to connected, then back: swaps the ListView child structure.
    controller.deviceStatus.value = DeviceConnectionStatus.connected;
    await tester.pump();
    expect(tester.takeException(), isNull);

    controller.deviceStatus.value = DeviceConnectionStatus.disconnected;
    await tester.pump();
    expect(tester.takeException(), isNull);

    handle.dispose();
  });
}
