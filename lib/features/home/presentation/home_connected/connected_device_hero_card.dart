// 已连接状态下的设备主英雄卡片；展示设备状态、电量、标签与说明书入口。
import 'dart:async';

import 'package:cyberskin_app/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_layered_gradient_card.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../../device/domain/connected_device_state.dart';
import '../../../device/domain/device.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import '../../../device/presentation/device_manual_route_arguments.dart';
import 'compact_glass_button.dart';

/// 已连接设备主卡；展示设备名称、连接状态、实时电量、关机操作、标签与说明书入口。
///
/// 具备 3D perspective 绕 X 轴翻转落入动画；电量与充电状态优先订阅 [connectedState]
/// 的 Rx 响应式变量，未就绪时平滑退化为 [device] 快照数据。
final class ConnectedDeviceHeroCard extends StatelessWidget {
  /// 创建已连接设备主卡组件。
  const ConnectedDeviceHeroCard({
    super.key,
    required this.device,
    this.connectedState,
    required this.flipAnimation,
    required this.fadeAnimation,
    this.onPowerOff,
    this.onManual,
  });

  /// 对应的设备领域模型。
  final Device device;

  /// 连接设备的实时运行时视图；为 null 时优先从全局 BLE 协调器读取。
  final ConnectedDeviceState? connectedState;

  /// 翻转入场动画（-0.35π -> 0）。
  final Animation<double> flipAnimation;

  /// 淡入动画（0 -> 1）。
  final Animation<double> fadeAnimation;

  /// 关机回调。
  final VoidCallback? onPowerOff;

  /// 查看说明书回调；为空时采用默认路由导航。
  final VoidCallback? onManual;

  @override
  Widget build(BuildContext context) {
    final tags = _parseTags(device.tags);
    final modelId = int.tryParse(device.model.trim());
    final heroTag = 'device-model-${modelId ?? 'unknown'}';
    final image = (device.iconUrl != null && device.iconUrl!.isNotEmpty)
        ? device.iconUrl!
        : (_fallbackAsset(device.name) ??
            'assets/images/home/device_pro_connected.png');

    return AnimatedBuilder(
      animation: flipAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0008)
            ..rotateX(flipAnimation.value),
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      child: Stack(
        children: [
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: AppLayeredGradientCard.scan(
              height: 179,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bluetooth_connected,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: AppTypography.size14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _buildBatteryButton(),
                            const SizedBox(width: 8),
                            CompactGlassButton(
                              label: 'Power',
                              icon: Icons.power_settings_new,
                              onPressed: onPowerOff,
                              width: 38,
                              iconOnly: true,
                            ),
                          ],
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            tags.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppTypography.size10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        _buildManualButton(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: AppImage.load(
              'assets/images/home/device_pro_connected.png',
              fit: BoxFit.contain,
              semanticLabel: device.name,
              width: 182,
              placeholder: const DeviceImagePlaceholder(),
              errorWidget: const DeviceImagePlaceholder(),
            ),
          ),
          const SizedBox(height: 194),
        ],
      ),
    );
  }

  /// 构建电量信息按钮；优先订阅实时 Rx 字段，未就绪时退化为设备模型快照。
  Widget _buildBatteryButton() {
    final coordinator = Get.isRegistered<CyberskinBleRuntimeCoordinator>()
        ? Get.find<CyberskinBleRuntimeCoordinator>()
        : null;
    final activeState = connectedState ?? coordinator?.connectedDevice.value;

    if (activeState != null) {
      return Obx(() {
        final level = activeState.batteryLevel.value;
        final isCharging = activeState.isCharging.value;
        final label = level >= 0 ? '$level%${isCharging ? ' ⚡' : ''}' : '--';
        return CompactGlassButton(
          label: label,
          iconWidget: AppImage.load('home/Battery-charge'.assetsPng, width: 24),
          onPressed: () {},
        );
      });
    }

    final fallbackLevel = device.batteryPercent;
    final fallbackLabel = fallbackLevel != null && fallbackLevel >= 0
        ? '$fallbackLevel%'
        : '--';

    return CompactGlassButton(
      label: fallbackLabel,
      iconWidget: AppImage.load('home/Battery-charge'.assetsPng, width: 24),
      onPressed: () {},
    );
  }

  /// 构建产品说明书操作按钮。
  Widget _buildManualButton(BuildContext context) {
    final modelId = int.tryParse(device.model.trim());
    final manualEnabled = modelId != null;

    return AppLiquidGlassButton(
      label: manualEnabled ? 'Product manual' : 'Manual unavailable',
      leadingIcon: Icons.description_outlined,
      iconSize: 12,
      onPressed: manualEnabled
          ? () {
              if (onManual != null) {
                onManual!();
              } else {
                unawaited(
                  Get.toNamed(
                    AppRoutes.deviceManual.replaceFirst(':modelId', '$modelId'),
                    arguments: DeviceManualRouteArguments(modelId: modelId),
                  ),
                );
              }
            }
          : null,
      variant: AppLiquidGlassButtonVariant.translucent,
      width: 132,
      height: 24,
      borderRadius: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(
        fontSize: AppTypography.size12,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// 设备图片缺失时使用的稳定占位，保证 Hero 仍保留视觉锚点。
final class DeviceImagePlaceholder extends StatelessWidget {
  /// 创建设备图片占位组件。
  const DeviceImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.devices_other_outlined,
        size: 46,
        color: AppColors.white80,
      ),
    );
  }
}

/// 将后台逗号分隔的标签字符串转换为不可变列表。
List<String> _parseTags(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const <String>[];
  }
  return raw
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}
