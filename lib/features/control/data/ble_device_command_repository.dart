// 将控制领域的语义命令委托给共享 BLE SDK。
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../domain/device_command_repository.dart';

/// Cyberskin BLE 语义指令 Repository。
final class BleDeviceCommandRepository implements DeviceCommandRepository {
  /// 创建 BLE 语义指令 Repository 实例。
  BleDeviceCommandRepository(this._coordinator, {this.runWithControl});

  /// 手动控制在下发前先取得设备控制权；公共播放端口使用未装饰的实例。
  final Future<Result<void>> Function(Future<Result<void>> Function())?
  runWithControl;

  final CyberskinBleRuntimeCoordinator _coordinator;

  @override
  Future<Result<void>> send(String command, {int? modelId, String? remoteId}) =>
      runWithControl == null
      ? _send(command, modelId: modelId, remoteId: remoteId)
      : runWithControl!(
          () => _send(command, modelId: modelId, remoteId: remoteId),
        );

  Future<Result<void>> _send(
    String command, {
    int? modelId,
    String? remoteId,
  }) async {
    final effectiveModelId = modelId ?? _coordinator.connectedModelId;
    final effectiveRemoteId = remoteId ?? _coordinator.connectedRemoteId;
    if (effectiveModelId == null || effectiveRemoteId == null) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.invalidData,
          message: 'A connected device is required before sending a command.',
        ),
      );
    }
    final success = await _coordinator.sendCommand(
      modelId: effectiveModelId,
      remoteId: effectiveRemoteId,
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
