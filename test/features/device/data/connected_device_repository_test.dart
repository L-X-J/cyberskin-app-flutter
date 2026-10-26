// 真实 BLE 连接与账号绑定列表独立时，设备页仍展示当前连接的型号信息。
import 'dart:async';

import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/data/connected_device_repository.dart';
import 'package:cyberskin_app/features/device/domain/connected_device_state.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/device_repository.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/domain/repositories/user_device_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/ble_control_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'empty bindings still resolve live model metadata and telemetry',
    () async {
      final fixture = BleControlFixture();
      addTearDown(fixture.dispose);
      fixture.emit(stoppedStatus);
      final catalog = _Catalog();
      final repository = ConnectedDeviceRepository(
        userDeviceRepository: _EmptyBindings(),
        catalogRepository: catalog,
        bleCoordinator: fixture.coordinator,
      );
      final controller = DeviceHomeController(repository, fixture.coordinator);
      addTearDown(controller.onClose);
      await controller.load();

      expect(catalog.requested, [1]);
      expect(controller.devices.single.name, 'Real model');
      expect(
        controller.devices.single.status,
        DeviceConnectionStatus.connected,
      );
      expect(
        controller.devices.single.capabilities.channels.single.channel,
        DeviceChannel.heat,
      );
      expect(controller.devices.single.cardColor, '#E35239');
      expect(
        fixture.coordinator.connectedDevice.value!.device.name,
        'Real model',
      );
      expect(fixture.coordinator.connectedDevice.value!.batteryLevel.value, 80);
    },
  );

  test('late detail response cannot resurrect a disconnected device', () async {
    final fixture = BleControlFixture();
    addTearDown(fixture.dispose);
    final catalog = _Catalog()..gate = Completer<Result<DeviceModelDetail>>();
    final repository = ConnectedDeviceRepository(
      userDeviceRepository: _EmptyBindings(),
      catalogRepository: catalog,
      bleCoordinator: fixture.coordinator,
    );
    final loading = repository.loadDevices();
    await Future<void>.delayed(Duration.zero);
    fixture.coordinator.connectionStates.clear();
    fixture.coordinator.clearConnectedDevice();
    catalog.gate!.complete(Result.ok(catalog.detail));
    expect((await loading).valueOrNull, isEmpty);
  });

  test(
    'snapshot arriving after an empty list populates UI and survives refresh',
    () async {
      final fixture = BleControlFixture();
      addTearDown(fixture.dispose);
      fixture.coordinator.clearConnectedDevice();
      final controller = DeviceHomeController(
        _EmptyDevices(),
        fixture.coordinator,
      );
      controller.onReady();
      addTearDown(controller.onClose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.devices, isEmpty);
      final state = ConnectedDeviceState(
        remoteId: 'a',
        device: Device(
          id: 'a',
          model: '1',
          name: 'Connected device',
          status: DeviceConnectionStatus.connected,
          capabilities: DeviceCapabilities(channels: const []),
        ),
      );
      fixture.coordinator.setConnectedDevice(state);
      expect(controller.devices.single, same(state.device));
      await controller.reload();
      expect(controller.devices.single, same(state.device));
      expect(fixture.coordinator.connectedDevice.value, same(state));
      fixture.coordinator.connectionStates.clear();
      expect(controller.devices, isEmpty);
      expect(fixture.coordinator.connectedDevice.value, isNull);
    },
  );
}

class _EmptyDevices implements DeviceRepository {
  @override
  Future<Result<List<Device>>> loadDevices() async => const Result.ok([]);
}

class _EmptyBindings implements UserDeviceRepository {
  @override
  Future<Result<List<UserDevice>>> listUserDevices() async =>
      const Result.ok([]);
  @override
  Future<Result<UserDevice>> bind(UserDeviceBindRequest request) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> rename(int id, String customName) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> unbind(int id) => throw UnimplementedError();
  @override
  void invalidateCache() {}
}

class _Catalog implements DeviceCatalogRepository {
  final requested = <int>[];
  Completer<Result<DeviceModelDetail>>? gate;
  final detail = DeviceModelDetail(
    summary: const DeviceModelSummary(
      id: 1,
      name: 'Real model',
      cardColor: '#E35239',
    ),
    supportedActions: [
      {'code': 'heat'},
    ],
  );
  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async {
    requested.add(id);
    return gate == null ? Result.ok(detail) : await gate!.future;
  }

  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.ok([]);
  @override
  Future<Result<DeviceManual>> getManual(int id) => throw UnimplementedError();
}
