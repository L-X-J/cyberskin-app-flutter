// 视频页路由级依赖装配。
import 'package:get/get.dart';

import '../domain/repositories/video_repository.dart';
import 'video_controller.dart';

/// 注册视频页 Controller。
final class VideoBinding extends Bindings {
  /// 创建视频绑定。
  VideoBinding();

  @override
  void dependencies() {
    Get.put<VideoController>(VideoController(Get.find<VideoRepository>()));
  }
}
