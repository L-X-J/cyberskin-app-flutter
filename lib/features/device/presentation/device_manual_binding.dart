// 设备说明书路由的局部依赖装配。
import 'package:get/get.dart';

import '../domain/repositories/device_catalog_repository.dart';
import 'device_manual_controller.dart';
import 'device_manual_route_arguments.dart';

/// 设备说明书页面的路由绑定。
final class DeviceManualBinding extends Bindings {
  /// 创建设备说明书绑定。
  DeviceManualBinding();

  @override
  void dependencies() {
    final modelId = int.tryParse(Get.parameters['modelId'] ?? '');
    if (modelId == null || modelId <= 0) {
      return;
    }
    final arguments = Get.arguments;
    final routeModelId = arguments is DeviceManualRouteArguments
        ? arguments.modelId
        : modelId;
    final routeSummary = arguments is DeviceManualRouteArguments
        ? arguments.summary
        : null;
    Get.put<DeviceManualController>(
      DeviceManualController(
        Get.find<DeviceCatalogRepository>(),
        modelId: routeModelId,
        summary: routeSummary,
      ),
    );
  }
}
