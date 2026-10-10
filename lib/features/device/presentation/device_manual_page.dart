// 设备产品说明书只读页面：展示后台发布的图文条目与型号入口。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_layered_gradient_card.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';
import '../domain/repositories/device_catalog_repository.dart';
import 'device_manual_controller.dart';

/// 设备产品说明书页面。
final class DeviceManualPage extends GetView<DeviceManualController> {
  /// 创建产品说明书页面。
  const DeviceManualPage({super.key});

  /// 构建说明书页面并在路由参数无效时展示安全状态。
  @override
  Widget build(BuildContext context) {
    final hasController = Get.isRegistered<DeviceManualController>();
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
      reserveFloatingControl: false,
    );
    return AppScaffold(
      currentTab: AppTab.home,
      showBottomNavigation: false,
      appBar: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      body: hasController
          ? _DeviceManualBody(
              controller: controller,
              topInset: topInset,
              bottomInset: bottomInset,
            )
          : const _InvalidModelState(),
    );
  }
}

/// 说明书主体只订阅手册页面自己的状态，避免整个应用壳层响应重建。
final class _DeviceManualBody extends StatelessWidget {
  const _DeviceManualBody({
    required this.controller,
    required this.topInset,
    required this.bottomInset,
  });

  final DeviceManualController controller;
  final double topInset;
  final double bottomInset;

  /// 构建说明书加载、失败或成功状态对应的内容子树。
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final manual = controller.manual.value;
      final failure = controller.failure.value;
      if (controller.isLoading.value && manual == null) {
        return const _ManualSurface(child: _ManualLoadingState());
      }
      if (failure != null && manual == null) {
        return _ManualSurface(
          child: _DeviceManualErrorState(
            message: failure.message,
            onRetry: () => unawaited(controller.reload()),
          ),
        );
      }
      if (manual == null) {
        return const _ManualSurface(child: _EmptyManualState());
      }
      return _DeviceManualContent(
        controller: controller,
        manual: manual,
        topInset: topInset,
        bottomInset: bottomInset,
      );
    });
  }
}

/// 已加载说明书的滚动内容。
final class _DeviceManualContent extends StatelessWidget {
  const _DeviceManualContent({
    required this.controller,
    required this.manual,
    required this.topInset,
    required this.bottomInset,
  });

  final DeviceManualController controller;
  final DeviceManual manual;
  final double topInset;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final items = manual.items;
    return _ManualSurface(
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, topInset + 12, 24, bottomInset),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppLiquidGlassButton(
              label: 'Back',
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => Get.back<void>(),
              variant: AppLiquidGlassButtonVariant.translucent,
              width: 44,
              height: 44,
              borderRadius: 22,
              iconSize: 20,
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              _productTitle(manual, controller.productName),
              textAlign: TextAlign.center,
              style: AppTypography.subtitle,
            ),
          ),
          const SizedBox(height: 10),
          const _ManualHero(),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 20),
            _ManualMediaChoices(items: items, controller: controller),
            const SizedBox(height: 18),
            _ManualTabs(items: items, controller: controller),
            const SizedBox(height: 26),
            Obx(() {
              final selectedIndex = controller.selectedTab.value;
              return _ManualArticle(item: items[selectedIndex]);
            }),
          ] else ...[
            const SizedBox(height: 28),
            const _EmptyManualState(),
          ],
          const SizedBox(height: 22),
          const _ManualAdvertisement(),
        ],
      ),
    );
  }
}

/// 产品说明书使用的沉浸背景；内容不使用通用白底卡片破坏设计层级。
final class _ManualSurface extends StatelessWidget {
  const _ManualSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        gradient: RadialGradient(
          center: Alignment(0.82, 0.25),
          radius: 1.06,
          colors: [Color(0xFF312937), Color(0xFF191240), Color(0xFF020202)],
          stops: [0, 0.54, 1],
        ),
      ),
      child: child,
    );
  }
}

/// 手册未提供名称时不猜测具体型号，保留中性的产品标题。
String _productTitle(DeviceManual manual, String? productName) {
  final normalized = productName?.trim();
  if (normalized != null && normalized.isNotEmpty) {
    return normalized;
  }
  return manual.deviceModelId == null ? 'Cyberskin device' : 'Your device';
}

