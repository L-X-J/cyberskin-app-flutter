import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../device/domain/device.dart';
import 'home_controller.dart';

/// 匿名可浏览的应用主页。
final class HomePage extends GetView<HomeController> {
  /// 创建主页。
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.home,
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => unawaited(Get.toNamed<void>(AppRoutes.profile)),
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Obx(
        () => _HomeBody(
          status: controller.deviceStatus.value,
          isAuthenticated: controller.isAuthenticated,
          onPrimaryAction: controller.requestConnection,
          onDeviceDetails: controller.openDevice,
          onLogin: controller.openLogin,
        ),
      ),
    );
  }
}

/// 根据设备连接状态渲染主页主体，避免壳层订阅无关状态。
final class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.status,
    required this.isAuthenticated,
    required this.onPrimaryAction,
    required this.onDeviceDetails,
    required this.onLogin,
  });

  final DeviceConnectionStatus status;
  final bool isAuthenticated;
  final VoidCallback onPrimaryAction;
  final VoidCallback onDeviceDetails;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    if (status == DeviceConnectionStatus.connected) {
      return _ConnectedHome(
        onDeviceDetails: onDeviceDetails,
        onPrimaryAction: onPrimaryAction,
      );
    }
    return _DisconnectedHome(
      isAuthenticated: isAuthenticated,
      onPrimaryAction: onPrimaryAction,
      onLogin: onLogin,
    );
  }
}

/// 设备已连接时的主页状态。
final class _ConnectedHome extends StatelessWidget {
  const _ConnectedHome({
    required this.onDeviceDetails,
    required this.onPrimaryAction,
  });

  final VoidCallback onDeviceDetails;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _StatusIcon(icon: Icons.bluetooth_connected),
        const SizedBox(height: 20),
        Text(
          'Device connected',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your Cyberskin device is ready for control.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: onDeviceDetails,
          icon: const Icon(Icons.tune),
          label: const Text('Open device controls'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPrimaryAction,
          icon: const Icon(Icons.bluetooth_disabled_outlined),
          label: const Text('Manage connection'),
        ),
      ],
    );
  }
}

/// 设备未连接时的主页状态，允许匿名浏览并引导登录。
final class _DisconnectedHome extends StatelessWidget {
  const _DisconnectedHome({
    required this.isAuthenticated,
    required this.onPrimaryAction,
    required this.onLogin,
  });

  final bool isAuthenticated;
  final VoidCallback onPrimaryAction;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _StatusIcon(icon: Icons.bluetooth_disabled_outlined),
        const SizedBox(height: 20),
        Text(
          'No device connected',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Connect a Cyberskin device to access controls and live status.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: onPrimaryAction,
          icon: const Icon(Icons.bluetooth_searching),
          label: Text(
            isAuthenticated ? 'Connect device' : 'Sign in to connect',
          ),
        ),
        if (!isAuthenticated) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onLogin, child: const Text('Sign in')),
        ],
      ],
    );
  }
}

/// 主页状态图标。
final class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
    );
  }
}
