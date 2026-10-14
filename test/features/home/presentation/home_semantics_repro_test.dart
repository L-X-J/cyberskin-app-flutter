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
    await tester.pump(const Duration(milliseconds: 300));

    controller.deviceStatus.value = DeviceConnectionStatus.connected;
    await tester.pump(const Duration(milliseconds: 300));

    controller.deviceStatus.value = DeviceConnectionStatus.disconnected;
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders checking phase and login action without card action button',
    (tester) async {
      final session = Get.put(SessionController());
      final controller = Get.put(HomeController(session));

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: const HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      controller.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.loginRequired,
        adapterOn: true,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Log in now'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsNothing);

      controller.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.ready,
        adapterOn: true,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Scan'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);

      controller.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.scanning,
        adapterOn: true,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Stop'), findsOneWidget);

      controller.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.connecting,
        adapterOn: true,
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Connecting'), findsOneWidget);

      controller.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.unavailable,
        adapterOn: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_disabled), findsOneWidget);
    },
  );
}
