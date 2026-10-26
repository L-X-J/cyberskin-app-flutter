// 用户绑定设备与 BLE 运行态的领域 Repository 实现。
import '../../../core/result/result.dart';
import '../domain/device.dart';
import '../domain/device_capability.dart';
import '../domain/device_repository.dart';

import '../domain/repositories/device_catalog_repository.dart';
import '../domain/repositories/user_device_repository.dart';
import 'cyberskin_ble_runtime_coordinator.dart';

/// 将后端用户设备绑定、设备目录和 SDK 运行态合并成页面可消费的设备摘要。
final class ConnectedDeviceRepository implements DeviceRepository {
  ConnectedDeviceRepository({
    required UserDeviceRepository userDeviceRepository,
    required DeviceCatalogRepository catalogRepository,
    required CyberskinBleRuntimeCoordinator bleCoordinator,
  }) : _userDeviceRepository = userDeviceRepository,
       _catalogRepository = catalogRepository,
       _bleCoordinator = bleCoordinator;

  final UserDeviceRepository _userDeviceRepository;
  final DeviceCatalogRepository _catalogRepository;
  final CyberskinBleRuntimeCoordinator _bleCoordinator;

  @override
  Future<Result<List<Device>>> loadDevices() async {
    final boundResult = await _userDeviceRepository.listUserDevices();
    final boundDevices = boundResult.valueOrNull;
    // 绑定记录是账号元数据，不能作为物理连接是否存在的判据。
    final connectedRemoteId = _bleCoordinator.connectedRemoteId;
    final connectedModelId = _bleCoordinator.connectedModelId;
    if (_bleCoordinator.hasConnectedDevice &&
        connectedRemoteId != null &&
        connectedModelId != null) {
      final detailResult = await _catalogRepository.getDeviceModelDetail(
        connectedModelId,
      );
      // 查询期间可能退出或切换设备，旧详情不得恢复失效的设备视图。
      if (!_bleCoordinator.hasConnectedDevice ||
          _bleCoordinator.connectedRemoteId != connectedRemoteId ||
          _bleCoordinator.connectedModelId != connectedModelId) {
        return const Result.ok([]);
      }
      final detail = detailResult.valueOrNull;
      if (detail != null) {
        UserDevice? metadata;
        for (final bound in boundDevices ?? const <UserDevice>[]) {
          if (bound.deviceModelId == connectedModelId) {
            metadata = bound;
            break;
          }
        }
        final battery = _bleCoordinator.connectedRuntime?.batteryLevel;
        return Result.ok([
          Device(
            id: metadata?.id?.toString() ?? connectedRemoteId,
            model: '$connectedModelId',
            name:
                metadata?.customName ??
                detail.summary.name ??
                metadata?.modelName ??
                'Device',
            status: DeviceConnectionStatus.connected,
            batteryPercent: battery != null && battery >= 0 && battery <= 100
                ? battery
                : null,
            capabilities: _capabilities(detail),
            cardColor: detail.summary.cardColor,
            tags: detail.summary.tags,
            iconUrl: metadata?.iconUrl ?? detail.summary.iconUrl,
            hardwareUid: metadata?.hardwareUid ?? detail.summary.hardwareUid,
          ),
        ]);
      }
      final snapshot = _bleCoordinator.connectedDevice.value;
      if (snapshot != null) return Result.ok([snapshot.device]);
      return Result.failure(detailResult.failureOrNull!);
    }
    if (boundDevices == null) {
      return Result.failure(boundResult.failureOrNull!);
    }
    final devices = <Device>[];
    for (final bound in boundDevices) {
      final modelId = bound.deviceModelId;
      if (modelId == null) continue;
      final detailResult = await _catalogRepository.getDeviceModelDetail(
        modelId,
      );
      final detail = detailResult.valueOrNull;
      if (detail == null) continue;
      final profile = _bleCoordinator.profileForModel(modelId);
      final connected = profile == null
          ? false
          : _bleCoordinator.hasConnectedDevice;
      final runtime = connected ? _bleCoordinator.connectedRuntime : null;
      final battery = runtime?.batteryLevel;
      devices.add(
        Device(
          id: '${bound.id ?? modelId}',
          model: '$modelId',
          name:
              bound.customName ??
              bound.modelName ??
              detail.summary.name ??
              'Device',
          status: connected
              ? DeviceConnectionStatus.connected
              : DeviceConnectionStatus.disconnected,
          batteryPercent: battery != null && battery >= 0 && battery <= 100
              ? battery
              : null,
          capabilities: _capabilities(detail),
          cardColor: detail.summary.cardColor,
          tags: detail.summary.tags,
          iconUrl: bound.iconUrl ?? detail.summary.iconUrl,
          hardwareUid: bound.hardwareUid ?? detail.summary.hardwareUid,
        ),
      );
    }
    return Result.ok(List.unmodifiable(devices));
  }

  DeviceCapabilities _capabilities(DeviceModelDetail detail) {
    final channels = <ChannelCapability>[];
    for (final action in detail.supportedActions) {
      final code = action['code']?.toString().toLowerCase();
      final channel = switch (code) {
        'thrust' || 'telescopic' => DeviceChannel.telescopic,
        'vibration' || 'vibrate' => DeviceChannel.vibration,
        'suck' || 'suction' => DeviceChannel.suck,
        'heat' || 'heating' => DeviceChannel.heat,
        _ => null,
      };
      if (channel == null) continue;
      channels.add(
        ChannelCapability(
          channel: channel,
          gearMax: _int(action['gearMax']),
          defaultValue: _int(action['defaultValue']) ?? 0,
          variableSpeedSupported: action['variableSpeed'] == true,
        ),
      );
    }
    return DeviceCapabilities(channels: channels);
  }

  int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value');
}
