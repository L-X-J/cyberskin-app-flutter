import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/data/cyberskin_ble_runtime_coordinator.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/home/presentation/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _FakeDeviceCatalogRepository implements DeviceCatalogRepository {
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

  test('uses disconnected as the default device state', () {
    final controller = HomeController(SessionController());

    expect(controller.deviceStatus.value, DeviceConnectionStatus.disconnected);
  });

  test(
    'shows the login-required phase for anonymous users when adapter is on',
    () async {
      final coordinator = CyberskinBleRuntimeCoordinator(
        isAuthenticated: () => true,
        catalogRepository: _FakeDeviceCatalogRepository(),
      );
      final session = SessionController();
      final controller = HomeController(session, bleCoordinator: coordinator);

      controller.onReady();
      coordinator.adapterState.value = 'on';
      coordinator.isInitialized.value = true;
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.bleCardState.value.phase,
        HomeBleCardPhase.loginRequired,
      );
      controller.onClose();
      coordinator.onClose();
    },
  );

  test('starts discovery after the session becomes authenticated', () async {
    final coordinator = _TestBleCoordinator();
    final session = SessionController();
    final controller = HomeController(session, bleCoordinator: coordinator);

    controller.onReady();
    session.markAuthenticated();
    await Future<void>.delayed(Duration.zero);

    expect(coordinator.loadProfilesAndStartCalls, 1);

    controller.onClose();
    coordinator.onClose();
  });

  test('clears the user BLE session after logout', () async {
    final coordinator = _TestBleCoordinator();
    final session = SessionController(
      onSessionEnded: coordinator.clearUserSession,
    )..markAuthenticated();
    final controller = HomeController(session, bleCoordinator: coordinator);

    controller.onReady();
    session.markAnonymous();
    await Future<void>.delayed(Duration.zero);

    expect(coordinator.clearUserSessionCalled, isTrue);

    controller.onClose();
    coordinator.onClose();
  });

  test(
    'ready primary action starts discovery for authenticated users',
    () async {
      final coordinator = _TestBleCoordinator();
      final session = SessionController()..markAuthenticated();
      final controller = HomeController(session, bleCoordinator: coordinator);
      controller.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.ready,
        adapterOn: true,
      );

      await controller.handleBlePrimaryAction();

      expect(coordinator.loadProfilesAndStartCalls, 1);

      controller.onClose();
      coordinator.onClose();
    },
  );

  test(
    'requests Bluetooth permission before requiring login to scan',
    () async {
      final coordinator = _TestBleCoordinator()..permissionResult = false;
      final session = SessionController();
      final controller = HomeController(session, bleCoordinator: coordinator);
      controller.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.permissionRequired,
        adapterOn: true,
      );

      await controller.handleBlePrimaryAction();

      expect(coordinator.requestBluetoothPermissionsCalled, isTrue);
      expect(coordinator.loadProfilesAndStartCalls, 0);

      controller.onClose();
      coordinator.onClose();
    },
  );

  test('handles bluetoothOff phase for anonymous user by turning on bluetooth or opening settings', () async {
    final coordinator = _TestBleCoordinator();
    final session = SessionController();
    final controller = HomeController(session, bleCoordinator: coordinator);

    controller.onReady();
    coordinator.adapterState.value = 'off';
    coordinator.isInitialized.value = true;
    await Future<void>.delayed(Duration.zero);

    expect(controller.bleCardState.value.phase, HomeBleCardPhase.bluetoothOff);

    // Turn on fails (e.g. platform restrictions), should fall back to opening settings
    coordinator.turnOnBluetoothResult = false;
    await controller.handleBlePrimaryAction();

    expect(coordinator.turnOnBluetoothCalled, isTrue);
    expect(coordinator.openBluetoothSettingsCalled, isTrue);

    controller.onClose();
    coordinator.onClose();
  });
}

final class _TestBleCoordinator extends CyberskinBleRuntimeCoordinator {
  _TestBleCoordinator()
    : super(
        catalogRepository: _FakeDeviceCatalogRepository(),
        isAuthenticated: () => true,
      );

  bool turnOnBluetoothCalled = false;
  bool openBluetoothSettingsCalled = false;
  bool requestBluetoothPermissionsCalled = false;
  bool turnOnBluetoothResult = false;
  bool permissionResult = true;
  int loadProfilesAndStartCalls = 0;
  bool clearUserSessionCalled = false;

  @override
  Future<void> clearUserSession() async {
    clearUserSessionCalled = true;
  }

  @override
  Future<void> loadProfilesAndStart() async {
    loadProfilesAndStartCalls++;
  }

  @override
  Future<bool> requestBluetoothPermissions() async {
    requestBluetoothPermissionsCalled = true;
    return permissionResult;
  }

  @override
  Future<bool> turnOnBluetooth() async {
    turnOnBluetoothCalled = true;
    return turnOnBluetoothResult;
  }

  @override
  Future<bool> openBluetoothSettings() async {
    openBluetoothSettingsCalled = true;
    return true;
  }
}
