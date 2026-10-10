import 'dart:async';

import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/app/floating_control_controller.dart';
import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/app/widgets/app_primary_tab_navigation.dart';
import 'package:cyberskin_app/app/widgets/app_scaffold.dart';
import 'package:cyberskin_app/app/widgets/floating_device_control_overlay.dart';
import 'package:cyberskin_app/features/control/domain/device_session.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:cyberskin_app/features/control/presentation/widgets/device_control_pill.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late FloatingControlController floating;
  late SessionController session;
  late ControlSessionController control;
  const extraDetail = '/test-detail';
  const fullScreen = '/test-full-screen';
  setUp(() {
    Get.testMode = true;
    floating = Get.put(FloatingControlController(), permanent: true);
    session = Get.put(SessionController(), permanent: true)
      ..markAuthenticated();
    control = Get.put(ControlSessionController(), permanent: true);
  });
  tearDown(() => Get.reset());

  Future<void> render(
    WidgetTester tester, {
    double textScale = 1,
    Size viewport = const Size(402, 874),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 50, bottom: 34);
    addTearDown(tester.view.reset);
    Widget page(String title) => AppScaffold(
      currentTab: title == 'Video' ? AppTab.video : AppTab.home,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          TextButton(
            onPressed: () => unawaited(Get.toNamed<void>(AppRoutes.profile)),
            child: const Text('Open detail'),
          ),
          const TextField(),
          ...List.generate(
            25,
            (i) => SizedBox(height: 40, child: Text('Item $i')),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        initialRoute: AppRoutes.home,
        navigatorObservers: [
          FloatingControlObserver(
            policies: {
              ...AppRoutes.floatingControlPolicies,
              extraDetail: FloatingControlPolicy.draggable,
              fullScreen: FloatingControlPolicy.hidden,
            },
            resetRoutes: {AppRoutes.home},
          ),
        ],
        getPages: [
          GetPage(name: AppRoutes.home, page: () => page('Home')),
          GetPage(name: AppRoutes.device, page: () => page('Devices')),
          GetPage(name: AppRoutes.video, page: () => page('Video')),
          GetPage(name: AppRoutes.profile, page: () => page('Profile')),
          GetPage(name: extraDetail, page: () => page('Detail')),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('Login')),
          ),
          GetPage(
            name: fullScreen,
            page: () => const Scaffold(body: Text('Fullscreen')),
          ),
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: FloatingDeviceControlOverlay(child: child!),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  Future<void> open(WidgetTester tester, String route) async {
    unawaited(Get.toNamed<void>(route));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  testWidgets(
    'single host docks without overlapping navigation and fixed routes reject dragging',
    (tester) async {
      await render(tester);
      final pill = find.byType(DeviceControlPill);
      expect(pill, findsOneWidget);
      final rect = tester.getRect(pill);
      expect(rect.right, closeTo(378, 0.01));
      expect(
        rect.bottom,
        closeTo(floating.bodyBounds.value!.bottom - 12, 0.01),
      );
      final navigation = tester.getRect(find.byType(AppPrimaryTabNavigation));
      final overlapsHorizontally =
          rect.left < navigation.right && navigation.left < rect.right;
      if (overlapsHorizontally) {
        expect(navigation.bottom + 12, lessThanOrEqualTo(rect.top));
      } else {
        expect(rect.bottom, closeTo(navigation.bottom, 0.01));
      }
      await tester.drag(pill, const Offset(-120, -200));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(pill), rect);
      for (final route in [AppRoutes.device, AppRoutes.video]) {
        await open(tester, route);
        final before = tester.getRect(pill);
        await tester.drag(pill, const Offset(-100, -100));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getRect(pill), before);
        expect(pill, findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow large-text layout stacks the docks above the bottom safe area',
    (tester) async {
      await render(tester, textScale: 2, viewport: const Size(320, 568));
      final pill = tester.getRect(find.byType(DeviceControlPill));
      final navigation = tester.getRect(find.byType(AppPrimaryTabNavigation));

      expect(pill.bottom, lessThanOrEqualTo(568 - 34 - 12));
      expect(navigation.bottom + 12, lessThanOrEqualTo(pill.top));
      expect(navigation.left, 24);
      expect(navigation.width, AppPrimaryTabNavigation.maxWidth);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'drag preserves device state, secondary position, then animates home and resets',
    (tester) async {
      session.setDeviceConnectionStatus(DeviceConnectionStatus.connected);
      control.updateState(DeviceSessionState.running);
      await render(tester);
      await open(tester, AppRoutes.profile);
      final pill = find.byType(DeviceControlPill);
      final dock = tester.getTopLeft(pill);
      await tester.drag(pill, const Offset(-100, -160));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final dragged = tester.getTopLeft(pill);
      expect(dragged.dx, lessThan(dock.dx));
      expect(dragged.dy, lessThan(dock.dy));
      expect(control.state.value, DeviceSessionState.running);
      await tester.tap(pill);
      await tester.pump();
      expect(control.state.value, DeviceSessionState.paused);
      await open(tester, extraDetail);
      expect(tester.getTopLeft(pill), dragged);
      Get.until((route) => route.settings.name == AppRoutes.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final moving = tester.getTopLeft(pill);
      expect(moving.dy, greaterThan(dragged.dy));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      expect(floating.draggedPosition.value, isNull);
      expect(tester.getTopLeft(pill), floating.targetFor(tester.getSize(pill)));
      await open(tester, AppRoutes.profile);
      expect(tester.getTopLeft(pill), floating.targetFor(tester.getSize(pill)));
      expect(control.state.value, DeviceSessionState.paused);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dialogs, login and fullscreen do not have a control above them',
    (tester) async {
      await render(tester);
      final context = tester.element(find.byType(AppScaffold));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('Modal')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DeviceControlPill), findsNothing);
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(find.byType(DeviceControlPill), findsOneWidget);
      for (final route in [AppRoutes.login, fullScreen]) {
        await open(tester, route);
        expect(find.byType(DeviceControlPill), findsNothing);
        Get.back<void>();
        await tester.pumpAndSettle();
        expect(find.byType(DeviceControlPill), findsOneWidget);
      }
    },
  );

  testWidgets(
    'disconnected and connected-idle navigate, connecting ignores clicks',
    (tester) async {
      await render(tester);
      await tester.tap(find.byType(DeviceControlPill));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.device);
      Get.back<void>();
      await tester.pumpAndSettle();
      session.setDeviceConnectionStatus(DeviceConnectionStatus.connecting);
      await tester.pump();
      await tester.tap(find.byType(DeviceControlPill));
      await tester.pump(const Duration(milliseconds: 200));
      expect(Get.currentRoute, AppRoutes.home);
      session.setDeviceConnectionStatus(DeviceConnectionStatus.connected);
      await tester.pump();
      expect(find.text('Tap to start'), findsOneWidget);
      await tester.tap(find.byType(DeviceControlPill));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.device);
      expect(control.state.value, DeviceSessionState.idle);
    },
  );

  testWidgets(
    'keyboard, resize, large text and drag boundaries remain inside measured body',
    (tester) async {
      await render(tester, textScale: 2, viewport: const Size(320, 568));
      await open(tester, AppRoutes.profile);
      final pill = find.byType(DeviceControlPill);
      await tester.drag(pill, const Offset(-1000, -1000));
      await tester.pump();
      var rect = tester.getRect(pill);
      expect(rect.left, greaterThanOrEqualTo(floating.bodyBounds.value!.left));
      expect(rect.top, greaterThanOrEqualTo(floating.bodyBounds.value!.top));
      tester.view.viewInsets = const FakeViewPadding(bottom: 170);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      rect = tester.getRect(pill);
      expect(rect.bottom, lessThanOrEqualTo(398));
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.physicalSize = const Size(874, 402);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      rect = tester.getRect(pill);
      expect(rect.right, lessThanOrEqualTo(floating.bodyBounds.value!.right));
      expect(rect.bottom, lessThanOrEqualTo(floating.bodyBounds.value!.bottom));
      expect(tester.takeException(), isNull);
    },
  );
}
