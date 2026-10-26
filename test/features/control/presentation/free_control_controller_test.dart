import 'dart:async';

import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/control/domain/device_command_repository.dart';
import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/free_control_controller.dart';
import 'package:cyberskin_app/features/control/free_control/presentation/widgets/free_control_component_placeholders.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:cyberskin_app/features/device/data/cyberskin_ble_runtime_coordinator.dart';
import 'package:cyberskin_app/features/device/domain/connected_device_state.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 型号详情加载失败，让控制器回退默认布局，避免测试依赖网络。
final class _OfflineCatalogRepository implements DeviceCatalogRepository {
  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.ok(<DeviceModelSummary>[]);

  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async =>
      const Result.failure(
        AppFailure(code: FailureCode.network, message: 'offline'),
      );

  @override
  Future<Result<DeviceManual>> getManual(int id) async =>
      throw UnimplementedError();
}

/// 记录下发指令；[gate] 非空时阻塞写入，用于模拟 BLE 写入在途。
final class _RecordingCommandRepository implements DeviceCommandRepository {
  final List<String> sent = <String>[];
  final List<(int?, String?)> targets = <(int?, String?)>[];
  Completer<void>? gate;
  Result<void> result = const Result.ok(null);

  @override
  Future<Result<void>> send(
    String command, {
    int? modelId,
    String? remoteId,
  }) async {
    sent.add(command);
    targets.add((modelId, remoteId));
    final pending = gate;
    if (pending != null) await pending.future;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  late CyberskinBleRuntimeCoordinator bleCoordinator;
  late _RecordingCommandRepository commands;
  late FreeControlController controller;
  late ConnectedDeviceState device;

  const stepped = FreeControlComponentConfig(
    type: FreeControlComponentType.telescopic,
    variant: 'telescopic_mode_1x2',
    cols: 2,
    gearMax: 6,
    gearCurrent: 2,
  );

  setUp(() {
    Get.reset();
    bleCoordinator = CyberskinBleRuntimeCoordinator(
      isAuthenticated: () => true,
      catalogRepository: _OfflineCatalogRepository(),
    );
    commands = _RecordingCommandRepository();
    controller = FreeControlController(
      catalogRepository: _OfflineCatalogRepository(),
      bleCoordinator: bleCoordinator,
      sessionController: ControlSessionController(),
      commandRepository: commands,
    );
    device = ConnectedDeviceState(
      device: Device(
        id: '1',
        model: '7',
        name: 'Device',
        status: DeviceConnectionStatus.connected,
        capabilities: DeviceCapabilities(channels: const []),
      ),
      remoteId: 'remote-1',
    );
  });

  tearDown(Get.reset);

  group('FreeControlController commands', () {
    test(
      'coalesces rapid intensity changes while a write is in flight',
      () async {
        bleCoordinator.setConnectedDevice(device);
        commands.gate = Completer<void>();

        controller.onIntensityChanged(FreeControlComponentType.telescopic, 10);
        controller.onIntensityChanged(FreeControlComponentType.telescopic, 20);
        controller.onIntensityChanged(FreeControlComponentType.telescopic, 30);
        controller.onToggleChanged(FreeControlComponentType.heat, true);
        expect(commands.sent, ['t:10']);

        commands.gate!.complete();
        await pumpEventQueue();

        // 中间值 20 被丢弃；开关指令不会被同通道强度覆盖。
        expect(commands.sent, ['t:10', 't:30', 'h:o']);
        expect(commands.targets, everyElement((7, 'remote-1')));
      },
    );

    test('maps gears, suck modes and ignores unknown modes', () async {
      bleCoordinator.setConnectedDevice(device);
      const suck = FreeControlComponentConfig(
        type: FreeControlComponentType.suck,
        variant: 'suck_multi_2x2',
        modes: ['Easy', 'Quick'],
      );

      controller.onGearSelected(stepped, 4);
      await pumpEventQueue();
      controller.onSuckModeSelected(suck, 'Quick');
      await pumpEventQueue();
      controller.onSuckModeSelected(suck, 'Missing');
      await pumpEventQueue();

      expect(commands.sent, ['t:67', 'CM->s:2']);
    });

    test('drops commands when no device is connected', () async {
      controller.onToggleChanged(FreeControlComponentType.suck, true);
      await pumpEventQueue();

      expect(commands.sent, isEmpty);
    });

    test('keeps draining after a failed write', () async {
      bleCoordinator.setConnectedDevice(device);
      commands.result = const Result.failure(
        AppFailure(code: FailureCode.network, message: 'rejected'),
      );

      controller.onToggleChanged(FreeControlComponentType.heat, true);
      controller.onToggleChanged(FreeControlComponentType.suck, false);
      await pumpEventQueue();

      expect(commands.sent, ['h:o', 's:f']);
    });
  });

  group('FreeControlController telemetry', () {
    test('reports connection status honestly', () {
      expect(controller.connectionStatusText, 'Disconnected');
      bleCoordinator.setConnectedDevice(device);
      expect(controller.connectionStatusText, 'Connected');
    });

    test('derives gears from reported power', () {
      bleCoordinator.setConnectedDevice(device);
      expect(controller.reportedGear(stepped), isNull);

      device.motorPower.value = 67;
      expect(controller.reportedGear(stepped), 4);

      // 设备停止（功率 0）时控件归零，与 gear=0 停止语义对齐。
      device.motorPower.value = 0;
      expect(controller.reportedGear(stepped), 0);
      expect(
        controller.reportedPercent(FreeControlComponentType.telescopic),
        0,
      );

      // 尚未上报（power=-1）时保留控件当前显示，不强制归零。
      device.motorPower.value = -1;
      expect(controller.reportedGear(stepped), isNull);
    });

    test('maps suck and heat states', () {
      bleCoordinator.setConnectedDevice(device);
      expect(controller.suckOn, isFalse);
      expect(controller.heatOn, isFalse);

      device.suckState.value = 3;
      device.heatState.value = 1;
      expect(controller.suckOn, isTrue);
      expect(controller.heatOn, isTrue);

      // 待机不是运行状态。
      device.suckState.value = 1;
      expect(controller.suckOn, isFalse);
    });
  });

  group('FreeControlComponentPlaceholder binding', () {
    Widget host(FreeControlComponentConfig config, Size size) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: FreeControlComponentPlaceholder(
            config: config,
            height: size.height,
          ),
        ),
      ),
    );

