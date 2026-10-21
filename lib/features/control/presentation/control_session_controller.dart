// 跨页面共享的设备会话状态与快捷控制编排入口。
// ignore_for_file: prefer_initializing_formals
import 'dart:async';

import 'package:get/get.dart';

import '../../../app/session_controller.dart';
import '../../../core/logging/app_log.dart';
import '../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../device/domain/connected_device_state.dart';
import '../../device/domain/device.dart';
import '../../device/domain/device_capability.dart';
import '../domain/device_command_repository.dart';
import '../domain/device_session.dart';

/// 为全局设备快捷控制条提供共享状态与语义指令编排的 GetX 控制器。
final class ControlSessionController extends GetxController {
  /// 创建全局控制会话控制器。
  ControlSessionController({
    CyberskinBleRuntimeCoordinator? bleCoordinator,
    DeviceCommandRepository? commandRepository,
    SessionController? sessionController,
    AppLog log = const NoopAppLog(),
  }) : _bleCoordinator = bleCoordinator,
       _commandRepository = commandRepository,
       _sessionController = sessionController,
       _log = log;

  final CyberskinBleRuntimeCoordinator? _bleCoordinator;
  final DeviceCommandRepository? _commandRepository;
  final SessionController? _sessionController;
  final AppLog _log;

  /// 当前会话状态；保持独立响应式字段，使状态变化时只重建控制条。
  final Rx<DeviceSessionState> state = DeviceSessionState.idle.obs;

  final List<Worker> _bleWorkers = <Worker>[];
  final List<Worker> _telemetryWorkers = <Worker>[];

  @override
  void onInit() {
    super.onInit();
    _bindBleWorkers();
  }

  void _bindBleWorkers() {
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;

    _bleWorkers.add(
      ever(coordinator.connectionStates, (_) {
        _syncConnectionAndSession();
      }),
    );

    _bleWorkers.add(
      ever(coordinator.connectedDevice, (connected) {
        _bindTelemetry(connected);
      }),
    );

    _syncConnectionAndSession();
    _bindTelemetry(coordinator.connectedDevice.value);
  }

  void _syncConnectionAndSession() {
    final coordinator = _bleCoordinator;
    if (coordinator == null) return;

    final session = _sessionController;
    final isConnected = coordinator.hasConnectedDevice;
    final isConnecting = coordinator.isConnecting;

    final DeviceConnectionStatus targetStatus;
    if (isConnecting) {
      targetStatus = DeviceConnectionStatus.connecting;
    } else if (isConnected) {
      final runtime = coordinator.connectedRuntime;
      final battery = runtime?.batteryLevel ?? -1;
      final isLow = battery >= 0 && battery <= 20;

      targetStatus = isLow
          ? DeviceConnectionStatus.lowBattery
          : DeviceConnectionStatus.connected;
    } else {
      targetStatus = DeviceConnectionStatus.disconnected;
    }

    if (session != null && session.deviceStatus.value != targetStatus) {
      session.setDeviceConnectionStatus(targetStatus);
    }
    if (!isConnected &&
        !isConnecting &&
        state.value != DeviceSessionState.idle) {
      updateState(DeviceSessionState.idle);
    }
  }

  void _bindTelemetry(ConnectedDeviceState? connected) {
    for (final worker in _telemetryWorkers) {
      worker.dispose();
    }
    _telemetryWorkers.clear();

    if (connected == null) return;

    void checkTelemetry() {
      final motor = connected.motorPower.value;
      final vibrate = connected.vibrateMotorPower.value;
      final suck = connected.suckState.value;

      final isRunning =
          (motor > 0) || (vibrate > 0) || (suck == 2 || suck == 3);

      if (isRunning) {
        if (state.value != DeviceSessionState.running) {
          updateState(DeviceSessionState.running);
        }
      } else if (motor == 0 && vibrate == 0 && suck != 2 && suck != 3) {
        if (state.value == DeviceSessionState.running) {
          updateState(DeviceSessionState.paused);
        }
      }
    }

    _telemetryWorkers.add(ever(connected.motorPower, (_) => checkTelemetry()));
    _telemetryWorkers.add(
      ever(connected.vibrateMotorPower, (_) => checkTelemetry()),
    );
    _telemetryWorkers.add(ever(connected.suckState, (_) => checkTelemetry()));

    _telemetryWorkers.add(
      ever(connected.batteryLevel, (battery) {
        if (_sessionController == null) return;
        if (battery >= 0 && battery <= 20) {
          _sessionController.setDeviceConnectionStatus(
            DeviceConnectionStatus.lowBattery,
          );
        } else if (_sessionController.deviceStatus.value ==
                DeviceConnectionStatus.lowBattery &&
            _bleCoordinator?.hasConnectedDevice == true) {
          _sessionController.setDeviceConnectionStatus(
            DeviceConnectionStatus.connected,
          );
        }
      }),
    );

    checkTelemetry();
  }

