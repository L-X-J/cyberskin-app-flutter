// 设备标签页入口及设备列表的局部展示组件。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../domain/device.dart';
import 'device_home_controller.dart';

/// 设备标签页入口页面。
final class DeviceHomePage extends GetView<DeviceHomeController> {
  /// 创建设备主页。
  const DeviceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.home,
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          IconButton(
            onPressed: () => unawaited(Get.toNamed(AppRoutes.profile)),
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: _DeviceBody(controller: controller),
    );
  }
}

/// 仅此内容子树订阅设备列表状态，顶部栏、底部导航和全局控制条保持在观察范围外。
final class _DeviceBody extends StatelessWidget {
  const _DeviceBody({required this.controller});

  final DeviceHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final devices = controller.devices.toList(growable: false);
      final failure = controller.failure.value;
      final isLoading = controller.isLoading.value;
      if (isLoading && devices.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (failure != null && devices.isEmpty) {
        return _DeviceErrorState(
          message: failure.message,
          onRetry: () => unawaited(controller.reload()),
        );
      }
      if (devices.isEmpty) {
        return const _EmptyDeviceState();
      }
      return RefreshIndicator(
        onRefresh: controller.reload,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: devices.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _DeviceCard(device: devices[index]);
          },
        ),
      );
    });
  }
}

/// 设备列表为空时展示的引导状态。
final class _EmptyDeviceState extends StatelessWidget {
  const _EmptyDeviceState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'No devices yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a Cyberskin device to start controlling it.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add device'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设备加载失败且没有可展示缓存时使用的错误状态。
final class _DeviceErrorState extends StatelessWidget {
  const _DeviceErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// 单个设备的摘要卡片。
final class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final battery = device.batteryPercent;
    final cardColor = _parseColor(device.cardColor);
    final tags = _parseTags(device.tags);
    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Icon(
                  device.status == DeviceConnectionStatus.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${device.status.label} · ${device.status.guidance}'),
            if (battery != null) ...[
              const SizedBox(height: 8),
              Text('Battery $battery%'),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceFirst('#', '');
    final value = int.tryParse(
      clean.length == 6 ? 'FF$clean' : clean,
      radix: 16,
    );
    return value == null ? null : Color(value);
  }

  List<String> _parseTags(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String>[];
    return raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(growable: false);
  }
}
