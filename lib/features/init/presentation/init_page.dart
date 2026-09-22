// 应用初始化页面：在配置前置条件满足前阻止进入主应用。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'init_controller.dart';

/// 初始化页入口，负责展示阻塞等待、错误重试和后台刷新状态。
final class InitPage extends GetView<InitController> {
  /// 创建初始化页。
  const InitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Obx(() {
            final status = controller.status.value;
            if (status == InitStatus.failed) {
              return _InitFailureState(
                message: controller.failure.value?.message ?? '无法加载应用配置。',
                onRetry: controller.retry,
              );
            }
            return const _InitLoadingState();
          }),
        ),
      ),
    );
  }
}

/// 正在读取缓存或等待远端配置时的加载状态。
final class _InitLoadingState extends StatelessWidget {
  const _InitLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Preparing Cyberskin'),
      ],
    );
  }
}

/// 首次配置不可用时提供的阻塞错误状态。
final class _InitFailureState extends StatelessWidget {
  const _InitFailureState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
