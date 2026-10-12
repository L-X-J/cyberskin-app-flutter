import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_typography.dart';
import '../device_manual_controller.dart';

/// 加载失败时覆盖在页面上方的错误提示层；有数据时自动隐藏。
final class DeviceManualStatusOverlay extends StatelessWidget {
  /// 创建 [DeviceManualStatusOverlay]。
  const DeviceManualStatusOverlay({required this.controller, super.key});

  /// 说明书页面控制器。
  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final hasData =
        controller.detail.value != null || controller.manual.value != null;
    final failure = controller.failure.value;
    if (hasData || failure == null) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x22000000),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  failure.message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: controller.reload,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}
