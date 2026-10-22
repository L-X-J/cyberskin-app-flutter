// 将 BLE 状态通知与原生后台运行能力适配为节奏领域端口。
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/result/result.dart';
import '../../../core/storage/session_credential_store.dart';
import '../../control/domain/device_command_repository.dart';
import '../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../domain/repositories/rhythm_device_port.dart';

/// 把已连接设备、每次状态通知与后台服务组合为执行端口。
final class BleRhythmDevicePort implements RhythmDevicePort {
  /// 创建实例；依赖及初始状态由调用方提供。
  BleRhythmDevicePort(
    this.coordinator,
    this.commands,
    SessionCredentialStore credentials,
  ) {
    _worker = ever(
      coordinator.connectedDevice,
      (_) => _events.add(RhythmDeviceEvent(target)),
    );
    _heartbeat = coordinator.rhythmHeartbeats.listen((remoteId) {
      if (target?.remoteId == remoteId) {
        _events.add(RhythmDeviceEvent(target, heartbeat: true));
      }
    });
    _credentials = credentials.invalidated.listen(
      (_) => _events.add(RhythmDeviceEvent(target, sessionExpired: true)),
    );
  }

  /// 共享 BLE 连接及通知来源，不创建第二条连接。
  final CyberskinBleRuntimeCoordinator coordinator;

  /// 原始语义命令通道，由执行器统一串行调度。
  final DeviceCommandRepository commands;
  static const _channel = MethodChannel('cyberskin/rhythm_background');
  final _events = StreamController<RhythmDeviceEvent>.broadcast(sync: true);
  late final Worker _worker;
  late final StreamSubscription<String> _heartbeat;
  late final StreamSubscription<void> _credentials;
  @override
  RhythmDeviceTarget? get target {
    final connected = coordinator.connectedDevice.value;
    final model = coordinator.connectedModelId;
    if (connected == null || model == null || !coordinator.hasConnectedDevice) {
      return null;
    }
    return RhythmDeviceTarget(
      modelId: model,
      remoteId: connected.remoteId,
      name: connected.device.name,
    );
  }

  @override
  Stream<RhythmDeviceEvent> get events => _events.stream;
  @override
  Future<Result<void>> send(String command, RhythmDeviceTarget target) =>
      commands.send(
        command,
        modelId: target.modelId,
        remoteId: target.remoteId,
      );
  @override
  Future<void> startBackground() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('start');
    }
  }

  @override
  Future<void> stopBackground() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('stop');
    }
  }

  /// 取消订阅并释放本实例拥有的资源。
  Future<void> dispose() async {
    _worker.dispose();
    await _heartbeat.cancel();
    await _credentials.cancel();
    await _events.close();
  }
}