/// 说明书产品主视觉；领域模型暂未提供 hero 媒体时使用项目内的透明产品兜底图。
final class _ManualHero extends StatelessWidget {
  const _ManualHero();

  @override
  /// 构建当前说明书条目的 hero 区域。
  Widget build(BuildContext context) {
    return Container(
      height: 232,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 30,
            right: 30,
            bottom: 18,
            height: 52,
            child: _ManualProductEllipse(),
          ),
          Positioned(
            top: 0,
            bottom: 20,
            child: AppImage.load(
              'assets/images/home/device_pro_connected_alt.png',
              width: 180,
              fit: BoxFit.contain,
              placeholder: const _ManualHeroPlaceholder(),
              errorWidget: const _ManualHeroPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 没有可用图片资源时的 hero 占位。
final class _ManualHeroPlaceholder extends StatelessWidget {
  const _ManualHeroPlaceholder();

  @override
  /// 构建没有可用图片时的稳定图标占位。
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.devices_other_outlined,
        size: 52,
        color: AppColors.white80,
      ),
    );
  }
}

/// 产品下方的细线椭圆，用于建立设备悬浮在空间中的视觉锚点。
final class _ManualProductEllipse extends StatelessWidget {
  const _ManualProductEllipse();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0x99FFFFFF)),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

/// 与说明书标签关联的三张媒体预览卡；不足三项时仅展示已发布的项。
final class _ManualMediaChoices extends StatelessWidget {
  const _ManualMediaChoices({required this.items, required this.controller});

