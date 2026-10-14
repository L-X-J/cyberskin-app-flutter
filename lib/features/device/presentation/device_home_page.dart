// 设备标签页入口页面；内容体已提取到 home_connected_view.dart 供首页 Shell 复用。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../home/presentation/home_connected/home_connected_view.dart';
import 'device_home_controller.dart';

/// 设备标签页入口页面。
final class DeviceHomePage extends GetView<DeviceHomeController> {
  /// 创建设备主页。
  const DeviceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: true,
    );
    return AppScaffold(
      currentTab: AppTab.home,
      appBar: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      body: DeviceBodyContent(
        controller: controller,
        topInset: topInset,
        bottomInset: bottomInset,
      ),
    );
  }
}
