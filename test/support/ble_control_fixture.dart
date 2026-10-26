// 通过真实协调器 SDK 事件投影路径驱动回归，不连接平台蓝牙。
import 'dart:async';

import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/control/domain/device_command_repository.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:cyberskin_app/features/device/data/cyberskin_ble_runtime_coordinator.dart';
import 'package:cyberskin_app/features/device/domain/connected_device_state.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/rhythm/domain/services/rhythm_playback.dart';
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

const stoppedStatus = BleRuntimeStatus(
  motorPower: 0,
  lastReportedMotorPower: 30,
  vibrateMotorPower: 0,
  lastReportedVibrateMotorPower: 80,
  suckState: -1,
  heatState: 0,
  batteryLevel: 80,
);
const commandFailure = Result<void>.failure(
  AppFailure(code: FailureCode.sessionLost, message: 'Command failed'),
);

class TestCommands implements DeviceCommandRepository {
  final sent = <String>[];
  Result<void> result = const Result.ok(null);
  Completer<Result<void>>? pending;
  @override
  Future<Result<void>> send(
    String command, {
    int? modelId,
    String? remoteId,
  }) async {
    sent.add(command);
    return pending == null ? result : pending!.future;
  }
}

class BleControlFixture {
  BleControlFixture({
    RhythmPlayback? rhythm,
    SessionController? session,
    bool initialize = true,
    List<DeviceChannel> channels = const [
      DeviceChannel.telescopic,
      DeviceChannel.vibration,
    ],
  }) {
    SharedPreferences.setMockInitialValues({});
    coordinator = CyberskinBleRuntimeCoordinator(
      isAuthenticated: () => true,
      catalogRepository: _Catalog(),
      preferencesFuture: SharedPreferences.getInstance(),
    );
    coordinator.connectionStates['a'] = BleConnectionState.connected;
    coordinator.setConnectedDevice(
      ConnectedDeviceState(
        device: Device(
          id: 'a',
          model: '1',
          name: 'Test',
          status: DeviceConnectionStatus.connected,
          capabilities: DeviceCapabilities(
            channels: [
              for (final channel in channels)
                ChannelCapability(channel: channel),
            ],
          ),
        ),
        remoteId: 'a',
      ),
    );
    control = ControlSessionController(
      bleCoordinator: coordinator,
      commandRepository: commands,
      programPlayback: rhythm?.engine,
      sessionController: session,
    );
    if (initialize) control.onInit();
  }

  late final CyberskinBleRuntimeCoordinator coordinator;
  late final ControlSessionController control;
  final commands = TestCommands();

  void emit(BleRuntimeStatus status, {String remoteId = 'a'}) =>
      coordinator.handleEventForTesting(
        BleRuntimeChanged(remoteId: remoteId, status: status),
      );

  void dispose() {
    control.onClose();
    coordinator.onClose();
  }
}

class _Catalog implements DeviceCatalogRepository {
  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.ok([]);
  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) =>
      throw UnimplementedError();
  @override
  Future<Result<DeviceManual>> getManual(int id) => throw UnimplementedError();
}
