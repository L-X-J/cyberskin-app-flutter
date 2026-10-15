// 主页已连接状态展示组件；包含设备内容体及其所有子组件。
import 'dart:async';
import 'dart:math' as math;

import 'package:cyberskin_app/core/extensions/string_extensions.dart';
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../app/widgets/app_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_img_group_80_card.dart';
import '../../../../core/widgets/app_layered_gradient_card.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../../device/domain/connected_device_state.dart';
import '../../../device/domain/device.dart';
import '../../../device/presentation/device_home_controller.dart';
import '../../../device/presentation/device_manual_route_arguments.dart';
import '../widgets/home_shared_widgets.dart';

/// 设备标签页的可嵌入内容体，可在独立路由或首页 Shell 中复用。
///
/// 订阅设备列表状态；调用方负责计算并传入正确的安全区插入值。
final class DeviceBodyContent extends StatelessWidget {
  /// 创建设备内容体；[topInset] 和 [bottomInset] 由调用方从 [MediaQuery] 和
  /// [AppScaffold.contentBottomPaddingOf] 计算后传入。
  /// [topPaddingOverride] 覆盖默认 [topInset]+34 的顶部留白，用于首页 Shell
  /// 已在外层渲染共享 HomeHeader 时避免重复空间。
  const DeviceBodyContent({
    super.key,
    required this.controller,
    required this.topInset,
    required this.bottomInset,
    this.topPaddingOverride,
    this.onPowerOff,
  });

  /// 设备主页控制器，持有设备列表和 BLE 发现状态。
  final DeviceHomeController controller;

  /// 页面顶部安全区高度，用于计算滚动内容的起始位置。
  final double topInset;

  /// 页面底部预留高度，确保最后一项在导航和控制条上方可达。
  final double bottomInset;

  /// 覆盖默认顶部内边距（topInset + 34）；首页 Shell 通过覆层渲染共享 Header
  /// 时传入此值，使内容从 Header 正下方开始而不重复渲染标题区。
  final double? topPaddingOverride;

  /// 请求关闭设备并解除绑定；独立设备页未提供时不显示业务动作。
  final VoidCallback? onPowerOff;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final devices = controller.devices.toList(growable: false);
      final failure = controller.failure.value;
      final isLoading = controller.isLoading.value;
      final pending = controller.pendingDiscovery?.value;
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
        return _EmptyDeviceState(
          pending: pending,
          onConfirm: () => unawaited(controller.confirmDiscovery()),
          onDismiss: () => unawaited(controller.dismissDiscovery()),
          onAdd: () => unawaited(controller.startDiscovery()),
        );
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
          topPaddingOverride: topPaddingOverride,
          onProfile: () => unawaited(Get.toNamed(AppRoutes.profile)),
          onRetry: () => unawaited(controller.reload()),
          pending: pending,
          onConfirmDiscovery: () => unawaited(controller.confirmDiscovery()),
          onDismissDiscovery: () => unawaited(controller.dismissDiscovery()),
          onPowerOff: onPowerOff ?? () {},
        ),
      );
    });
  }
}

/// 已连接设备页的滚动内容；业务上同一时刻只允许一台设备连接，始终取列表首项渲染。
final class _DeviceContent extends StatelessWidget {
  const _DeviceContent({
    required this.devices,
    required this.isLoading,
    required this.failure,
    required this.topInset,
    required this.bottomInset,
    required this.onProfile,
    required this.onRetry,
    this.pending,
    required this.onConfirmDiscovery,
    required this.onDismissDiscovery,
    required this.onPowerOff,
    this.topPaddingOverride,
  });

  final List<Device> devices;
  final bool isLoading;
  final String? failure;
  final double topInset;
  final double bottomInset;
  final VoidCallback onProfile;
  final VoidCallback onRetry;
  final BleDiscoveredDevice? pending;
  final VoidCallback onConfirmDiscovery;
  final VoidCallback onDismissDiscovery;
  final VoidCallback onPowerOff;

  // 首页 Shell 已渲染共享 HomeHeader 时传入，跳过内部 _DeviceHeader 并调整顶部留白。
  final double? topPaddingOverride;

