import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/device_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeDeviceRepository implements DeviceRepository {
  _FakeDeviceRepository(this.result);

  final Result<List<Device>> result;
  int loadCount = 0;

  @override
  Future<Result<List<Device>>> loadDevices() async {
    loadCount++;
    return result;
  }
}

Device _device() => Device(
  id: 'device-1',
  model: 'cyberskin-air',
  name: 'Cyberskin Air',
  status: DeviceConnectionStatus.connected,
  capabilities: DeviceCapabilities(channels: const <ChannelCapability>[]),
  batteryPercent: 82,
);

void main() {
  test('loads devices into observable state', () async {
    final repository = _FakeDeviceRepository(Result.ok(<Device>[_device()]));
    final controller = DeviceHomeController(repository);

    await controller.load();

    expect(repository.loadCount, 1);
    expect(controller.devices, hasLength(1));
    expect(controller.devices.single.name, 'Cyberskin Air');
    expect(controller.failure.value, isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test(
    'exposes repository failures without throwing from the controller',
    () async {
      const failure = AppFailure(
        code: FailureCode.network,
        message: 'Network unavailable',
      );
      final repository = _FakeDeviceRepository(const Result.failure(failure));
      final controller = DeviceHomeController(repository);

      await controller.load();

      expect(controller.devices, isEmpty);
      expect(controller.failure.value, failure);
      expect(controller.isLoading.value, isFalse);
    },
  );
}
