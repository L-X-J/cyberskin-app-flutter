// 训练列表的页面级依赖；播放控制器在 AppBinding 注册，返回不会销毁会话。
import 'package:get/get.dart';

import '../../control/domain/services/device_program_playback.dart';
import '../../device/domain/repositories/user_device_repository.dart';
import '../domain/repositories/training_repository.dart';
import 'pages/home/training_home_controller.dart';

/// 训练列表的命名路由依赖绑定。
final class TrainingBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(
    () => TrainingHomeController(
      Get.find<TrainingRepository>(),
      Get.find<UserDeviceRepository>(),
      Get.find<DeviceProgramPlayback>().port,
    ),
  );
}