  /// 在 Repository 或 BLE 事件到达后更新会话状态。
  void updateState(DeviceSessionState nextState) {
    if (state.value == nextState) {
      return;
    }
    state.value = nextState;
  }

  /// 暂停运行中的会话，或恢复已暂停的会话。
  void togglePause() {
    final nextState = switch (state.value) {
      DeviceSessionState.running => DeviceSessionState.paused,
      DeviceSessionState.paused => DeviceSessionState.running,
      DeviceSessionState.idle || DeviceSessionState.connecting => state.value,
    };
    if (nextState != state.value) {
      updateState(nextState);
      if (nextState == DeviceSessionState.paused) {
        unawaited(sendPause());
      } else if (nextState == DeviceSessionState.running) {
        unawaited(sendResume());
      }
    }
  }

  /// 悬浮控制条主点击激活入口：
  /// - 运行中（running / runningLowBattery）：发送暂停指令并置为 paused；
  /// - 暂停或待启动（paused / idle）：发送继续/启动指令并置为 running。
  Future<void> activateQuickControl() async {
    if (state.value == DeviceSessionState.running) {
      updateState(DeviceSessionState.paused);
      await sendPause();
    } else {
      updateState(DeviceSessionState.running);
      await sendResume();
    }
  }

  /// 向当前连接设备发送暂停指令。
  Future<void> sendPause() async {
    final repository = _commandRepository;
    if (repository == null) return;

    final connected = _bleCoordinator?.connectedDevice.value;
    final capabilities = connected?.device.capabilities;
    final command = _buildPauseCommand(capabilities);

    final result = await repository.send(
      command,
      modelId: _bleCoordinator?.connectedModelId,
      remoteId: _bleCoordinator?.connectedRemoteId,
    );
    if (result.isFailure) {
      _log.warning(
        'Quick control pause command failed',
        data: {'command': command},
        error: result.failureOrNull?.message,
      );
    }
  }

  /// 向当前连接设备发送恢复/开始运行指令。
  Future<void> sendResume() async {
    final repository = _commandRepository;
    if (repository == null) return;

    final connected = _bleCoordinator?.connectedDevice.value;
    final capabilities = connected?.device.capabilities;
    final command = _buildResumeCommand(capabilities);

    final result = await repository.send(
      command,
      modelId: _bleCoordinator?.connectedModelId,
      remoteId: _bleCoordinator?.connectedRemoteId,
    );
    if (result.isFailure) {
      _log.warning(
        'Quick control resume command failed',
        data: {'command': command},
        error: result.failureOrNull?.message,
      );
    }
  }

  /// 根据能力构建暂停指令。
  String _buildPauseCommand(DeviceCapabilities? capabilities) {
    final hasTelescopic =
        capabilities?.supports(DeviceChannel.telescopic) ?? true;
    final hasVibration =
        capabilities?.supports(DeviceChannel.vibration) ?? true;
    final hasSuck = capabilities?.supports(DeviceChannel.suck) ?? false;

    final parts = <String>[];
    if (hasTelescopic) parts.add('t:s');
    if (hasVibration) parts.add('v:s');
    if (hasSuck) parts.add('s:s');
    if (parts.isEmpty) return 't:s|v:s';
    return parts.join('|');
  }

  /// 根据能力构建恢复/启动运行指令。
  String _buildResumeCommand(DeviceCapabilities? capabilities) {
    final hasTelescopic =
        capabilities?.supports(DeviceChannel.telescopic) ?? true;
    final hasVibration =
        capabilities?.supports(DeviceChannel.vibration) ?? true;

    final parts = <String>[];
    if (hasTelescopic) parts.add('t:c');
    if (hasVibration) parts.add('v:c');
    if (parts.isEmpty) return 't:c|v:c';
    return parts.join('|');
  }

  @override
  void onClose() {
    for (final worker in _telemetryWorkers) {
      worker.dispose();
    }
    _telemetryWorkers.clear();

    for (final worker in _bleWorkers) {
      worker.dispose();
    }
    _bleWorkers.clear();

    super.onClose();
  }
}
