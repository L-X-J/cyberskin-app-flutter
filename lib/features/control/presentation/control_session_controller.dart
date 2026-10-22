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
import '../domain/services/device_program_playback.dart';

/// 为全局设备快捷控制条提供共享状态与语义指令编排的 GetX 控制器。
final class ControlSessionController extends GetxController {
  /// 创建全局控制会话控制器。
  ControlSessionController({
    DeviceProgramPlayback? programPlayback,
    CyberskinBleRuntimeCoordinator? bleCoordinator,
    DeviceCommandRepository? commandRepository,
    SessionController? sessionController,
    AppLog log = const NoopAppLog(),
  }) : _programPlayback = programPlayback,
       _bleCoordinator = bleCoordinator,
       _commandRepository = commandRepository,
       _sessionController = sessionController,
       _log = log;

  final DeviceProgramPlayback? _programPlayback;
  StreamSubscription<DeviceProgramPlaybackSnapshot>? _programSubscription;
  bool _hadProgramSession = false;
  final CyberskinBleRuntimeCoordinator? _bleCoordinator;
  final DeviceCommandRepository? _commandRepository;
  final SessionController? _sessionController;
  final AppLog _log;

  /// 当前会话状态；保持独立响应式字段，使状态变化时只重建控制条。
  final Rx<DeviceSessionState> state = DeviceSessionState.idle.obs;

  final List<Worker> _bleWorkers = <Worker>[];
  final List<Worker> _telemetryWorkers = <Worker>[];
  StreamSubscription<String>? _telemetrySubscription;
  int _stateRevision = 0;

  @override
  void onInit() {
    super.onInit();
    _bindBleWorkers();
    _programSubscription = _programPlayback?.changes.listen((snapshot) {
      if (_programPlayback.editing) {
        updateState(DeviceSessionState.paused);
        return;
      }
      if (_programPlayback.active) {
        _hadProgramSession = true;
        updateState(
          snapshot.phase == DeviceProgramPlaybackPhase.running
              ? DeviceSessionState.running
              : DeviceSessionState.paused,
        );
      } else if (_hadProgramSession) {
        _hadProgramSession = false;
        updateState(DeviceSessionState.idle);
      }
    });
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

    // 心跳在完整快照提交后逐帧广播，同值帧也必须纠正快捷操作的乐观状态。
    _telemetrySubscription = coordinator.rhythmHeartbeats.listen((remoteId) {
      if (remoteId == coordinator.connectedDevice.value?.remoteId) {
        _syncTelemetry();
      }
    });
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

    _syncTelemetry();
  }

  /// 只用完整的当前功率快照校正手动会话；历史功率和加热不代表运动。
  /// 支持的运动通道必须明确停止，未知值不能作为停止证据。
  void _syncTelemetry() {
    final coordinator = _bleCoordinator;
    final connected = coordinator?.connectedDevice.value;
    if (connected == null || coordinator?.hasConnectedDevice != true) return;
    if (_programPlayback?.active == true || _programPlayback?.editing == true) {
      return;
    }
    final status = coordinator!.runtime[connected.remoteId];
    if (status == null) return;
    if (status.motorPower > 0 ||
        status.vibrateMotorPower > 0 ||
        status.suckState == 2 ||
        status.suckState == 3) {
      updateState(DeviceSessionState.running);
      return;
    }
    final channels = connected.device.capabilities.channels
        .map((capability) => capability.channel)
        .where((channel) => channel != DeviceChannel.heat);
    final stopped =
        channels.isNotEmpty &&
        channels.every(
          (channel) => switch (channel) {
            DeviceChannel.telescopic => status.motorPower == 0,
            DeviceChannel.vibration => status.vibrateMotorPower == 0,
            DeviceChannel.suck => status.suckState == 1,
            DeviceChannel.heat => false,
          },
        );
    if (stopped) {
      updateState(
        state.value == DeviceSessionState.running
            ? DeviceSessionState.paused
            : state.value,
      );
    }
  }

  /// 在 Repository 或 BLE 事件到达后更新会话状态。
  void updateState(DeviceSessionState nextState) {
    _stateRevision++;
    if (state.value == nextState) {
      return;
    }
    state.value = nextState;
  }

  /// 暂停运行中的会话，或恢复已暂停的会话。
  void togglePause() {
    if (_programPlayback?.editing == true) return;
    if (_programPlayback?.active == true) {
      unawaited(activateQuickControl());
      return;
    }
    if (state.value == DeviceSessionState.running ||
        state.value == DeviceSessionState.paused) {
      unawaited(activateQuickControl());
    }
  }

  /// 悬浮控制条主点击激活入口：
  /// - 运行中（running / runningLowBattery）：发送暂停指令并置为 paused；
  /// - 暂停或待启动（paused / idle）：发送继续/启动指令并置为 running。
  Future<void> activateQuickControl() async {
    final playback = _programPlayback;
    if (playback?.editing == true) return;
    if (playback?.active == true) {
      if (playback!.snapshot.phase == DeviceProgramPlaybackPhase.running) {
        await playback.pause();
      } else {
        await playback.resume();
      }
      return;
    }
    final previous = state.value;
    final pausing = previous == DeviceSessionState.running;
    updateState(
      pausing ? DeviceSessionState.paused : DeviceSessionState.running,
    );
    final revision = _stateRevision;
    final remoteId = _bleCoordinator?.connectedRemoteId;
    final succeeded = pausing ? await sendPause() : await sendResume();
    // 失败只回滚本次乐观状态，不覆盖后到的遥测、序列或其他快捷操作。
    if (!succeeded &&
        revision == _stateRevision &&
        remoteId == _bleCoordinator?.connectedRemoteId) {
      updateState(previous);
    }
  }

  /// 向当前连接设备发送暂停指令。
  Future<bool> sendPause() async {
    if (_programPlayback?.active == true) {
      return _programPlayback!.pause();
    }
    final repository = _commandRepository;
    if (repository == null) return true;

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
    return result.isSuccess;
  }

  /// 向当前连接设备发送恢复/开始运行指令。
  Future<bool> sendResume() async {
    if (_programPlayback?.editing == true) return false;
    if (_programPlayback?.active == true) {
      return _programPlayback!.resume();
    }
    final repository = _commandRepository;
    if (repository == null) return true;

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
    return result.isSuccess;
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
    unawaited(_programSubscription?.cancel());
    unawaited(_telemetrySubscription?.cancel());
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
