// 视频独立路由壳层；主页内嵌与此路由共用同一标签内容实现。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import 'video_controller.dart';
import 'video_tab_content.dart';

export 'video_tab_content.dart';

/// 可匿名访问的视频页面。
final class VideoPage extends GetView<VideoController> {
  /// 创建独立视频路由。
  const VideoPage({super.key});

  /// 全屏仅改变壳层布局，不替换内容树和播放器。
  @override
  Widget build(BuildContext context) => Obx(
    () => AppScaffold(
      currentTab: AppTab.video,
      showBottomNavigation: !controller.isFullscreen.value,
      appBar: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      body: VideoTabContent(controller: controller),
    ),
  );
}
