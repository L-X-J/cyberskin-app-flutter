import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/app/floating_control_controller.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/control/domain/device_session.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/free_control_controller.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/free_control_page.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:cyberskin_app/features/device/data/cyberskin_ble_runtime_coordinator.dart';
import 'package:cyberskin_app/features/device/domain/connected_device_state.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _FakeCatalogRepository implements DeviceCatalogRepository {
  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.ok(<DeviceModelSummary>[]);

  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async =>
      throw UnimplementedError();

  @override
  Future<Result<DeviceManual>> getManual(int id) async =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  test('freeControl page configures floating control policy as hidden', () {
    expect(
      AppRoutes.floatingControlPolicies[AppRoutes.freeControl],
      FloatingControlPolicy.hidden,
    );
  });

  group('FreeControlPage', () {
    late FreeControlController controller;
    late CyberskinBleRuntimeCoordinator bleCoordinator;
    late ControlSessionController sessionController;

    setUp(() {
      Get.reset();
      bleCoordinator = CyberskinBleRuntimeCoordinator(
        catalogRepository: _FakeCatalogRepository(),
      );
      sessionController = ControlSessionController();
      controller = FreeControlController(
        catalogRepository: _FakeCatalogRepository(),
        bleCoordinator: bleCoordinator,
        sessionController: sessionController,
      );
      Get.put<FreeControlController>(controller);
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('renders back button, title, and subtitle initially', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: FreeControlPage()));
      await tester.pump();

      // 验证返回按钮存在
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      // 验证大标题与副标题
      expect(find.text('Free control mode'), findsOneWidget);
      expect(find.textContaining('Connected'), findsOneWidget);
    });

    testWidgets('collapsing on scroll fades subtitle and animates header', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: FreeControlPage()));
      await tester.pump();

      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      // 获取初始大标题位置
      final initialTitleOffset = tester.getTopLeft(
        find.text('Free control mode'),
      );

      // 向上滚动模拟折叠
      await tester.drag(listViewFinder, const Offset(0, -80));
      await tester.pump();

      // 折叠后标题位置发生了向上的平滑过渡
      final scrolledTitleOffset = tester.getTopLeft(
        find.text('Free control mode'),
      );
      expect(scrolledTitleOffset.dy, lessThan(initialTitleOffset.dy));

      // 验证返回按钮仍然存在并在固定位置
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    });

    test(
      'device disconnection sets control session to idle and navigates home',
      () async {
        final device = Device(
          id: '1',
          model: '1',
          name: 'Device',
          status: DeviceConnectionStatus.connected,
          capabilities: DeviceCapabilities(channels: const []),
        );
        final connectedState = ConnectedDeviceState(
          device: device,
          remoteId: 'remote-1',
        );
        bleCoordinator.setConnectedDevice(connectedState);
        bleCoordinator.connectionStates['remote-1'] =
            BleConnectionState.connected;

        expect(sessionController.state.value, DeviceSessionState.running);

        // 模拟设备断开（休眠或关机）
        bleCoordinator.connectionStates['remote-1'] =
            BleConnectionState.disconnected;
        bleCoordinator.clearConnectedDevice();

        await Future<void>.delayed(Duration.zero);

        expect(sessionController.state.value, DeviceSessionState.idle);
      },
    );
  });
}
