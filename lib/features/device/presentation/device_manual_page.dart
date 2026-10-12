// 设备说明书统一页面的滚动 UI。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../../app/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';
import '../../../core/widgets/app_lottie_background.dart';
import '../domain/repositories/device_catalog_repository.dart';
import 'device_manual_controller.dart';
import 'device_manual_route_arguments.dart';
import 'device_model_card.dart';

/// 设备说明书页面。
final class DeviceManualPage extends GetView<DeviceManualController> {
  /// 创建设备说明书页面。
  const DeviceManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    final routeArgs = arguments is DeviceManualRouteArguments
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

  final DeviceManualController controller;
  final DeviceManualRouteArguments? routeArgs;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bottom = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
      reserveFloatingControl: false,
    );
    return Stack(
      children: [
        const AppLottieBackground(playbackSpeed: 1.5),
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              primary: true,
              automaticallyImplyLeading: false,
              expandedHeight: 174,
              toolbarHeight: 64,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(start: 24),
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
              clipBehavior: Clip.hardEdge,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                collapseMode: CollapseMode.pin,
                background: _ExpandedHeaderBackground(controller: controller),
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 72,
                  end: 24,
                  bottom: 16,
                ),
                title: _HeaderTitle(
                  controller: controller,
                  style: AppTypography.subtitle.copyWith(fontSize: 16),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ReactiveProductHero(
                controller: controller,
                routeArgs: routeArgs,
              ),
            ),
            SliverToBoxAdapter(
              child: _ReactiveProductPicker(controller: controller),
            ),
            SliverToBoxAdapter(
              child: _ReactiveManualSections(controller: controller),
            ),
            SliverToBoxAdapter(
              child: _ReactiveAdvertisement(
                controller: controller,
                bottomPadding: bottom,
              ),
            ),
          ],
        ),
        _DetailStatusOverlay(controller: controller),
      ],
    );
  }
}

/// AppBar 展开态的独立背景层；它覆盖整个折叠头部，避免正文穿透标题区域。
final class _ExpandedHeaderBackground extends StatelessWidget {
  const _ExpandedHeaderBackground({required this.controller});

  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final progress = ((constraints.maxHeight - kToolbarHeight) / 110).clamp(
        0.0,
        1.0,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          const AppLottieBackground(playbackSpeed: 1.5),
          IgnorePointer(
            child: Opacity(
              opacity: progress,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: _HeaderTitle(
                    controller: controller,
                    style: AppTypography.productName,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

final class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.controller, required this.style});

  final DeviceManualController controller;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Obx(() {
    final model = controller.selectedModel.value ?? controller.summary;
    return Text(
      model?.name ?? 'Cyberskin device',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  });
}

final class _ReactiveProductHero extends StatelessWidget {
  const _ReactiveProductHero({
    required this.controller,
    required this.routeArgs,
  });

  final DeviceManualController controller;
  final DeviceManualRouteArguments? routeArgs;

  @override
  Widget build(BuildContext context) => Obx(() {
    final model =
        controller.selectedModel.value ??
        controller.detail.value?.summary ??
        controller.summary ??
        const DeviceModelSummary(name: 'Cyberskin device');
    return _ProductHero(model: model, routeArgs: routeArgs);
  });
}

final class _ReactiveProductPicker extends StatelessWidget {
  const _ReactiveProductPicker({required this.controller});

  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.selectedModel.value ?? controller.summary;
    final models = controller.models.isEmpty
        ? <DeviceModelSummary>[
            selected ?? const DeviceModelSummary(name: 'Device'),
          ]
        : controller.models.toList(growable: false);
    return Column(
      children: [
        const SizedBox(height: 44),
        _ProductPicker(
          models: models,
          selectedIndex: controller.selectedModelIndex.value,
          onSelected: controller.selectModel,
        ),
      ],
    );
  });
}

final class _ReactiveManualSections extends StatelessWidget {
  const _ReactiveManualSections({required this.controller});

  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 27),
    child: Obx(
      () => _ManualSections(
        manual: controller.manual.value,
        selectedIndex: controller.selectedManualIndex.value,
        isLoading: controller.isLoading.value,
        onSelected: controller.selectManual,
      ),
    ),
  );
}

final class _ReactiveAdvertisement extends StatelessWidget {
  const _ReactiveAdvertisement({
    required this.controller,
    required this.bottomPadding,
  });

  final DeviceManualController controller;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Obx(() {
    final imageUrl = controller.detail.value?.advertisements
        .map((advertisement) => advertisement.imageUrl)
        .firstWhere(
          (value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 26, 24, bottomPadding),
      child: _Advertisement(imageUrl: imageUrl),
    );
  });
}

