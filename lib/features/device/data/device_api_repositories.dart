// 设备目录与用户绑定 App API 的远端 Repository 实现。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../domain/repositories/device_catalog_repository.dart';
import '../domain/repositories/user_device_repository.dart';

/// DeviceCatalogRepository 的 App API 实现。
final class DeviceCatalogRemoteRepository extends BaseRemoteRepository
    implements DeviceCatalogRepository {
  /// 创建设备目录远端 Repository。
  DeviceCatalogRemoteRepository({
    required super.transport,
    required super.sessionStore,
  });

  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() =>
      request<List<DeviceModelSummary>>(
        AppApiOperation.listDeviceModels,
        decode: (data) =>
            ApiJson.objectList(data)
                .map(_decodeSummary)
                .toList(growable: false),
      );

  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) =>
      request<DeviceModelDetail>(
        AppApiOperation.deviceModelDetail,
        pathParameters: <String, Object?>{'id': id},
        decode: _decodeDetail,
      );

  @override
  Future<Result<DeviceManual>> getManual(int id) => request<DeviceManual>(
    AppApiOperation.deviceManual,
    pathParameters: <String, Object?>{'id': id},
    decode: _decodeManual,
  );

  /// 解码设备目录和详情复用的型号摘要字段。
  DeviceModelSummary _decodeSummary(Map<String, dynamic> json) =>
      DeviceModelSummary(
        id: ApiJson.integer(json, 'id'),
        name: ApiJson.string(json, 'name'),
        iconUrl: ApiJson.string(json, 'iconUrl'),
        displayBackgroundUrl: ApiJson.string(json, 'displayBgUrl'),
        hardwareUid: ApiJson.string(json, 'hwUid'),
        cardColor: ApiJson.string(json, 'cardColor'),
        tags: ApiJson.string(json, 'tags'),
      );

  /// 解码设备详情，并冻结设备协议中尚未稳定化的开放配置字段。
  DeviceModelDetail _decodeDetail(Object? data) {
    final json = ApiJson.object(data);
    final bleJson = json['ble'];
    final actions = json['supportedActions'];
    final heatLevels = json['heatLevels'];
    return DeviceModelDetail(
      summary: _decodeSummary(json),
      hardwareExtensionUid: ApiJson.string(json, 'hwExtUid'),
      lockRule: _optionalObject(json['lockRule']),
      ble: bleJson == null
          ? null
          : DeviceBleConfiguration(
              type: ApiJson.string(
                ApiJson.object(bleJson, field: 'ble'),
                'type',
              ),
              readService: ApiJson.string(
                ApiJson.object(bleJson, field: 'ble'),
                'readService',
              ),
              readCharacteristic: ApiJson.string(
                ApiJson.object(bleJson, field: 'ble'),
                'readChar',
              ),
              writeService: ApiJson.string(
                ApiJson.object(bleJson, field: 'ble'),
                'writeService',
              ),
              writeCharacteristic: ApiJson.string(
                ApiJson.object(bleJson, field: 'ble'),
                'writeChar',
              ),
              extensionLockEnabled:
                  ApiJson.boolean(
                    ApiJson.object(bleJson, field: 'ble'),
                    'extLockEnabled',
                  ) ??
                  false,
              additionalProperties: ApiJson.additionalProperties(
                ApiJson.object(bleJson, field: 'ble'),
                <String>{
                  'type',
                  'readService',
                  'readChar',
                  'writeService',
                  'writeChar',
                  'extLockEnabled',
                },
              ),
            ),
      supportedActions: actions == null
          ? const <Map<String, dynamic>>[]
          : ApiJson.objectList(actions, field: 'supportedActions'),
      heatSupported: ApiJson.boolean(json, 'heatSupported') ?? false,
      heatLevels: heatLevels == null
          ? const <int>[]
          : (heatLevels as List)
                .map((item) {
                  if (item is int) {
                    return item;
                  }
                  if (item is num && item == item.roundToDouble()) {
                    return item.toInt();
                  }
                  throw const FormatException('heatLevels 必须为整数列表。');
                })
                .toList(growable: false),
      layout: _optionalObject(json['layout']),
      oneClickClimax: _optionalObject(json['oneClickClimax']),
      layoutVersion: ApiJson.integer(json, 'layoutVersion'),
      additionalProperties: ApiJson.additionalProperties(json, <String>{
        'id',
        'name',
        'iconUrl',
        'displayBgUrl',
        'hwUid',
        'cardColor',
        'tags',
        'hwExtUid',
        'lockRule',
        'ble',
        'supportedActions',
        'heatSupported',
        'heatLevels',
        'layout',
        'oneClickClimax',
        'layoutVersion',
      }),
    );
  }

  /// 解码按后端排序返回的设备说明书条目。
  DeviceManual _decodeManual(Object? data) {
    final json = ApiJson.object(data);
    final rawItems = json['items'];
    return DeviceManual(
      deviceModelId: ApiJson.integer(json, 'deviceModelId'),
      items: rawItems == null
          ? const <DeviceManualItem>[]
          : ApiJson.objectList(rawItems, field: 'items')
                .map(
                  (item) => DeviceManualItem(
                    id: ApiJson.integer(item, 'id'),
                    tab: ApiJson.string(item, 'tab'),
                    contentUrl: ApiJson.string(item, 'contentUrl'),
                    contentHtml: ApiJson.string(item, 'contentHtml'),
                    additionalProperties: ApiJson.additionalProperties(
                      item,
                      <String>{'id', 'tab', 'contentUrl', 'contentHtml'},
                    ),
                  ),
                )
                .toList(growable: false),
    );
  }

  /// 深拷贝可选开放对象，避免领域模型持有可变的传输层 Map。
  Map<String, dynamic>? _optionalObject(Object? value) => value == null
      ? null
      : Map<String, dynamic>.unmodifiable(ApiJson.object(value));
}

