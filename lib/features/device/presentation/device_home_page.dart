// 设备标签页入口及已连接设备首页的局部展示组件。
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../app/widgets/app_glass_surfaces.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_layered_gradient_card.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';
import '../domain/device.dart';
import 'device_home_controller.dart';
import 'device_manual_route_arguments.dart';

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
      body: _DeviceBody(
        controller: controller,
        topInset: topInset,
        bottomInset: bottomInset,
      ),
    );
  }
}

/// 仅此内容子树订阅设备列表状态，顶部导航和全局控制条保持在观察范围外。
final class _DeviceBody extends StatelessWidget {
  const _DeviceBody({
    required this.controller,
    required this.topInset,
    required this.bottomInset,
  });

  final DeviceHomeController controller;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final devices = controller.devices.toList(growable: false);
      final failure = controller.failure.value;
      final isLoading = controller.isLoading.value;
      if (isLoading && devices.isEmpty) {
        return const _DeviceLoadingState();
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
        color: AppColors.secondary,
        backgroundColor: AppColors.surface,
        onRefresh: controller.reload,
        child: _DeviceContent(
          devices: devices,
          isLoading: isLoading,
          failure: failure?.message,
          topInset: topInset,
          bottomInset: bottomInset,
          onProfile: () => unawaited(Get.toNamed(AppRoutes.profile)),
          onRetry: () => unawaited(controller.reload()),
        ),
      );
    });
  }
}

/// 已连接设备页的滚动内容，按设备列表顺序保留多个设备的可见性。
final class _DeviceContent extends StatelessWidget {
  const _DeviceContent({
    required this.devices,
    required this.isLoading,
    required this.failure,
    required this.topInset,
    required this.bottomInset,
    required this.onProfile,
    required this.onRetry,
  });

  final List<Device> devices;
  final bool isLoading;
  final String? failure;
  final double topInset;
  final double bottomInset;
  final VoidCallback onProfile;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      fake: true,
      useBackdropGroup: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          gradient: RadialGradient(
            center: Alignment(0.9, 0.24),
            radius: 1.1,
            colors: [Color(0xFF25163B), Color(0xFF101030), Color(0xFF020202)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, topInset + 34, 24, bottomInset),
          children: [
            _DeviceHeader(onProfile: onProfile),
            const SizedBox(height: 28),
            for (var index = 0; index < devices.length; index++) ...[
              if (index > 0) const SizedBox(height: 28),
              _DeviceSection(device: devices[index]),
            ],
            if (failure != null) ...[
              const SizedBox(height: 12),
              AppInlineHint(
                icon: Icons.sync_problem_outlined,
                text: failure!,
                onTap: onRetry,
              ),
            ],
            if (isLoading) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
    );
  }
}

/// 页面标题区和用户资料入口。
final class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My device', style: AppTypography.pageTitle),
              SizedBox(height: 4),
              Text(
                'Good evening, stay relaxed',
                style: TextStyle(
                  fontSize: AppTypography.size16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppLiquidGlassButton(
          label: 'Profile',
          variant: AppLiquidGlassButtonVariant.translucent,
          width: 50,
          height: 50,
          borderRadius: 25,
          onPressed: onProfile,
          child: AppImage.load(
            'assets/images/home/go_user_profile.png',
            width: 50,
            height: 50,
            semanticLabel: 'Profile',
          ),
        ),
      ],
    );
  }
}