final class _DetailStatusOverlay extends StatelessWidget {
  const _DetailStatusOverlay({required this.controller});

  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final hasData =
        controller.detail.value != null || controller.manual.value != null;
    final failure = controller.failure.value;
    if (hasData) {
      return const SizedBox.shrink();
    }
    if (failure == null) {
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

final class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.model, required this.routeArgs});

  final DeviceModelSummary model;
  final DeviceManualRouteArguments? routeArgs;

  @override
  Widget build(BuildContext context) {
    final image =
        model.iconUrl ??
        routeArgs?.summary?.iconUrl ??
        _fallbackAsset(model.name);
    final heroTag = 'device-model-${model.id ?? 'unknown'}';
    return SizedBox(
      height: 238,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Stack(
          key: ValueKey('${model.id}:$image'),
          alignment: Alignment.center,
          children: [
            const Positioned(
              left: 54,
              right: 54,
              bottom: 14,
              height: 58,
              child: _ProductBase(),
            ),
            Positioned(
              top: 19,
              child: Hero(
                tag: heroTag,
                child: AppImage.load(
                  image,
                  width: 188,
                  height: 188,
                  fit: BoxFit.contain,
                  placeholder: const _ProductPlaceholder(),
                  errorWidget: const _ProductPlaceholder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ardot 设计稿中的细椭圆产品底座。
final class _ProductBase extends StatelessWidget {
  const _ProductBase();

  @override
  Widget build(BuildContext context) => AppImage.load(
    'assets/images/device/device_detail_base.svg',
    width: 293,
    height: 58,
    fit: BoxFit.fill,
  );
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
    final width = (MediaQuery.sizeOf(context).width - 40 - 20) / 3;
    return SizedBox(
      height: 116,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: models.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => SizedBox(
          width: width,
          child: DeviceModelCard(
            title: models[index].name ?? 'Device',
            image: models[index].iconUrl ?? _pickerAsset(models[index], index),
            baseColor: _pickerColor(models[index], index),
            heroTag: null,
            selected: index == selectedIndex,
            onTap: () => onSelected(index),
            variant: DeviceModelCardVariant.picker,
          ),
        ),
      ),
    );
  }
}

String? _pickerAsset(DeviceModelSummary model, int index) {
  final name = model.name?.toLowerCase() ?? '';
  if (name.contains('pro') || index == 1) {
    return 'assets/images/home/device_pro.png';
  }
  if (name.contains('air') || index == 0) {
    return 'assets/images/home/device_air.png';
  }
  return null;
}

Color _pickerColor(DeviceModelSummary model, int index) {
  final raw = model.cardColor?.replaceFirst('#', '');
  final parsed = raw == null
      ? null
      : int.tryParse(raw.length == 6 ? 'FF$raw' : raw, radix: 16);
  if (parsed != null) {
    return Color(parsed);
  }
  return switch (index % 3) {
    0 => const Color(0xFFEA512E),
    1 => const Color(0xFFB44FAE),
    _ => const Color(0xFF84D86D),
  };
}

final class _ManualSections extends StatelessWidget {
  const _ManualSections({
    required this.manual,
    required this.selectedIndex,
    required this.isLoading,
    required this.onSelected,
  });

  final DeviceManual? manual;
  final int selectedIndex;
  final bool isLoading;
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
          height: 42,
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ColoredBox(
                  color: AppColors.white20,
                  child: SizedBox(height: 1),
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < tabs.length; index++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelected(index),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                tabs[index],
                                style: AppTypography.bodyMedium.copyWith(
                                  color: index == selectedIndex
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ),
                            if (index == selectedIndex)
                              const Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: ColoredBox(
                                  color: AppColors.textPrimary,
                                  child: SizedBox(height: 1),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 44),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                ...previousChildren,
                ..._optionalWidget(currentChild),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.transparent,
                    ),
                  )
                : _RichManualContent(
                    key: ValueKey<String>(
                      '${selectedItem?.id}:${selectedItem?.contentUrl}:$selectedIndex',
                    ),
                    item: selectedItem,
                  ),
          ),
        ),
      ],
    );
  }
}

Iterable<Widget> _optionalWidget(Widget? child) =>
    child == null ? const <Widget>[] : <Widget>[child];

DeviceManualItem? _itemForSection(List<DeviceManualItem> items, int index) {
  if (items.isEmpty) {
    return null;
  }
  const aliases = <String>['intro', 'connection', 'cleaning'];
  final expected = aliases[index.clamp(0, aliases.length - 1)];
  for (final item in items) {
    final tab = item.tab?.trim().toLowerCase();
    if (tab == expected ||
        (index == 0 && tab == 'introduction') ||
        (index == 2 && tab == 'wash')) {
      return item;
    }
  }
  return index < items.length ? items[index] : items.first;
}

final class _RichManualContent extends StatelessWidget {
  const _RichManualContent({required this.item, super.key});