  @override
  Widget build(BuildContext context) {
    final topPadding = topPaddingOverride ?? topInset + 34;
    return HomeBackground(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomInset),
        children: [
          // if (pending != null) ...[
          //   _NearbyDeviceCard(
          //     device: pending!,
          //     onConfirm: onConfirmDiscovery,
          //     onDismiss: onDismissDiscovery,
          //   ),
          //   const SizedBox(height: 18),
          // ],
          // // 独立路由（/device）时渲染自有标题区；首页 Shell 模式下由覆层共享 Header 代替。
          // if (topPaddingOverride == null) ...[
          //   _DeviceHeader(onProfile: onProfile),
          //   const SizedBox(height: 28),
          // ],
          // 业务上同一时刻只允许一台设备连接，取列表首项渲染。
          if (devices.isNotEmpty)
            _DeviceSection(device: devices.first, onPowerOff: onPowerOff),
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
    );
  }
}

/// 单个设备的首页内容，所有设备文案和颜色来自 [Device]。
/// 挂载时播放错帧入场动画：顶部卡旋转落入，下方卡片依次淡入。
final class _DeviceSection extends StatefulWidget {
  const _DeviceSection({required this.device, required this.onPowerOff});

  final Device device;
  final VoidCallback onPowerOff;

  @override
  State<_DeviceSection> createState() => _DeviceSectionState();
}

final class _DeviceSectionState extends State<_DeviceSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // 顶部设备卡：淡入 + 绕 X 轴翻转落入（类似卡片从仰视角翻转到正面的效果）。
  late final Animation<double> _heroFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  );

  // 绕 X 轴翻转：从 -0.35π（约 -63°，卡片背面朝向用户）到 0（正面）。
  late final Animation<double> _heroFlip =
      Tween<double>(begin: -0.35 * math.pi, end: 0.0).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ),
      );

  // 功能入口行、训练卡、广告卡依次渐入。
  late final Animation<double> _cardsFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _trainingFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> _adFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final modelId = int.tryParse(device.model.trim());
    // coordinator 是 GetxService，全局唯一。connectedDevice 用 Obx 订阅，
    // 确保连接设备视图刷新（包括首次 setConnectedDevice）时 hero 卡能收到最新对象。
    final coordinator = Get.isRegistered<CyberskinBleRuntimeCoordinator>()
        ? Get.find<CyberskinBleRuntimeCoordinator>()
        : null;
    return Column(
      children: [
        // 顶部设备卡：绕 X 轴翻转落入（卡片从仰视角翻转到正面）+ 淡入。
        AnimatedBuilder(
          animation: _heroFlip,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              // perspective：让远端收缩，模拟 3D 深度感。
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0008)
                ..rotateX(_heroFlip.value),
              child: FadeTransition(opacity: _heroFade, child: child),
            );
          },
          child: coordinator != null
              ? Obx(
                  () => _ConnectedDeviceHero(
                    device: device,
                    modelId: modelId,
                    connectedState: coordinator.connectedDevice.value,
                    onPowerOff: widget.onPowerOff,
                  ),
                )
              : _ConnectedDeviceHero(
                  device: device,
                  modelId: modelId,
                  onPowerOff: widget.onPowerOff,
                ),
        ),
        const SizedBox(height: 16),
        // 功能入口行：淡入。
        FadeTransition(
          opacity: _cardsFade,
          child: Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  title: 'Free control\nmode',
                  colors: const [Color(0xFFE4472A), Color(0xFF8E171A)],
                  onTap: () => unawaited(Get.toNamed(AppRoutes.freeControl)),
                  preview: AppImage.load("control/img_group_15".assetsSvg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  title: 'Customrhythm',
                  colors: [Color(0xFFBEF77A), Color(0xFF4B9C58)],
                  preview: AppImage.load("control/Group_5".assetsSvg),
                  // preview: _RhythmPreview(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 训练卡：淡入。
        FadeTransition(
          opacity: _trainingFade,
          child: const _TrainingPlaceholderCard(),
        ),
        const SizedBox(height: 16),
        // 广告卡：淡入。
        FadeTransition(
          opacity: _adFade,
          child: const _AdvertisementPlaceholderCard(),
        ),
      ],
    );
  }
}

