// 设备产品说明书路由的局部依赖装配与型号参数解析。
import 'package:get/get.dart';

import '../domain/repositories/device_catalog_repository.dart';
import 'device_manual_controller.dart';
import 'device_manual_route_arguments.dart';

/// 产品说明书页面路由级依赖绑定。
final class DeviceManualBinding extends Bindings {
  /// 创建说明书绑定。
  DeviceManualBinding();

  @override
  void dependencies() {
    final modelId = int.tryParse(Get.parameters['modelId'] ?? '');
    if (modelId == null || modelId <= 0) {
      return;
    }
    final arguments = Get.arguments;
    final productName = arguments is DeviceManualRouteArguments
        ? arguments.productName
        : null;
    Get.put<DeviceManualController>(
      DeviceManualController(
        Get.find<DeviceCatalogRepository>(),
        modelId: modelId,
        productName: productName,
      ),
    );
  }
}
