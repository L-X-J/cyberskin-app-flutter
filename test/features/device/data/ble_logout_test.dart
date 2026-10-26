// 注销期间的目录回包、设备事件和会话清理回归；不连接平台蓝牙。
import 'dart:async';

import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/data/cyberskin_ble_runtime_coordinator.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/device_repository.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_controller.dart';
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Stop updates scanning immediately and ignores a late scan-start event',
    () async {
      final coordinator = CyberskinBleRuntimeCoordinator(
        catalogRepository: _Catalog(),
        isAuthenticated: () => true,
      );
      coordinator.isScanning.value = true;
      await coordinator.stopDiscovery();
      expect(coordinator.isScanning.value, isFalse);
      coordinator.handleEventForTesting(const BleScanningChanged(true));
      expect(coordinator.isScanning.value, isFalse);
      coordinator.onClose();
    },
  );

  test(
    'anonymous page initialization cannot load profiles or reconnect',
    () async {
      final catalog = _Catalog();
      final coordinator = _Coordinator(catalog, () => false);
      addTearDown(coordinator.onClose);

      await coordinator.loadProfilesAndStart();
      coordinator.handleEventForTesting(const BleScanningChanged(true));
      coordinator.handleEventForTesting(
        const BleConnectionChanged(
          remoteId: 'old',
          state: BleConnectionState.connected,
        ),
      );
      coordinator.handleEventForTesting(
        const BleRuntimeChanged(
          remoteId: 'old',
          status: BleRuntimeStatus(batteryLevel: 86),
        ),
      );
      coordinator.handleEventForTesting(const BleAdapterChanged('on'));

      expect(catalog.calls, 0);
      expect(coordinator.initializations, 0);
      expect(coordinator.connectionStates, isEmpty);
      expect(coordinator.runtime, isEmpty);
      expect(coordinator.isScanning.value, isFalse);
      expect(coordinator.adapterState.value, 'on');
    },
  );

  for (final result in <Result<List<DeviceModelSummary>>>[
    const Result.ok([DeviceModelSummary(id: 1)]),
    const Result.failure(
      AppFailure(code: FailureCode.network, message: 'late failure'),
    ),
  ]) {
    test(
      'logout discards an in-flight profile ${result.isFailure ? 'failure' : 'success'}',
      () async {
        var authenticated = true;
        final catalog = _Catalog();
        final coordinator = _Coordinator(catalog, () => authenticated);
        addTearDown(coordinator.onClose);
        final loading = coordinator.loadProfilesAndStart();
        await Future<void>.delayed(Duration.zero);
        expect(catalog.calls, 1);

        authenticated = false;
        await coordinator.clearUserSession();
        catalog.response.complete(result);
        await loading;

        expect(catalog.detailCalls, 0);
        expect(coordinator.failureCode.value, isNull);
        expect(coordinator.isScanning.value, isFalse);
        expect(coordinator.profileForModel(1), isNull);
      },
    );
  }

  test(
    'logout invalidates a pending device list in the retained controller',
    () async {
      var authenticated = true;
      final coordinator = _Coordinator(_Catalog(), () => authenticated);
      final repository = _PendingDevices();
      final controller = DeviceHomeController(repository, coordinator);
      controller.onReady();
      coordinator.connectionStates['old'] = BleConnectionState.connected;
      authenticated = false;
      await coordinator.clearUserSession();
      repository.response.complete(
        Result.ok([
          Device(
            id: 'old',
            model: '1',
            name: 'Old account device',
            status: DeviceConnectionStatus.connected,
            capabilities: DeviceCapabilities(channels: const []),
          ),
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.devices, isEmpty);
      expect(controller.isLoading.value, isFalse);
      expect(coordinator.connectedDevice.value, isNull);
      controller.onClose();
      coordinator.onClose();
    },
  );

  test(
    'session clears BLE without a home controller and awaits cleanup',
    () async {
      late final _Coordinator coordinator;
      final session = SessionController(
        onSessionEnded: () => coordinator.clearUserSession(),
      )..markAuthenticated();
      coordinator = _Coordinator(
        _Catalog(),
        () => session.state.value == SessionState.authenticated,
      );
      addTearDown(coordinator.onClose);
      coordinator.connectionStates['old'] = BleConnectionState.connected;
      coordinator.runtime['old'] = const BleRuntimeStatus(batteryLevel: 86);
      coordinator.isScanning.value = true;
      session.deviceStatus.value = DeviceConnectionStatus.connected;
      final stopGate = Completer<void>();
      coordinator.stopGate = stopGate;
      var completed = false;
      final logout = session.logout().then((_) => completed = true);

      expect(session.state.value, SessionState.anonymous);
      expect(session.deviceStatus.value, DeviceConnectionStatus.disconnected);
      expect(coordinator.connectionStates, isEmpty);
      expect(coordinator.runtime, isEmpty);
      expect(coordinator.connectedDevice.value, isNull);
      expect(coordinator.isScanning.value, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);

      stopGate.complete();
      await logout;
      expect(completed, isTrue);
      expect(coordinator.stops, 2);
    },
  );
}

class _Coordinator extends CyberskinBleRuntimeCoordinator {
  _Coordinator(_Catalog catalog, bool Function() authenticated)
    : super(catalogRepository: catalog, isAuthenticated: authenticated);
  int initializations = 0;
  int stops = 0;
  Completer<void>? stopGate;
  @override
  Future<void> initializeBluetooth() async {
    initializations++;
  }

  @override
  Future<void> stopDiscovery() async {
    stops++;
    await stopGate?.future;
  }
}

class _Catalog implements DeviceCatalogRepository {
  int calls = 0;
  int detailCalls = 0;
  final response = Completer<Result<List<DeviceModelSummary>>>();
  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() {
    calls++;
    return response.future;
  }

  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) {
    detailCalls++;
    throw StateError('Stale profile results must not request details');
  }

  @override
  Future<Result<DeviceManual>> getManual(int id) => throw UnimplementedError();
}

class _PendingDevices implements DeviceRepository {
  final response = Completer<Result<List<Device>>>();
  @override
  Future<Result<List<Device>>> loadDevices() => response.future;
}