/// 已连接设备主卡，展示设备状态、电量、标签和说明书入口。
///
/// 静态元数据（名称、型号、标签）来自 [device]；电量和状态从 [connectedState]
/// 的响应式字段读取，为 null 时退化为 [device] 的快照值。
final class _ConnectedDeviceHero extends StatelessWidget {
  const _ConnectedDeviceHero({
    required this.device,
    required this.modelId,
    required this.onPowerOff,
    this.connectedState,
  });

  final Device device;
  final int? modelId;
  final VoidCallback onPowerOff;

  /// 连接设备的实时运行时视图；为 null 时使用 [device] 的静态快照数据。
  final ConnectedDeviceState? connectedState;

  @override
  Widget build(BuildContext context) {
    final manualEnabled = modelId != null;
    return Stack(
      children: [
        Positioned(
          top: 15,
          left: 0,
          right: 0,
          child: AppLayeredGradientCard.scan(
            height: 179,
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
                            '· Connected',
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
                          // 电量标签
                          Obx(() {
                            var label = '-';
                            if (connectedState != null) {
                              final level = connectedState!.batteryLevel.value;
                              final isCharging =
                                  connectedState!.isCharging.value;
                              label = level >= 0
                                  ? '$level%${isCharging ? ' ⚡' : ''}'
                                  : '--';
                            }
                            return _CompactGlassButton(
                              label: label,
                              iconWidget: AppImage.load(
                                'home/Battery-charge'.assetsPng,
                                width: 24,
                              ),
                              onPressed: () {},
                            );
                          }),
                          const SizedBox(width: 8),
                          _CompactGlassButton(
                            label: 'Power',
                            icon: Icons.power_settings_new,
                            onPressed: onPowerOff,
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
                        iconSize: 12,
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
                        height: 24,
                        borderRadius: 8,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        textStyle: const TextStyle(
                          fontSize: AppTypography.size12,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
            placeholder: const _DeviceImagePlaceholder(),
            errorWidget: const _DeviceImagePlaceholder(),
          ),
        ),
        const SizedBox(height: 194),
      ],
    );
  }
}

/// 设备能力入口卡；当前设备页没有直接的控制路由时保持为稳定的视觉入口。
final class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.colors,
    this.preview,
    this.onTap,
  });

  final String title;
  final List<Color> colors;
  final Widget? preview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppImgGroup80Card(
        height: 170,
        backgroundColor: colors.first,
        accentColor: colors.first,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsGeometry.only(right: 30),
                    child: Text(title, style: AppTypography.bodyMedium),
                  ),
                  const Spacer(),
                  if (preview != null)
                    SizedBox(
                      height: 66,
                      width: double.infinity,
                      child: preview,
                    ),
                ],
              ),
            ),
            Positioned(
              right: 20,
              top: 24,
              child: AppLiquidGlassButton(
                label: 'Open model',
                icon: Icons.chevron_right,
                onPressed: onTap,
                variant: AppLiquidGlassButtonVariant.translucent,
                iconSize: 16,
                height: 20,
                width: 20,
                borderRadius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    this.iconWidget,
    this.width,
    this.iconOnly = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// 替代 [icon] 的自定义图标 Widget，优先级高于 [icon]。
  /// [iconOnly] 为 true 时作为按钮唯一内容；否则渲染在文案左侧，
  /// 建议通过 [width] 固定宽度以避免自动测量偏窄。
  final Widget? iconWidget;
  final double? width;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return AppLiquidGlassButton(
      label: label,
      leadingWidget: iconOnly ? null : iconWidget,
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
      // iconOnly + iconWidget：整个按钮内容由 iconWidget 填充。
      child: (iconOnly && iconWidget != null) ? iconWidget : null,
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
  const _EmptyDeviceState({
    required this.pending,
    required this.onConfirm,
    required this.onDismiss,
    required this.onAdd,
  });

  final BleDiscoveredDevice? pending;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
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
              _NearbyDeviceCard(
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

final class _NearbyDeviceCard extends StatelessWidget {
  const _NearbyDeviceCard({
    required this.device,
    required this.onConfirm,
    required this.onDismiss,
  });

  final BleDiscoveredDevice device;
  final VoidCallback onConfirm;
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
                  child: _CompactGlassButton(
                    label: 'Connect',
                    onPressed: onConfirm,
                    width: 100,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactGlassButton(
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
