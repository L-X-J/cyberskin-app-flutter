// 自由控制主页面：根据后端返回的数据动态排列组件。
// 目前使用组件占位展示排版与布局结构。

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/widgets/app_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'free_control_controller.dart';
import 'widgets/free_control_layout_builder.dart';

final class FreeControlPage extends GetView<FreeControlController> {
  const FreeControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
      reserveFloatingControl: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF090714),
      body: Stack(
        children: [
          // 页面背景底图 (采用设计稿 app-background)
          Positioned.fill(
            child: Image.asset(
              'assets/images/device_modules/app-background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF090714)),
              ),
            ),
          ),

          // 页面顶部氛围暗紫光晕
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.4),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF6E288E).withValues(alpha: 0.45),
                      const Color(0xFF3B1556).withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 主滚动内容
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset),
              children: [
                // 顶部导航返回栏与标题
                _buildHeader(context),
                const SizedBox(height: 20),

                // 核心：完全通过后端下发的布局数据 (modules: row, col, variant) 动态排列组件
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(
                          color: AppColors.secondary,
                        ),
                      ),
                    );
                  }

                  final currentLayout = controller.layout.value;
                  if (currentLayout == null || currentLayout.components.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Text(
                          'No layout components configured',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }

                  return FreeControlLayoutBuilder(layout: currentLayout);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顶部标题与返回按钮
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 返回按钮圆环
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 标题与设备状态
        const Text(
          'Free control mode',
          style: TextStyle(
            fontSize: 26,
            fontWeight: AppFontWeights.demibold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Obx(() {
          return Text(
            '${controller.deviceName} · ${controller.connectionStatusText}',
            style: const TextStyle(
              fontSize: AppTypography.size12,
              color: AppColors.textHint,
            ),
          );
        }),
      ],
    );
  }
}
