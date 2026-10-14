// 将控制领域的语义命令委托给共享 BLE SDK。
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../domain/device_command_repository.dart';

/// Cyberskin BLE 语义指令 Repository。
final class BleDeviceCommandRepository implements DeviceCommandRepository {
  BleDeviceCommandRepository(this._coordinator);

  final CyberskinBleRuntimeCoordinator _coordinator;

  @override
  Future<Result<void>> send(
    String command, {
    int? modelId,
    String? remoteId,
  }) async {
    if (modelId == null || remoteId == null) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.invalidData,
          message: 'A connected device is required before sending a command.',
        ),
      );
    }
    final success = await _coordinator.sendCommand(
      modelId: modelId,
      remoteId: remoteId,
      command: command,
    );
    return success
        ? const Result.ok(null)
        : const Result.failure(
            AppFailure(
              code: FailureCode.network,
              message: 'The device did not accept the command.',
            ),
          );
  }
}