  final DeviceManualItem? item;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Text(
        'No published content is available for this section.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
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
    if (html.trim().isEmpty) {
      return Text(
        'No published rich text is available for this section.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      );
    }
    final fragment = html_parser.parseFragment(html);
    final blocks = <Widget>[];
    for (final node in fragment.nodes) {
      _appendHtmlBlock(node, blocks);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }
}

final class _HtmlStyleState {
  const _HtmlStyleState({
    this.bold = false,
    this.italic = false,
    this.headingLevel = 0,
  });

  final bool bold;
  final bool italic;
  final int headingLevel;

  _HtmlStyleState copyWith({bool? bold, bool? italic, int? headingLevel}) =>
      _HtmlStyleState(
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        headingLevel: headingLevel ?? this.headingLevel,
      );
}

void _appendHtmlBlock(dom.Node node, List<Widget> blocks) {
  if (node is dom.Text) {
    if (node.data.trim().isEmpty) return;
    blocks.add(_HtmlParagraph(nodes: <dom.Node>[node]));
    return;
  }
  if (node is! dom.Element) return;

  final tag = node.localName?.toLowerCase() ?? '';
  if (tag == 'img') {
    final source = node.attributes['src']?.trim();
    if (source != null && source.isNotEmpty) {
      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppImage.load(
            source,
            width: double.infinity,
            fit: BoxFit.contain,
            errorWidget: const SizedBox.shrink(),
          ),
        ),
      );
    }
    return;
  }
  if (tag == 'ul' || tag == 'ol') {
    for (final child in node.children) {
      if (child.localName?.toLowerCase() == 'li') {
        blocks.add(_HtmlParagraph(nodes: <dom.Node>[child], bullet: true));
      }
    }
    return;
  }
  if (tag == 'br') {
    blocks.add(const SizedBox(height: 8));
    return;
  }
  if (_isBlockTag(tag)) {
    blocks.add(
      _HtmlParagraph(
        nodes: <dom.Node>[node],
        headingLevel: _headingLevel(tag),
        textAlign: _textAlign(node),
      ),
    );
    return;
  }
  blocks.add(_HtmlParagraph(nodes: <dom.Node>[node]));
}

final class _HtmlParagraph extends StatelessWidget {
  const _HtmlParagraph({
    required this.nodes,
    this.headingLevel = 0,
    this.textAlign = TextAlign.left,
    this.bullet = false,
  });

  final List<dom.Node> nodes;
  final int headingLevel;
  final TextAlign textAlign;
  final bool bullet;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    if (bullet) spans.add(const TextSpan(text: '• '));
    for (final node in nodes) {
      _appendInlineNode(
        node,
        spans,
        _HtmlStyleState(headingLevel: headingLevel),
      );
    }
    final style = headingLevel > 0
        ? AppTypography.productName.copyWith(
            fontSize: headingLevel <= 2 ? 20 : 17,
            height: 1.25,
            color: AppColors.textPrimary,
          )
        : AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.55,
          );
    return Padding(
      padding: EdgeInsets.only(bottom: headingLevel > 0 ? 20 : 14),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}

void _appendInlineNode(
  dom.Node node,
  List<TextSpan> spans,
  _HtmlStyleState state,
) {
  if (node is dom.Text) {
    final text = node.data.replaceAll(RegExp(r'\s+'), ' ');
    if (text.trim().isEmpty) return;
    spans.add(
      TextSpan(
        text: text,
        style: TextStyle(
          fontWeight: state.bold || state.headingLevel > 0
              ? FontWeight.w700
              : FontWeight.w400,
          fontStyle: state.italic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
    return;
  }
  if (node is! dom.Element) return;
  final tag = node.localName?.toLowerCase() ?? '';
  if (tag == 'br') {
    spans.add(const TextSpan(text: '\n'));
    return;
  }
  final nextHeading = _headingLevel(tag);
  final childState = state.copyWith(
    bold: state.bold || tag == 'strong' || tag == 'b',
    italic: state.italic || tag == 'em' || tag == 'i',
    headingLevel: nextHeading == 0 ? state.headingLevel : nextHeading,
  );
  for (final child in node.nodes) {
    _appendInlineNode(child, spans, childState);
  }
}

bool _isBlockTag(String tag) =>
    tag == 'p' ||
    tag == 'div' ||
    tag == 'section' ||
    tag == 'article' ||
    tag == 'li' ||
    tag == 'h1' ||
    tag == 'h2' ||
    tag == 'h3' ||
    tag == 'h4' ||
    tag == 'h5' ||
    tag == 'h6';

int _headingLevel(String tag) => switch (tag) {
  'h1' => 1,
  'h2' => 2,
  'h3' => 3,
  'h4' => 4,
  'h5' => 5,
  'h6' => 6,
  _ => 0,
};

TextAlign _textAlign(dom.Element element) {
  final style = element.attributes['style']?.toLowerCase() ?? '';
  final align = element.attributes['align']?.toLowerCase();
  final value =
      RegExp(r'text-align\s*:\s*(left|center|right|justify)')
          .firstMatch(style)
          ?.group(1) ??
      align;
  return switch (value) {
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    'justify' => TextAlign.justify,
    _ => TextAlign.left,
  };
}

final class _Advertisement extends StatelessWidget {
  const _Advertisement({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: AppImage.load(
      imageUrl,
      width: double.infinity,
      height: 138,
      fit: BoxFit.cover,
      errorWidget: const SizedBox.shrink(),
    ),
  );
}

final class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.devices_other_outlined,
    size: 52,
    color: AppColors.white80,
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