/// UserDeviceRepository 的 App API 实现。
final class UserDeviceRemoteRepository extends BaseRemoteRepository
    implements UserDeviceRepository {
  /// 创建用户设备远端 Repository。
  UserDeviceRemoteRepository({
    required super.transport,
    required super.sessionStore,
  });

  @override
  Future<Result<List<UserDevice>>> listUserDevices() =>
      request<List<UserDevice>>(
        AppApiOperation.listUserDevices,
        decode: (data) =>
            ApiJson.objectList(data)
                .map(_decodeUserDevice)
                .toList(growable: false),
      );

  @override
  Future<Result<UserDevice>> bind(UserDeviceBindRequest request) =>
      this.request<UserDevice>(
        AppApiOperation.bindUserDevice,
        body: <String, Object?>{
          'deviceModelId': request.deviceModelId,
          if (request.customName != null) 'customName': request.customName,
        },
        decode: (data) => _decodeUserDevice(ApiJson.object(data)),
      );

  @override
  Future<Result<void>> rename(int id, String customName) => requestVoid(
    AppApiOperation.renameUserDevice,
    pathParameters: <String, Object?>{'id': id},
    body: <String, Object?>{'customName': customName},
  );

  @override
  Future<Result<void>> unbind(int id) => requestVoid(
    AppApiOperation.unbindUserDevice,
    pathParameters: <String, Object?>{'id': id},
  );

  /// 解码用户绑定记录及其关联型号摘要。
  UserDevice _decodeUserDevice(Map<String, dynamic> json) => UserDevice(
    id: ApiJson.integer(json, 'id'),
    deviceModelId: ApiJson.integer(json, 'deviceModelId'),
    customName: ApiJson.string(json, 'customName'),
    boundAt: _dateTime(ApiJson.string(json, 'boundAt')),
    modelName: ApiJson.string(json, 'name'),
    iconUrl: ApiJson.string(json, 'iconUrl'),
    hardwareUid: ApiJson.string(json, 'hwUid'),
  );

  /// 解码可选 ISO-8601 绑定时间，拒绝已经提供但格式错误的数据。
  DateTime? _dateTime(String? value) {
    if (value == null) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const FormatException('日期字段格式无效。');
    }
    return parsed.toUtc();
  }
}
