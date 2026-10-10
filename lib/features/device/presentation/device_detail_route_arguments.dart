// 设备详情路由参数：只携带入口卡片已有的展示信息。
import '../domain/repositories/device_catalog_repository.dart';

/// 设备详情页面的非领域路由参数。
final class DeviceDetailRouteArguments {
  /// 创建设备详情路由参数。
  const DeviceDetailRouteArguments({required this.modelId, this.summary});

  /// 后台设备型号主键。
  final int modelId;

  /// 入口卡片已加载的摘要，用于首帧和 Hero 动画，不替代详情接口。
  final DeviceModelSummary? summary;
}
