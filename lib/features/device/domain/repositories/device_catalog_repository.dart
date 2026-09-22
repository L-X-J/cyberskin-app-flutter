// 设备型号目录的领域模型与远端访问抽象。
import '../../../../core/result/result.dart';

/// 后台发布的设备型号摘要。
final class DeviceModelSummary {
  /// 创建设备型号摘要。
  const DeviceModelSummary({
    this.id,
    this.name,
    this.iconUrl,
    this.displayBackgroundUrl,
    this.hardwareUid,
  });

  /// 设备型号主键。
  final int? id;

  /// 设备型号展示名称。
  final String? name;

  /// 图标地址。
  final String? iconUrl;

  /// 展示底图地址。
  final String? displayBackgroundUrl;

  /// 硬件唯一标识。
  final String? hardwareUid;
}

/// 设备型号详情中的 BLE 连接参数。
final class DeviceBleConfiguration {
  /// 创建 BLE 配置，并保留未知扩展字段。
  DeviceBleConfiguration({
    this.type,
    this.readService,
    this.readCharacteristic,
    this.writeService,
    this.writeCharacteristic,
    this.extensionLockEnabled = false,
    Map<String, dynamic> additionalProperties = const <String, dynamic>{},
  }) : additionalProperties = Map<String, dynamic>.unmodifiable(
         additionalProperties,
       );

  /// 开放的 BLE 类型标识。
  final String? type;

  /// 读取服务 UUID。
  final String? readService;

  /// 读取特征 UUID。
  final String? readCharacteristic;

  /// 写入服务 UUID。
  final String? writeService;

  /// 写入特征 UUID。
  final String? writeCharacteristic;

  /// 是否启用扩展联合锁定；缺失字段按 false 处理。
  final bool extensionLockEnabled;

  /// 未被当前协议稳定定义的字段。
  final Map<String, dynamic> additionalProperties;
}

/// 后台发布的设备型号详情。
final class DeviceModelDetail {
  /// 创建设备型号详情。
  DeviceModelDetail({
    required this.summary,
    this.hardwareExtensionUid,
    Map<String, dynamic>? lockRule,
    this.ble,
    List<Map<String, dynamic>> supportedActions =
        const <Map<String, dynamic>>[],
    this.heatSupported = false,
    List<int> heatLevels = const <int>[],
    Map<String, dynamic>? layout,
    Map<String, dynamic>? oneClickClimax,
    this.layoutVersion,
    Map<String, dynamic> additionalProperties = const <String, dynamic>{},
  }) : supportedActions = List<Map<String, dynamic>>.unmodifiable(
         supportedActions.map(Map<String, dynamic>.unmodifiable),
       ),
       heatLevels = List<int>.unmodifiable(heatLevels),
       lockRule = lockRule == null
           ? null
           : Map<String, dynamic>.unmodifiable(lockRule),
       layout = layout == null
           ? null
           : Map<String, dynamic>.unmodifiable(layout),
       oneClickClimax = oneClickClimax == null
           ? null
           : Map<String, dynamic>.unmodifiable(oneClickClimax),
       additionalProperties = Map<String, dynamic>.unmodifiable(
         additionalProperties,
       );

  /// 共享的型号摘要字段。
  final DeviceModelSummary summary;

  /// 硬件扩展标识。
  final String? hardwareExtensionUid;

  /// 开放的设备锁定规则配置。
  final Map<String, dynamic>? lockRule;

  /// BLE 连接参数。
  final DeviceBleConfiguration? ble;

  /// 开放的能力操作协议列表。
  final List<Map<String, dynamic>> supportedActions;

  /// 是否支持加热；缺失字段按 false 处理。
  final bool heatSupported;

  /// 后台配置的加热档位。
  final List<int> heatLevels;

  /// 开放的控制布局协议。
  final Map<String, dynamic>? layout;

  /// 开放的一键高潮协议。
  final Map<String, dynamic>? oneClickClimax;

  /// 后台布局版本。
  final int? layoutVersion;

  /// 未知详情字段，供前向兼容诊断使用。
  final Map<String, dynamic> additionalProperties;
}

/// 单个设备说明书图文条目。
final class DeviceManualItem {
  /// 创建说明书条目，并保留开放字段。
  DeviceManualItem({
    this.id,
    this.tab,
    this.contentUrl,
    this.contentHtml,
    Map<String, dynamic> additionalProperties = const <String, dynamic>{},
  }) : additionalProperties = Map<String, dynamic>.unmodifiable(
         additionalProperties,
       );

  /// 说明书条目主键。
  final int? id;

  /// 开放的说明书分类字符串。
  final String? tab;

  /// 发布的 HTML 对象地址。
  final String? contentUrl;

  /// 服务端为兼容旧客户端回填的 HTML。
  final String? contentHtml;

  /// 未被静态 OpenAPI 细化的条目字段。
  final Map<String, dynamic> additionalProperties;
}

/// 设备型号的已发布说明书。
final class DeviceManual {
  /// 创建设备说明书。
  DeviceManual({
    this.deviceModelId,
    List<DeviceManualItem> items = const <DeviceManualItem>[],
  }) : items = List<DeviceManualItem>.unmodifiable(items);

  /// 关联设备型号主键。
  final int? deviceModelId;

  /// 按后台配置顺序展示的说明条目。
  final List<DeviceManualItem> items;
}

/// 设备型号目录的领域访问入口。
abstract interface class DeviceCatalogRepository {
  /// 获取已发布设备型号摘要。
  Future<Result<List<DeviceModelSummary>>> listDeviceModels();

  /// 获取一个设备型号的能力、布局与 BLE 详情。
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id);

  /// 获取一个设备型号的说明书。
  Future<Result<DeviceManual>> getManual(int id);
}
