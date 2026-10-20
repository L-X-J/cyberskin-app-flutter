import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/repositories/device_catalog_repository.dart';
import '../device_manual_controller.dart';
import '../device_manual_route_arguments.dart';

/// Obx 包裹层；从 controller 提取当前选中型号后交给 [DeviceManualProductHero]。
final class DeviceManualReactiveProductHero extends StatelessWidget {
  /// 创建 [DeviceManualReactiveProductHero]。
  const DeviceManualReactiveProductHero({
    required this.controller,
    required this.routeArgs,
    super.key,
  });

  /// 说明书页面控制器。
  final DeviceManualController controller;

  /// 路由参数，用于获取跳转前的型号封面图。
  final DeviceManualRouteArguments? routeArgs;

  @override
  Widget build(BuildContext context) => Obx(() {
    final model =
        controller.selectedModel.value ??
        controller.detail.value?.summary ??
        controller.summary ??
        const DeviceModelSummary(name: 'Cyberskin device');
    return DeviceManualProductHero(model: model, routeArgs: routeArgs);
  });
}

/// 产品主图英雄区域；包含产品图片、Hero 动画和底座装饰。
final class DeviceManualProductHero extends StatelessWidget {
  /// 创建 [DeviceManualProductHero]。
  const DeviceManualProductHero({
    required this.model,
    required this.routeArgs,
    super.key,
  });

  /// 当前展示的设备型号。
  final DeviceModelSummary model;

  /// 路由参数，用于获取跳转前的型号封面图。
  final DeviceManualRouteArguments? routeArgs;

  @override
  Widget build(BuildContext context) {
    final image =
        model.iconUrl ??
        routeArgs?.summary?.iconUrl ??
        _fallbackAsset(model.name);
    final heroTag = 'device-model-${model.id ?? 'unknown'}';
    return SizedBox(
      height: 238,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 54,
            right: 54,
            bottom: 14,
            height: 58,
            child: _ProductBase(),
          ),
          Positioned(
            top: 19,
            child: Hero(
              tag: heroTag,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: AppImage.load(
                  image,
                  key: ValueKey('${model.id}:$image'),
                  width: 188,
                  height: 188,
                  fit: BoxFit.contain,
                  placeholder: const _ProductPlaceholder(),
                  errorWidget: const _ProductPlaceholder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ardot 设计稿中的细椭圆产品底座。
final class _ProductBase extends StatelessWidget {
  const _ProductBase();

  @override
  Widget build(BuildContext context) => AppImage.load(
    'assets/images/device/device_detail_base.svg',
    width: 293,
    height: 58,
    fit: BoxFit.fill,
  );
}

final class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.devices_other_outlined,
    size: 52,
    color: AppColors.white80,
  );
}

String? _fallbackAsset(String? name) {
  final value = name?.toLowerCase() ?? '';
  if (value.contains('pro')) {
    return 'assets/images/home/device_pro_connected.png';
  }
  if (value.contains('air')) {
    return 'assets/images/home/device_air_connected.png';
  }
  return null;
}
