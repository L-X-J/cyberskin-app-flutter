// 将 BLE 状态通知与原生后台运行能力适配为公共播放端口。
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/result/result.dart';
import '../../../core/storage/session_credential_store.dart';
import '../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../domain/device_command_repository.dart';
import '../domain/repositories/device_playback_port.dart';

/// 把已连接设备、每次状态通知与后台服务组合为执行端口。
final class BleDevicePlaybackPort implements DevicePlaybackPort {
  /// 创建实例；依赖及初始状态由调用方提供。
  BleDevicePlaybackPort(
    this.coordinator,
    this.commands,
    SessionCredentialStore credentials,
  ) {
    _worker = ever(
      coordinator.connectedDevice,
      (_) => _events.add(DevicePlaybackEvent(target)),
    );
    _heartbeat = coordinator.rhythmHeartbeats.listen((remoteId) {
      if (target?.remoteId == remoteId) {
        _events.add(DevicePlaybackEvent(target, heartbeat: true));
      }
    });
    _credentials = credentials.invalidated.listen(
      (_) => _events.add(DevicePlaybackEvent(target, sessionExpired: true)),
    );
  }

  /// 共享 BLE 连接及通知来源，不创建第二条连接。
  final CyberskinBleRuntimeCoordinator coordinator;

  /// 原始语义命令通道，由执行器统一串行调度。
  final DeviceCommandRepository commands;
  // 沿用现有原生通道名；节奏与 Training 共用这一份后台服务。
  static const _channel = MethodChannel('cyberskin/rhythm_background');
  final _events = StreamController<DevicePlaybackEvent>.broadcast(sync: true);
  late final Worker _worker;
  late final StreamSubscription<String> _heartbeat;
  late final StreamSubscription<void> _credentials;
  @override
  DevicePlaybackTarget? get target {
    final connected = coordinator.connectedDevice.value;
    final model = coordinator.connectedModelId;
    if (connected == null || model == null || !coordinator.hasConnectedDevice) {
      return null;
    }
    return DevicePlaybackTarget(
      modelId: model,
      remoteId: connected.remoteId,
      name: connected.device.name,
    );
  }

  @override
  Stream<DevicePlaybackEvent> get events => _events.stream;
  @override
  Future<Result<void>> send(String command, DevicePlaybackTarget target) =>
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
