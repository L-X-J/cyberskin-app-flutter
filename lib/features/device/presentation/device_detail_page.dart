// 设备型号详情页面：展示后台详情、能力摘要和产品介绍入口。
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';
import '../domain/repositories/device_catalog_repository.dart';
import 'device_detail_controller.dart';
import 'device_detail_route_arguments.dart';
import 'device_manual_route_arguments.dart';

/// 设备型号详情页。
final class DeviceDetailPage extends GetView<DeviceDetailController> {
  /// 创建设备型号详情页。
  const DeviceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final routeArgs = args is DeviceDetailRouteArguments ? args : null;
    return AppScaffold(
      currentTab: AppTab.home,
      showBottomNavigation: false,
      appBar: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      body: Obx(() {
        final detail = controller.detail.value;
        final summary = detail?.summary ?? controller.summary;
        return _DetailSurface(
          modelId: controller.modelId,
          summary: summary,
          detail: detail,
          isLoading: controller.isLoading.value,
          failure: controller.failure.value,
          onRetry: controller.reload,
          onBack: Get.back,
          onManual: () => Get.toNamed<void>(
            AppRoutes.deviceManual.replaceFirst(
              ':modelId',
              '${controller.modelId}',
            ),
            arguments: DeviceManualRouteArguments(productName: summary?.name),
          ),
          routeArgs: routeArgs,
        );
      }),
    );
  }
}

/// 详情页沉浸式滚动表面。
final class _DetailSurface extends StatelessWidget {
  const _DetailSurface({
    required this.modelId,
    required this.summary,
    required this.detail,
    required this.isLoading,
    required this.failure,
    required this.onRetry,
    required this.onBack,
    required this.onManual,
    required this.routeArgs,
  });

  final int modelId;
  final DeviceModelSummary? summary;
  final DeviceModelDetail? detail;
  final bool isLoading;
  final AppFailure? failure;
  final Future<void> Function() onRetry;
  final VoidCallback onBack;
  final VoidCallback onManual;
  final DeviceDetailRouteArguments? routeArgs;

  @override
  Widget build(BuildContext context) {
    final bottom = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
      reserveFloatingControl: false,
    );
    final title = summary?.name ?? 'Cyberskin device';
    final heroTag = 'device-model-${summary?.id ?? modelId}';
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.82, 0.08),
          radius: 1.15,
          colors: [Color(0xFF332143), Color(0xFF11102B), Colors.black],
          stops: [0, 0.52, 1],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.viewPaddingOf(context).top + 12,
          24,
          bottom,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppLiquidGlassButton(
              label: 'Back',
              icon: Icons.arrow_back_ios_new,
              onPressed: onBack,
              variant: AppLiquidGlassButtonVariant.translucent,
              width: 42,
              height: 42,
              iconSize: 18,
              borderRadius: 21,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 28,
                  left: 22,
                  right: 22,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: AppRadius.pill,
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 26),
                      ],
                    ),
                  ),
                ),
                Hero(
                  tag: heroTag,
                  child: AppImage.load(
                    summary?.iconUrl ??
                        routeArgs?.summary?.iconUrl ??
                        _fallbackAsset(summary?.name),
                    width: 230,
                    height: 260,
                    fit: BoxFit.contain,
                    placeholder: const SizedBox(width: 230, height: 260),
                  ),
                ),
              ],
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.heading2,
          ),
          if (summary?.tags != null) ...[
            const SizedBox(height: 8),
            Text(
              summary!.tags!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ],
          const SizedBox(height: 26),
          const _DetailTabs(),
          const SizedBox(height: 18),
          _IntroSection(summary: summary, detail: detail),
          const SizedBox(height: 18),
          _CapabilitySection(detail: detail),
          const SizedBox(height: 18),
          AppLiquidGlassButton(
            label: 'Product manual',
            icon: Icons.menu_book_outlined,
            onPressed: onManual,
            variant: AppLiquidGlassButtonVariant.translucent,
            height: 52,
            width: double.infinity,
          ),
          if (isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (failure != null) ...[
            const SizedBox(height: 16),
            AppInlineHint(
              icon: Icons.sync_problem_outlined,
              text: failure!.message,
              onTap: () => onRetry(),
            ),
          ],
        ],
      ),
    );
  }
}

final class _DetailTabs extends StatelessWidget {
  const _DetailTabs();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: _TabLabel('Introduction', selected: true)),
      Expanded(child: _TabLabel('Connection')),
      Expanded(child: _TabLabel('Wash')),
    ],
  );
}

final class _TabLabel extends StatelessWidget {
  const _TabLabel(this.label, {this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: selected ? AppColors.textPrimary : AppColors.white20,
        ),
      ],
    ),
  );
}

final class _IntroSection extends StatelessWidget {
  const _IntroSection({required this.summary, required this.detail});
  final DeviceModelSummary? summary;
  final DeviceModelDetail? detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Introducing ${summary?.name ?? 'your device'}',
        style: AppTypography.heading3,
      ),
      const SizedBox(height: 10),
      Text(
        'Explore the capabilities published for this device model. Connection settings and controls are managed by the device catalog.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: 16),
      _InfoCard(
        icon: Icons.tune,
        title: detail == null
            ? 'Loading capabilities'
            : '${detail!.supportedActions.length} configured actions',
        subtitle: detail?.layoutVersion == null
            ? 'Backend configuration'
            : 'Layout version ${detail!.layoutVersion}',
      ),
    ],
  );
}

final class _CapabilitySection extends StatelessWidget {
  const _CapabilitySection({required this.detail});
  final DeviceModelDetail? detail;

  @override
  Widget build(BuildContext context) {
    final items = <_CapabilityItem>[
      if (detail?.heatSupported == true)
        _CapabilityItem(
          'Heat',
          '${detail!.heatLevels.length} levels',
          Icons.local_fire_department_outlined,
        ),
      if (detail?.ble != null)
        _CapabilityItem(
          'Bluetooth',
          detail!.ble!.type ?? 'Configured',
          Icons.bluetooth,
        ),
      if (detail?.layout != null)
        _CapabilityItem(
          'Control layout',
          'Available',
          Icons.dashboard_customize_outlined,
        ),
      if (detail?.oneClickClimax != null)
        _CapabilityItem('One-click climax', 'Available', Icons.bolt_outlined),
    ];
    if (items.isEmpty) {
      items.add(
        const _CapabilityItem(
          'Device profile',
          'Details unavailable',
          Icons.info_outline,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capabilities', style: AppTypography.heading3),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => _InfoCard(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  compact: true,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

final class _CapabilityItem {
  const _CapabilityItem(this.title, this.subtitle, this.icon);
  final String title;
  final String subtitle;
  final IconData icon;
}

final class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 162 : double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white10,
      borderRadius: AppRadius.medium,
      border: Border.all(color: AppColors.borderWhite10),
    ),
    child: LiquidGlassLayer(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.tag.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badge,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String? _fallbackAsset(String? name) {
  final value = name?.toLowerCase() ?? '';
  if (value.contains('pro'))
    return 'assets/images/home/device_pro_connected.png';
  if (value.contains('air'))
    return 'assets/images/home/device_air_connected.png';
  return null;
}