/// 单个设备的首页内容，所有设备文案和颜色来自 [Device]。
final class _DeviceSection extends StatelessWidget {
  const _DeviceSection({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final modelId = int.tryParse(device.model.trim());
    return Column(
      children: [
        _ConnectedDeviceHero(device: device, modelId: modelId),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(
              child: _FeatureCard(
                title: 'Free control\nmode',
                colors: [Color(0xFFE4472A), Color(0xFF8E171A)],
                preview: _FreeControlPreview(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                title: 'Customrhythm',
                colors: [Color(0xFFBEF77A), Color(0xFF4B9C58)],
                preview: _RhythmPreview(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _TrainingPlaceholderCard(),
        const SizedBox(height: 16),
        const _AdvertisementPlaceholderCard(),
      ],
    );
  }
}

/// 已连接设备主卡，展示设备状态、电量、标签和说明书入口。
final class _ConnectedDeviceHero extends StatelessWidget {
  const _ConnectedDeviceHero({required this.device, required this.modelId});

  final Device device;
  final int? modelId;

  @override
  Widget build(BuildContext context) {
    final baseColor = _parseColor(device.cardColor) ?? const Color(0xFF5E185F);
    final manualEnabled = modelId != null;
    return AppLayeredGradientCard(
      height: 179,
      baseColor: baseColor,
      topGradientColors: const [Colors.black, Color(0xFFC95FD0)],
      child: Stack(
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bluetooth_connected,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      device.status.label,
                      style: const TextStyle(
                        fontSize: AppTypography.size14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _CompactGlassButton(
                      label: '${device.batteryPercent ?? '--'}%',
                      icon: Icons.battery_6_bar_rounded,
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    _CompactGlassButton(
                      label: 'Power',
                      icon: Icons.power_settings_new,
                      onPressed: () {},
                      width: 38,
                      iconOnly: true,
                    ),
                  ],
                ),
                if (_parseTags(device.tags).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _parseTags(device.tags).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppTypography.size10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                AppLiquidGlassButton(
                  label: manualEnabled
                      ? 'Product manual'
                      : 'Manual unavailable',
                  leadingIcon: Icons.description_outlined,
                  onPressed: manualEnabled
                      ? () => unawaited(
                          Get.toNamed(
                            AppRoutes.deviceManual.replaceFirst(
                              ':modelId',
                              '$modelId',
                            ),
                            arguments: DeviceManualRouteArguments(
                              modelId: modelId!,
                            ),
                          ),
                        )
                      : null,
                  variant: AppLiquidGlassButtonVariant.translucent,
                  width: 132,
                  height: 28,
                  borderRadius: 12,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(
                    fontSize: AppTypography.size12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            top: -6,
            width: 132,
            height: 166,
            child: AppImage.load(
              'assets/images/home/device_pro_connected.png',
              fit: BoxFit.contain,
              semanticLabel: device.name,
              placeholder: const _DeviceImagePlaceholder(),
              errorWidget: const _DeviceImagePlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备能力入口卡；当前设备页没有直接的控制路由时保持为稳定的视觉入口。
final class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.colors,
    required this.preview,
  });

  final String title;
  final List<Color> colors;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    return AppLayeredGradientCard(
      height: 170,
      baseColor: colors.last,
      topGradientColors: [Colors.black, colors.first],
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, height: 1.15)),
                const Spacer(),
                SizedBox(height: 66, width: double.infinity, child: preview),
              ],
            ),
          ),
          Positioned(
            top: 24,
            right: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const SizedBox.square(
                dimension: 20,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.white80,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 自由控制入口的局部参数矩阵，避免以通用图标代替设计的控制语义。
final class _FreeControlPreview extends StatelessWidget {
  const _FreeControlPreview();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.vibration_rounded, size: 12, color: AppColors.white80),
              Icon(Icons.speed_rounded, size: 12, color: AppColors.white80),
              Icon(
                Icons.water_drop_outlined,
                size: 12,
                color: AppColors.white80,
              ),
              Icon(
                Icons.thermostat_outlined,
                size: 12,
                color: AppColors.white80,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: math.max(1, constraints.maxWidth / 30),
              children: List<Widget>.generate(
                12,
                (index) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? Colors.white.withValues(alpha: 0.26)
                        : Colors.black.withValues(alpha: 0.18),
                    borderRadius: AppRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 自定义节奏入口的波形预览；只表达入口视觉，不承担真实节奏编辑状态。
final class _RhythmPreview extends StatelessWidget {
  const _RhythmPreview();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RhythmWavePainter());
  }
}

/// 绘制与设计卡片一致的连续节奏曲线和当前位置标记。
final class _RhythmWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.22,
        size.width * 0.28,
        size.height * 0.2,
        size.width * 0.43,
        size.height * 0.55,
      )
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.95,
        size.width * 0.71,
        size.height * 0.18,
        size.width,
        size.height * 0.72,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFD5F88E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final marker = Offset(size.width * 0.42, size.height * 0.54);
    canvas.drawCircle(marker, 5, Paint()..color = const Color(0xFFBEE974));
    canvas.drawCircle(
      marker,
      9,
      Paint()
        ..color = const Color(0xFFBEE974).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _RhythmWavePainter oldDelegate) => false;
}

/// 没有训练 Repository 数据时保留的训练入口占位卡。
final class _TrainingPlaceholderCard extends StatelessWidget {
  const _TrainingPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return AppLayeredGradientCard(
      height: 136,
      baseColor: const Color(0xFF3A427D),
      topGradientColors: const [Colors.black, Color(0xFF46529D)],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Training mode', style: TextStyle(fontSize: 17)),
                const Spacer(),
                _CompactGlassButton(
                  label: 'More',
                  icon: Icons.grid_view_rounded,
                  onPressed: () {},
                  width: 66,
                ),
              ],
            ),
            const Spacer(),
            AppGlassCard(
              height: 62,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: AppImage.load(
                      'assets/images/home/training_thumb.png',
                      width: 44,
                      height: 44,
                      radius: 22,
                    ),
                  ),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rhythm Adaptation · Beginner's Guide",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '12 minutes · 4 stages · Low intensity',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 没有广告 Repository 数据时保留的运营位占位卡。
final class _AdvertisementPlaceholderCard extends StatelessWidget {
  const _AdvertisementPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return AppLayeredGradientCard(
      height: 124,
      baseColor: const Color(0xFF2A2932),
      topGradientColors: const [Colors.black, Color(0xFF443149)],
      child: Stack(
        children: [
          Positioned.fill(
            child: AppImage.load(
              'assets/images/home/banner_device.png',
              fit: BoxFit.cover,
              radius: AppRadius.radiusCard,
              errorWidget: const ColoredBox(color: AppColors.surface),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 24, 100, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The GalaxyVoy1', style: TextStyle(fontSize: 17)),
                SizedBox(height: 4),
                Text('New product launch', style: TextStyle(fontSize: 16)),
                SizedBox(height: 6),
                Text(
                  '12 modes of vibration heating',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备页的紧凑液态玻璃操作表面。
final class _CompactGlassButton extends StatelessWidget {
  const _CompactGlassButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.iconOnly = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return AppLiquidGlassButton(
      label: label,
      leadingIcon: iconOnly ? null : icon,
      icon: iconOnly ? icon : null,
      onPressed: onPressed,
      variant: AppLiquidGlassButtonVariant.translucent,
      width: width,
      height: 32,
      borderRadius: 12,
      iconSize: 18,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      textStyle: const TextStyle(
        fontSize: AppTypography.size12,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// 设备图片缺失时使用的稳定占位，保证 hero 仍保留视觉锚点。
final class _DeviceImagePlaceholder extends StatelessWidget {
  const _DeviceImagePlaceholder();

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

/// 页面加载设备数据时的首屏状态。
final class _DeviceLoadingState extends StatelessWidget {
  const _DeviceLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.secondary),
    );
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
              onPressed: () {},
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

/// 将后台颜色字段转换为 Flutter 颜色；非法值回退到页面默认表面。
Color? _parseColor(String? hex) {
  final clean = hex?.trim().replaceFirst(RegExp(r'^#'), '');
  if (clean == null ||
      !RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(clean)) {
    return null;
  }
  final value = int.tryParse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
  return value == null ? null : Color(value);
}

/// 将后台逗号标签转换为可展示的不可变列表。
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
