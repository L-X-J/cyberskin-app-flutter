import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_image.dart';
import '../device_manual_controller.dart';

/// Obx 包裹层；从 controller 提取广告图 URL 后交给 [DeviceManualAdvertisement]。
final class DeviceManualReactiveAdvertisement extends StatelessWidget {
  /// 创建 [DeviceManualReactiveAdvertisement]。
  const DeviceManualReactiveAdvertisement({
    required this.controller,
    required this.bottomPadding,
    super.key,
  });

  /// 说明书页面控制器。
  final DeviceManualController controller;

  /// 底部安全距离。
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Obx(() {
    final imageUrl = controller.detail.value?.advertisements
        .map((advertisement) => advertisement.imageUrl)
        .firstWhere(
          (value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 26, 24, bottomPadding),
      child: DeviceManualAdvertisement(imageUrl: imageUrl),
    );
  });
}

/// 页面底部的圆角广告横幅图片。
final class DeviceManualAdvertisement extends StatelessWidget {
  /// 创建 [DeviceManualAdvertisement]。
  const DeviceManualAdvertisement({required this.imageUrl, super.key});

  /// 广告图片远端地址。
  final String imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: AppImage.load(
      imageUrl,
      width: double.infinity,
      height: 138,
      fit: BoxFit.cover,
      errorWidget: const SizedBox.shrink(),
    ),
  );
}
