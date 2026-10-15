// 设备标签页空状态、加载中与错误重试视图组件。
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/material.dart';

import '../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import 'compact_glass_button.dart';

/// 页面加载设备数据时的首屏等待状态。
final class HomeDeviceLoadingState extends StatelessWidget {
  /// 创建设备加载中状态组件。
  const HomeDeviceLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.secondary),
    );
  }
}

/// 设备列表为空时展示的引导状态，支持展示附近发现的待确认设备。
final class HomeEmptyDeviceState extends StatelessWidget {
  /// 创建设备空状态组件。
  const HomeEmptyDeviceState({
    super.key,
    required this.pending,
    required this.onConfirm,
    required this.onDismiss,
    required this.onAdd,
  });

  /// 扫描到的待确认目标设备；为空时不渲染附近设备卡片。
  final BleDiscoveredDevice? pending;

  /// 确认连接发现的设备回调。
  final VoidCallback onConfirm;

  /// 忽略/取消发现的设备回调。
  final VoidCallback onDismiss;

  /// 开始搜索或添加设备回调。
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pending != null) ...[
              HomeNearbyDeviceCard(
                device: pending!,
                onConfirm: onConfirm,
                onDismiss: onDismiss,
              ),
              const SizedBox(height: 24),
            ],
            const Icon(
              Icons.bluetooth_disabled_outlined,
              size: 64,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: 20),
            const Text('No devices yet', style: AppTypography.subtitle),
            const SizedBox(height: 8),
            const Text(
              'Add a Cyberskin device to start controlling it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppLiquidGlassButton(
              label: 'Add device',
              icon: Icons.add,
              onPressed: onAdd,
              variant: AppLiquidGlassButtonVariant.highlighted,
              height: 48,
              iconSize: 18,
              textStyle: AppTypography.confirmButton,
            ),
          ],
        ),
      ),
    );
  }
}

/// 扫描到附近待连接设备时的提示卡片。
final class HomeNearbyDeviceCard extends StatelessWidget {
  /// 创建附近设备展示卡片。
  const HomeNearbyDeviceCard({
    super.key,
    required this.device,
    required this.onConfirm,
    required this.onDismiss,
  });

  /// 扫描到的设备信息。
  final BleDiscoveredDevice device;

  /// 点击连接回调。
  final VoidCallback onConfirm;

  /// 点击忽略回调。
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nearby device', style: AppTypography.subtitle),
            const SizedBox(height: 4),
            Text(device.name.isEmpty ? device.remoteId : device.name),
            const SizedBox(height: 4),
            Text(
              'Signal ${device.rssi} dBm',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CompactGlassButton(
                    label: 'Connect',
                    onPressed: onConfirm,
                    width: 100,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CompactGlassButton(
                    label: 'Dismiss',
                    onPressed: onDismiss,
                    width: 100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 设备加载失败且无本地缓存时的重试状态。
final class HomeDeviceErrorState extends StatelessWidget {
  /// 创建设备错误状态组件。
  const HomeDeviceErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  /// 错误提示消息。
  final String message;

  /// 重试回调。
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.errorLight,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            AppLiquidGlassButton(
              label: 'Try again',
              onPressed: onRetry,
              variant: AppLiquidGlassButtonVariant.subtle,
              height: 48,
              textStyle: AppTypography.confirmButton,
            ),
          ],
        ),
      ),
    );
  }
}
