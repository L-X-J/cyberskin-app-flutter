import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_html_content.dart';
// AppHtmlSkeleton 在 isLoading 时复用，保持骨架屏与 HTML 加载态视觉一致。
import '../../domain/repositories/device_catalog_repository.dart';
import '../device_manual_controller.dart';

/// Obx 包裹层；从 controller 提取 manual 和加载状态后交给 [DeviceManualSections]。
final class DeviceManualReactiveSections extends StatelessWidget {
  /// 创建 [DeviceManualReactiveSections]。
  const DeviceManualReactiveSections({required this.controller, super.key});

  /// 说明书页面控制器。
  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 27),
    child: Obx(
      () => DeviceManualSections(
        manual: controller.manual.value,
        selectedIndex: controller.selectedManualIndex.value,
        isLoading: controller.isLoading.value,
        onSelected: controller.selectManual,
      ),
    ),
  );
}

/// 说明书 Tab 栏 + 内容区；Tab 切换时以 AnimatedSwitcher 过渡。
final class DeviceManualSections extends StatelessWidget {
  /// 创建 [DeviceManualSections]。
  const DeviceManualSections({
    required this.manual,
    required this.selectedIndex,
    required this.isLoading,
    required this.onSelected,
    super.key,
  });

  /// 说明书数据；为 null 时显示加载或空状态。
  final DeviceManual? manual;

  /// 当前激活的 Tab 索引。
  final int selectedIndex;

  /// 内容是否正在加载。
  final bool isLoading;

  /// 用户切换 Tab 时的回调。
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
                ? const AppHtmlSkeleton()
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

/// 根据 tab 索引从 items 中匹配对应的 section；支持别名回退。
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
    final url = item?.contentUrl?.trim();
    if (url == null || url.isEmpty) {
      return Text(
        'No published content is available for this section.',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      );
    }
    return AppHtmlContent(url: url);
  }
}