    testWidgets('heat bar follows telemetry and sends toggles', (tester) async {
      Get.put<FreeControlController>(controller);
      bleCoordinator.setConnectedDevice(device);
      device.heatState.value = 1;
      const heat = FreeControlComponentConfig(
        type: FreeControlComponentType.heat,
        variant: 'heat_bar_1x2',
        cols: 2,
      );

      await tester.pumpWidget(host(heat, const Size(358, 105)));
      await tester.pumpAndSettle();
      expect(find.text('Heating'), findsOneWidget);

      await tester.tap(find.text('ON'));
      await tester.pumpAndSettle();
      expect(commands.sent, ['h:f']);
      expect(find.text('Not enabled'), findsOneWidget);

      // 设备侧被重新打开时，UI 跟随上报状态。
      device.heatState.value = 0;
      await tester.pumpAndSettle();
      device.heatState.value = 1;
      await tester.pumpAndSettle();
      expect(find.text('Heating'), findsOneWidget);
    });

    testWidgets('stepped control follows reported power', (tester) async {
      Get.put<FreeControlController>(controller);
      bleCoordinator.setConnectedDevice(device);
      device.motorPower.value = 67;

      Finder gearText(String text) => find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(text),
      );

      await tester.pumpWidget(host(stepped, const Size(358, 135)));
      await tester.pumpAndSettle();
      expect(gearText('Gear  4 / 6'), findsOneWidget);

      device.motorPower.value = 100;
      await tester.pumpAndSettle();
      expect(gearText('Gear  6 / 6'), findsOneWidget);
      expect(commands.sent, isEmpty, reason: '遥测同步不能回写设备');
    });

    testWidgets('suck multi shows motion and sends mode commands', (
      tester,
    ) async {
      Get.put<FreeControlController>(controller);
      bleCoordinator.setConnectedDevice(device);
      device.suckState.value = 2;
      const suck = FreeControlComponentConfig(
        type: FreeControlComponentType.suck,
        variant: 'suck_multi_2x2',
        rows: 2,
        cols: 2,
        modes: ['Easy', 'Quick'],
      );

      await tester.pumpWidget(host(suck, const Size(358, 231)));
      // 波纹动画无限循环，只能按固定时长推进。
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Inhaling'), findsOneWidget);

      await tester.tap(find.text('Quick'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(commands.sent, ['CM->s:2']);

      device.suckState.value = 3;
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Exhaling'), findsOneWidget);
    });
  });
}
