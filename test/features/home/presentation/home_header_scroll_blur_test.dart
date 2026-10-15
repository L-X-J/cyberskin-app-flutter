// 主页头部高斯模糊背景在列表滑动时的动态联动测试。
import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/device_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_page.dart';
import 'package:cyberskin_app/features/home/presentation/widgets/home_shared_widgets.dart';
import 'package:flutter/material.dart';
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
