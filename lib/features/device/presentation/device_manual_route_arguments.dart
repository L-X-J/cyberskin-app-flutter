// 设备说明书路由的展示参数：保留来源页面已有的设备名称，不承担领域加载。

/// 进入产品说明书时可携带的展示参数。
///
/// 型号 ID 仍由路由 path 提供并由 Binding 校验；[productName] 仅用于在后台
/// 手册没有名称时保持来源设备的真实展示名称。
final class DeviceManualRouteArguments {
  /// 创建说明书展示参数。
  const DeviceManualRouteArguments({this.productName});

  /// 来源设备或绑定记录提供的展示名称。
  final String? productName;
}
