// 设备型号详情与产品说明书统一页面的滚动 UI。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

/// 设备型号详情与产品说明书页面。
final class DeviceDetailPage extends GetView<DeviceDetailController> {
  /// 创建设备详情页面。
  const DeviceDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    final routeArgs = arguments is DeviceDetailRouteArguments
        ? arguments
        : null;
    return AppScaffold(
      currentTab: AppTab.home,
      showBottomNavigation: false,
      appBar: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      body: _DetailContent(
        controller: controller,
        routeArgs: routeArgs,
        onBack: () => Get.back<void>(),
      ),
    );
  }
}

final class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.controller,
    required this.routeArgs,
    required this.onBack,
  });

  final DeviceDetailController controller;
  final DeviceDetailRouteArguments? routeArgs;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final selected =
        controller.selectedModel.value ??
        controller.detail.value?.summary ??
        controller.summary ??
        const DeviceModelSummary(name: 'Cyberskin device');
    final models = controller.models.isEmpty
        ? <DeviceModelSummary>[selected]
        : controller.models.toList(growable: false);
    final manual = controller.manual.value;
    final bottom = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
      reserveFloatingControl: false,
    );

    if (controller.isLoading.value &&
        controller.detail.value == null &&
        manual == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.failure.value != null &&
        controller.detail.value == null &&
        manual == null) {
      return _ErrorState(
        failure: controller.failure.value!,
        onRetry: controller.reload,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.78, 0.08),
          radius: 1.15,
          colors: [Color(0xFF342247), Color(0xFF11102B), Colors.black],
          stops: [0, 0.52, 1],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 126,
            backgroundColor: const Color(0xFF11102B),
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: AppLiquidGlassButton(
                label: 'Back',
                icon: Icons.arrow_back_ios_new,
                onPressed: onBack,
                variant: AppLiquidGlassButtonVariant.translucent,
                width: 40,
                height: 40,
                borderRadius: 20,
                iconSize: 17,
              ),
            ),
            leadingWidth: 64,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 70,
                bottom: 14,
                end: 20,
              ),
              title: Text(
                selected.name ?? 'Cyberskin device',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subtitle.copyWith(fontSize: 16),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: _ProductHero(model: selected, routeArgs: routeArgs),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _ProductPicker(
                models: models,
                selectedIndex: controller.selectedModelIndex.value,
                onSelected: controller.selectModel,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
              child: _ManualSections(
                manual: manual,
                selectedIndex: controller.selectedManualIndex.value,
                onSelected: controller.selectManual,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, bottom),
              child: _AdvertisementFallback(
                imageUrl: controller.advertisements
                    .map((advertisement) => advertisement.imageUrl)
                    .firstWhere(
                      (value) => value != null && value.isNotEmpty,
                      orElse: () => null,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.model, required this.routeArgs});

  final DeviceModelSummary model;
  final DeviceDetailRouteArguments? routeArgs;

  @override
  Widget build(BuildContext context) {
    final image =
        model.iconUrl ??
        routeArgs?.summary?.iconUrl ??
        _fallbackAsset(model.name);
    final heroTag = 'device-model-${model.id ?? 'unknown'}';
    return SizedBox(
      height: 286,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Stack(
          key: ValueKey('${model.id}:$image'),
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 18,
              right: 18,
              bottom: 30,
              child: Container(
                height: 48,
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
                image,
                width: 218,
                height: 248,
                fit: BoxFit.contain,
                placeholder: const _ProductPlaceholder(),
                errorWidget: const _ProductPlaceholder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ProductPicker extends StatelessWidget {
  const _ProductPicker({
    required this.models,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<DeviceModelSummary> models;
  final int selectedIndex;
  final Future<void> Function(int index) onSelected;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 48 - 20) / 3;
    return SizedBox(
      height: 116,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: models.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: width.clamp(92, 132),
          child: _ProductCard(
            model: models[index],
            selected: index == selectedIndex,
            onTap: () => onSelected(index),
          ),
        ),
      ),
    );
  }
}

final class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.model,
    required this.selected,
    required this.onTap,
  });

  final DeviceModelSummary model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: model.name ?? 'Device model',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.white20 : AppColors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.borderWhite10,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: AppImage.load(
                model.iconUrl ?? _fallbackAsset(model.name),
                fit: BoxFit.contain,
                placeholder: const _ProductPlaceholder(size: 26),
                errorWidget: const _ProductPlaceholder(size: 26),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              model.name ?? 'Device',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.badge.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _ManualSections extends StatelessWidget {
  const _ManualSections({
    required this.manual,
    required this.selectedIndex,
    required this.onSelected,
  });

  final DeviceManual? manual;
  final int selectedIndex;
  final void Function(int index) onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = <String>['Introduction', 'Connection', 'Wash'];
    final selectedItem = _itemForSection(
      manual?.items ?? const [],
      selectedIndex,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 24),
            itemBuilder: (_, index) {
              final active = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(index),
                child: Column(
                  children: [
                    Text(
                      tabs[index],
                      style: AppTypography.bodyMedium.copyWith(
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      width: 92,
                      color: active ? AppColors.textPrimary : AppColors.white20,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _RichManualContent(item: selectedItem),
      ],
    );
  }
}

DeviceManualItem? _itemForSection(List<DeviceManualItem> items, int index) {
  if (items.isEmpty) {
    return null;
  }
  const aliases = <String>['intro', 'connection', 'cleaning'];
  final expected = aliases[index.clamp(0, aliases.length - 1)];
  for (final item in items) {
    if (item.tab?.trim().toLowerCase() == expected) {
      return item;
    }
  }
  return index < items.length ? items[index] : items.first;
}

final class _RichManualContent extends StatelessWidget {
  const _RichManualContent({required this.item});

  final DeviceManualItem? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Text(
        'No published content is available for this section.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return _HtmlText(html: item!.contentHtml ?? '');
  }
}

final class _HtmlText extends StatelessWidget {
  const _HtmlText({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final spans = _parseHtml(html);
    if (spans.isEmpty) {
      return Text(
        'No published content is available for this section.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }
    return Text.rich(TextSpan(children: spans));
  }
}

List<TextSpan> _parseHtml(String html) {
  final source = html.trim();
  if (source.isEmpty) return const <TextSpan>[];
  final spans = <TextSpan>[];
  final tokenPattern = RegExp(
    r'<(/?)(h[1-3]|p|strong|b|em|i|li|br|ul|ol)[^>]*>',
    caseSensitive: false,
  );
  var cursor = 0;
  var bold = false;
  var italic = false;
  var heading = false;
  for (final match in tokenPattern.allMatches(source)) {
    final text = _decodeHtml(source.substring(cursor, match.start));
    if (text.trim().isNotEmpty) {
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: heading ? 18 : 15,
            height: 1.65,
            fontWeight: heading || bold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );
    }
    final tag = match.group(2)!.toLowerCase();
    final closing = match.group(1) == '/';
    if (tag == 'br') spans.add(const TextSpan(text: '\n'));
    if (tag == 'li' && !closing) spans.add(const TextSpan(text: '• '));
    if (tag == 'p' || tag.startsWith('h')) {
      spans.add(const TextSpan(text: '\n'));
    }
    if (tag.startsWith('h')) heading = !closing;
    if (tag == 'strong' || tag == 'b') bold = !closing;
    if (tag == 'em' || tag == 'i') italic = !closing;
    if ((tag == 'p' || tag.startsWith('h') || tag == 'li') && closing) {
      spans.add(const TextSpan(text: '\n'));
    }
    cursor = match.end;
  }
  final tail = _decodeHtml(source.substring(cursor));
  if (tail.trim().isNotEmpty) {
    spans.add(
      TextSpan(
        text: tail,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.65,
        ),
      ),
    );
  }
  return spans;
}

String _decodeHtml(String value) => value
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&#39;', "'")
    .replaceAll('&quot;', '"');

final class _AdvertisementFallback extends StatelessWidget {
  const _AdvertisementFallback({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: AppImage.load(
      imageUrl ?? 'assets/images/home/banner_device.png',
      width: double.infinity,
      height: 138,
      fit: BoxFit.cover,
      errorWidget: const SizedBox.shrink(),
    ),
  );
}

final class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.devices_other_outlined, size: size, color: AppColors.white80);
}

final class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.failure, required this.onRetry});

  final AppFailure failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
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
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

String? _fallbackAsset(String? name) {
  final value = name?.toLowerCase() ?? '';
  if (value.contains('pro')) {
    return 'assets/images/home/device_pro_connected.png';
  }
  if (value.contains('air')) {
    return 'assets/images/home/device_air_connected.png';
  }
  return null;
}