  final List<DeviceManualItem> items;
  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) {
    const previews = <_ManualMediaPreview>[
      _ManualMediaPreview(
        baseColor: Color(0xFFE64A2F),
        topColor: Color(0xFFFE542E),
        image: 'assets/images/home/device_air_banner.png',
      ),
      _ManualMediaPreview(
        baseColor: Color(0xFFAD58C5),
        topColor: Color(0xFFC663E0),
        image: 'assets/images/home/device_pro_connected_alt.png',
      ),
      _ManualMediaPreview(
        baseColor: Color(0xFF79C763),
        topColor: Color(0xFFB0F279),
        image: 'assets/images/home/banner_device.png',
      ),
    ];
    final visibleItems = items.take(3).toList(growable: false);
    return Obx(() {
      final selectedIndex = controller.selectedTab.value;
      return Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < visibleItems.length; index++) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(
                  child: _ManualMediaCard(
                    item: visibleItems[index],
                    preview: previews[index],
                    selected: selectedIndex == index,
                    onTap: () => controller.selectTab(index),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < visibleItems.length; index++)
                Expanded(
                  child: Text(
                    _tabLabel(visibleItems[index], index),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTypography.size14,
                      color: selectedIndex == index
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}

/// 媒体入口的静态视觉参数，仅承载说明书卡片的色彩和本地兜底图。
final class _ManualMediaPreview {
  const _ManualMediaPreview({
    required this.baseColor,
    required this.topColor,
    required this.image,
  });

  final Color baseColor;
  final Color topColor;
  final String image;
}

/// 单张说明书媒体预览卡。
final class _ManualMediaCard extends StatelessWidget {
  const _ManualMediaCard({
    required this.item,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final DeviceManualItem item;
  final _ManualMediaPreview preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: _tabLabel(item, 0),
      child: AppLayeredGradientCard(
        height: 114,
        baseColor: preview.baseColor,
        topGradientColors: [Colors.black, preview.topColor],
        borderRadius: AppRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circular(30),
          child: AnimatedOpacity(
            opacity: selected ? 1 : 0.78,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: AppImage.load(preview.image, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

/// 按后台返回顺序展示的说明书标签栏，选中项使用底部细线而非 Material Chip。
final class _ManualTabs extends StatelessWidget {
  const _ManualTabs({required this.items, required this.controller});

  final List<DeviceManualItem> items;
  final DeviceManualController controller;

  @override
  /// 构建可横向滚动的说明书条目标签。
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIndex = controller.selectedTab.value;
      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x557F6C9D))),
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => controller.selectTab(index),
                  child: SizedBox(
                    height: 38,
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              _tabLabel(items[index], index),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppTypography.size14,
                                color: selectedIndex == index
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          height: 2,
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          color: selectedIndex == index
                              ? AppColors.textPrimary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// 优先保留后台标签；只有字段为空时才使用稳定的展示 fallback。
String _tabLabel(DeviceManualItem item, int index) {
  final tab = item.tab?.trim();
  if (tab != null && tab.isNotEmpty) {
    return tab;
  }
  return switch (index) {
    0 => 'Product intro',
    1 => 'Connection',
    2 => 'Wash',
    _ => 'Section ${index + 1}',
  };
}

/// 展示当前条目的标题和可读文本内容；文章承接背景，不额外叠白底卡片。
final class _ManualArticle extends StatelessWidget {
  const _ManualArticle({required this.item});

  final DeviceManualItem item;

  @override
  /// 构建当前说明书条目的纯文本文章内容。
  Widget build(BuildContext context) {
    final content = _readableContent(item.contentHtml);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _articleTitle(item),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTypography.size20,
            fontWeight: AppFontWeights.semibold,
            height: 1.28,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          content.isEmpty ? 'Content is not available yet.' : content,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppTypography.size14,
            height: 1.38,
          ),
        ),
      ],
    );
  }
}

/// 优先使用后台 HTML 中的标题，缺失时回退到已发布 tab 标签。
String _articleTitle(DeviceManualItem item) {
  final html = item.contentHtml;
  final headingMatch = html == null
      ? null
      : RegExp(
          r'<h[1-3][^>]*>(.*?)</h[1-3]>',
          caseSensitive: false,
        ).firstMatch(html);
  final heading = headingMatch?.group(1);
  if (heading != null) {
    final cleaned = _readableContent(heading);
    if (cleaned.isNotEmpty) return cleaned;
  }
  return item.tab?.trim().isNotEmpty == true
      ? item.tab!.trim()
      : 'Product information';
}

/// 底部运营位使用本地资产作为后台广告不可用时的视觉兜底。
final class _ManualAdvertisement extends StatelessWidget {
  const _ManualAdvertisement();

  @override
  Widget build(BuildContext context) {
    return AppLayeredGradientCard(
      height: 126,
      baseColor: const Color(0xFF25242D),
      topGradientColors: const [Colors.black, Color(0xFF46334E)],
      borderRadius: AppRadius.circular(30),
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(30, 20, 108, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The GalaxyVoy1',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'New product launch',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 5),
                Text(
                  '12 modes of vibration heating',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Positioned(
            right: 18,
            top: 8,
            bottom: 6,
            width: 74,
            child: AppImage.load(
              'assets/images/home/banner_device.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// 将后端 HTML 降级为无需 HTML 渲染依赖也能阅读的纯文本。
String _readableContent(String? html) {
  if (html == null || html.trim().isEmpty) {
    return '';
  }
  return html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'&nbsp;', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
      .replaceAll(RegExp(r'&lt;', caseSensitive: false), '<')
      .replaceAll(RegExp(r'&gt;', caseSensitive: false), '>')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// 无条目时的只读空状态。
final class _EmptyManualState extends StatelessWidget {
  const _EmptyManualState();

  @override
  /// 构建设备说明书为空时的只读提示。
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Product information is not available yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
      ),
    );
  }
}

/// 说明书加载失败状态。
final class _DeviceManualErrorState extends StatelessWidget {
  const _DeviceManualErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  /// 构建设备说明书加载失败状态。
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
              variant: AppLiquidGlassButtonVariant.translucent,
              width: 132,
              height: 42,
              borderRadius: 21,
              textStyle: const TextStyle(
                fontSize: AppTypography.size14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 手册首屏加载状态，与沉浸式页面保持一致而不回退到亮色进度条。
final class _ManualLoadingState extends StatelessWidget {
  const _ManualLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 30,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.white80,
        ),
      ),
    );
  }
}

/// 路由参数无法解析时的安全状态。
final class _InvalidModelState extends StatelessWidget {
  const _InvalidModelState();

  @override
  /// 构建型号路由参数无效时的安全提示。
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'This product manual cannot be opened right now.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
