// 主页头部滚动模糊、一级标签位移时序与常驻页面状态验证。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/app/widgets/app_scaffold.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/device_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_connected/home_connected_view.dart';
import 'package:cyberskin_app/features/home/presentation/home_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_page.dart';
import 'package:cyberskin_app/features/home/presentation/widgets/home_shared_widgets.dart';
import 'package:cyberskin_app/features/video/presentation/video_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _FakeDeviceRepository implements DeviceRepository {
  _FakeDeviceRepository(this.result);

  final Result<List<Device>> result;

  @override
  Future<Result<List<Device>>> loadDevices() async => result;
}

Device _testDevice() => Device(
  id: 'device-test-1',
  model: '389',
  name: 'Cyberskin Air',
  status: DeviceConnectionStatus.connected,
  capabilities: DeviceCapabilities(channels: const <ChannelCapability>[]),
  batteryPercent: 88,
  cardColor: '#5E185F',
);

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() => Get.reset());

  testWidgets('tabs slide with header exit first and preserve page states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 949);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 50, bottom: 34);
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      for (final font in [
        ('HomeMotionPreview', 'Roboto-Medium.ttf'),
        ('MaterialIcons', 'MaterialIcons-Regular.otf'),
      ]) {
        final bytes = File(
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/${font.$2}',
        ).readAsBytesSync();
        await (FontLoader(
          font.$1,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    final home = Get.put(HomeController(Get.put(SessionController())));
    final device = Get.put(
      DeviceHomeController(
        _FakeDeviceRepository(Result.ok(<Device>[_testDevice()])),
      ),
    );
    await device.load();
    home.deviceStatus.value = DeviceConnectionStatus.connected;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'HomeMotionPreview',
        ),
        home: const RepaintBoundary(
          key: ValueKey('home-motion-capture'),
          child: HomePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(HomePage));
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/home/device_air_connected.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/home/go_user_profile.png'),
          context,
        ),
      ]);
    });
    await tester.pump(const Duration(seconds: 2));
    final header = find.byType(HomeHeader);
    final deviceBody = find.byType(DeviceBodyContent, skipOffstage: false);
    final videoBody = find.byType(VideoTabContent, skipOffstage: false);
    final headerRect = tester.getRect(header);
    final deviceState = tester.state(find.byType(HomeConnectedView));
    final videoState = tester.state(videoBody);
    final scroll = tester
        .widget<HomeConnectedView>(find.byType(HomeConnectedView))
        .scrollController!;
    Future<void> capture(String state) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('home-motion-capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        try {
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/ui').createSync(recursive: true);
          File('build/ui/home_tabs_${state}_402x949_text1.0.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
    }

    await capture('device');
    await tester.tap(find.text('Video'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 55));
    expect(tester.getRect(header).top, lessThan(headerRect.top));
    expect(tester.getSize(header), headerRect.size);
    expect(tester.getTopLeft(deviceBody).dx, 0);
    await capture('header_exiting');
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getRect(header).bottom, lessThanOrEqualTo(headerRect.top));
    expect(tester.getTopLeft(deviceBody).dx, inExclusiveRange(-402, 0));
    expect(tester.getTopLeft(videoBody).dx, inExclusiveRange(0, 402));
    await capture('to_video');
    await tester.pump(const Duration(milliseconds: 165));
    expect(tester.getTopLeft(videoBody).dx, 0);
    expect(find.text('My device').hitTestable(), findsNothing);
    await capture('video');

    await tester.tap(find.text('Device'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 165));
    expect(tester.getTopLeft(deviceBody).dx, inExclusiveRange(-402, 0));
    expect(tester.getRect(header).bottom, lessThanOrEqualTo(headerRect.top));
    await capture('to_device');
    await tester.pump(const Duration(milliseconds: 275));
    expect(tester.getRect(header), headerRect);
    expect(tester.getTopLeft(deviceBody).dx, 0);
    expect(tester.state(find.byType(HomeConnectedView)), same(deviceState));
    expect(tester.state(videoBody), same(videoState));

    tester.view.physicalSize = const Size(402, 600);
    await tester.pump();
    scroll.jumpTo(50);
    await tester.pump();
    expect(scroll.offset, 50);

    home.selectTab(AppTab.video);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    home.selectTab(AppTab.home);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    home.selectTab(AppTab.video);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 440));
    expect(tester.getTopLeft(videoBody).dx, 0);
    expect(tester.getSize(header), headerRect.size);
    home.selectTab(AppTab.home);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 440));
    expect(scroll.offset, 50);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion switches body and header immediately', (
    tester,
  ) async {
    final home = Get.put(HomeController(Get.put(SessionController())));
    home.deviceStatus.value = DeviceConnectionStatus.connected;
    await tester.pumpWidget(
      const GetMaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: HomePage(),
        ),
      ),
    );
    await tester.pump();
    final header = find.byType(HomeHeader);
    final originalHeader = tester.getRect(header);
    home.selectTab(AppTab.video);
    await tester.pump();
    expect(tester.getTopLeft(find.byType(VideoTabContent)).dx, 0);
    expect(tester.getRect(header).bottom, closeTo(originalHeader.top, 0.1));
    expect(tester.getSize(header), originalHeader.size);
    home.selectTab(AppTab.home);
    await tester.pump();
    expect(tester.getRect(header), originalHeader);
    expect(tester.takeException(), isNull);
  });

  group('HomeHeader blur background unit tests', () {
    testWidgets('renders without BackdropFilter when scrollProgress is 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              title: 'My device',
              subtitle: 'Good evening, stay relaxed',
              scrollProgress: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('My device'), findsOneWidget);
      expect(find.text('Good evening, stay relaxed'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('renders BackdropFilter when scrollProgress > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeHeader(
              title: 'Add Device',
              subtitle: 'Keep device nearby to scan',
              scrollProgress: 0.8,
            ),
          ),
        ),
      );

      expect(find.text('Add Device'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });
  });

  group('HomePage scroll-driven blur tests', () {
    testWidgets(
      'HomeHeader dynamically enables BackdropFilter on scroll in disconnected state',
      (tester) async {
        tester.view.physicalSize = const Size(390, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final session = Get.put(SessionController());
        Get.put(HomeController(session));

        await tester.pumpWidget(
          GetMaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: const HomePage(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // 初始停留在顶部，无高斯模糊背景
        expect(
          find.descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );

        // 向上拖动列表（内容向上滑动）
        await tester.drag(find.byType(ListView), const Offset(0, -60));
        await tester.pump(const Duration(milliseconds: 50));

        // 滑动后，HomeHeader 具有动态高斯模糊遮罩背景
        expect(
          find.descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(BackdropFilter),
          ),
          findsOneWidget,
        );

        // 向下拖动回顶部
        await tester.drag(find.byType(ListView), const Offset(0, 100));
        await tester.pump(const Duration(milliseconds: 50));

        // 回到顶部后，模糊背景自动清除
        expect(
          find.descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'HomeHeader dynamically enables BackdropFilter on scroll in connected state',
      (tester) async {
        final session = Get.put(SessionController());
        final homeController = Get.put(HomeController(session));
        final deviceController = DeviceHomeController(
          _FakeDeviceRepository(Result.ok(<Device>[_testDevice()])),
        );
        Get.put<DeviceHomeController>(deviceController);
        await deviceController.load();

        homeController.deviceStatus.value = DeviceConnectionStatus.connected;

        await tester.pumpWidget(
          GetMaterialApp(
            theme: ThemeData(brightness: Brightness.dark),
            home: const HomePage(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        // 初始停留在顶部，无高斯模糊背景
        expect(
          find.descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );

        // 向上拖动已连接列表
        await tester.drag(find.byType(ListView), const Offset(0, -60));
        await tester.pump(const Duration(milliseconds: 50));

        // 滑动后，HomeHeader 启用动态高斯模糊
        expect(
          find.descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(BackdropFilter),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
