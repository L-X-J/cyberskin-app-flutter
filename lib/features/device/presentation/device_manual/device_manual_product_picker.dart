import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/repositories/device_catalog_repository.dart';
import '../device_manual_controller.dart';
import '../device_model_card.dart';

/// Obx 包裹层；从 controller 提取型号列表和选中状态后交给 [DeviceManualProductPicker]。
final class DeviceManualReactiveProductPicker extends StatelessWidget {
  /// 创建 [DeviceManualReactiveProductPicker]。
  const DeviceManualReactiveProductPicker({
    required this.controller,
    super.key,
  });

  /// 说明书页面控制器。
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
        DeviceManualProductPicker(
          models: models,
          selectedIndex: controller.selectedModelIndex.value,
          onSelected: controller.selectModel,
        ),
      ],
    );
  });
}

/// 横向滚动的型号选择卡片列表。
final class DeviceManualProductPicker extends StatelessWidget {
  /// 创建 [DeviceManualProductPicker]。
  const DeviceManualProductPicker({
    required this.models,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  /// 可选择的型号列表。
  final List<DeviceModelSummary> models;

  /// 当前选中项的索引。
  final int selectedIndex;

  /// 用户点击某项时的回调。
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

/// 当型号没有远端图片时按名称或位置匹配本地资产。
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

/// 当型号没有远端颜色时按位置回退到预设色板。
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
