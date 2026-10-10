// 设备详情路由的局部依赖装配。
import 'package:get/get.dart';

import '../domain/repositories/device_catalog_repository.dart';
import 'device_detail_controller.dart';
import 'device_detail_route_arguments.dart';

/// 设备详情页面的路由绑定。
final class DeviceDetailBinding extends Bindings {
  /// 创建设备详情绑定。
  DeviceDetailBinding();

  @override
  void dependencies() {
    final arguments = Get.arguments;
    if (arguments is! DeviceDetailRouteArguments || arguments.modelId <= 0) {
      return;
    }
    Get.put<DeviceDetailController>(
      DeviceDetailController(
        Get.find<DeviceCatalogRepository>(),
        modelId: arguments.modelId,
        summary: arguments.summary,
      ),
    );
  }
}
