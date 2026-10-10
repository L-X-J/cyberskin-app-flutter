// 设备详情路由的局部依赖装配。
import 'package:get/get.dart';

import '../../content/domain/repositories/content_repository.dart';
import '../domain/repositories/device_catalog_repository.dart';
import 'device_detail_controller.dart';
import 'device_detail_route_arguments.dart';

/// 设备详情页面的路由绑定。
final class DeviceDetailBinding extends Bindings {
  /// 创建设备详情绑定。
  DeviceDetailBinding();

  @override
  void dependencies() {
    final modelId = int.tryParse(Get.parameters['modelId'] ?? '');
    if (modelId == null || modelId <= 0) {
      return;
    }
    final arguments = Get.arguments;
    final routeModelId = arguments is DeviceDetailRouteArguments
        ? arguments.modelId
        : modelId;
    final routeSummary = arguments is DeviceDetailRouteArguments
        ? arguments.summary
        : null;
    Get.put<DeviceDetailController>(
      DeviceDetailController(
        Get.find<DeviceCatalogRepository>(),
        modelId: routeModelId,
        summary: routeSummary,
        contentRepository: Get.find<ContentRepository>(),
      ),
    );
  }
}
