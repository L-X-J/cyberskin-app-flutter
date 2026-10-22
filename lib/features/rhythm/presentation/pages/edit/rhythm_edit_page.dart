// 新增/编辑节奏页面：表单布局、草稿退出确认和片段弹层入口。
import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/entities/rhythm_program.dart';
import '../../widgets/rhythm_dialogs.dart';
import '../../widgets/rhythm_page_frame.dart';
import '../../widgets/rhythm_segment_card.dart';
import '../../widgets/rhythm_surface.dart';
import 'rhythm_edit_controller.dart';
import 'widgets/rhythm_segment_sheet.dart';

/// 新增与编辑共用的表单，返回前保护未保存内容。
final class RhythmEditPage extends StatefulWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmEditPage({super.key});
  @override
  State<RhythmEditPage> createState() => _RhythmEditPageState();
}

final class _RhythmEditPageState extends State<RhythmEditPage> {
  /// 拥有片段草稿和保存规则的编辑控制器。
  final controller = Get.find<RhythmEditController>();
  late final TextEditingController _name = TextEditingController(
    text: controller.name,
  );
  bool _leaving = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _back() async {
    if (_leaving || controller.saving.value) return;
    if (controller.dirty.value &&
        !await rhythmConfirm(
          'Discard your unsaved changes?',
          confirm: 'Discard',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => Get.back<void>());
  }

  Future<void> _sheet({int? index}) async {
    if (controller.loading.value || controller.capabilities.isEmpty) return;
    if (index == null && controller.segments.length >= 30) {
      controller.error.value = 'Maximum 30 segments reached.';
      return;
    }
    if (index != null) {
      try {
        RhythmStep.decode(controller.segments[index]);
      } on FormatException catch (e) {
        controller.error.value = e.message;
        return;
      }
    }
    await Get.bottomSheet<void>(
      RhythmSegmentSheet(controller: controller, index: index),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppRhythmStyle.glass,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0x668E88A3), width: 2),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22)),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: RhythmPageFrame(
      onBack: _back,
      body: ListView(
        children: [
          const Text('Rhythm name', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Obx(
            () => TextField(
              controller: _name,
              onChanged: controller.setName,
              maxLength: 64,
              enabled: !controller.saving.value,
              style: const TextStyle(fontSize: 18),
              decoration: _input('Please enter').copyWith(
                errorText: controller.nameError.value,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Applicable Devices', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Obx(
            () => InputDecorator(
              decoration: _input('Select a device'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: controller.selectedModel.value,
                  isDense: true,
                  hint: const Text('Select a device'),
                  isExpanded: true,
                  dropdownColor: AppRhythmStyle.panel,
                  items: controller.models
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: controller.loading.value || controller.saving.value
                      ? null
                      : (value) async {
                          if (value == null ||
                              value == controller.selectedModel.value) {
                            return;
                          }
                          if (controller.segments.isNotEmpty &&
                              !await rhythmConfirm(
                                'Changing the device will remove all current segments. Continue?',
                              )) {
                            return;
                          }
                          await controller.selectModel(value);
                        },
                ),
              ),
            ),
          ),
          Obx(
            () => controller.loading.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  )
                : const SizedBox.shrink(),
          ),
          Obx(() => RhythmError(controller.error.value)),
          Obx(
            () =>
                controller.error.value != null &&
                    controller.capabilities.isEmpty
                ? TextButton(
                    onPressed: controller.load,
                    child: const Text('Retry'),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),
          const Text('Set rhythm', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Obx(
            () => Column(
              children: [
                for (var i = 0; i < controller.segments.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: RhythmSegmentCard(
                      segment: controller.segments[i],
                      capabilities: controller.capabilities,
                      onEdit: () => _sheet(index: i),
                      onDelete: () => controller.deleteSegment(i),
                    ),
                  ),
              ],
            ),
          ),
          Obx(
            () => Opacity(
              opacity: controller.capabilities.isEmpty ? .5 : 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () => _sheet(),
                child: const RhythmSurface(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_box_outlined),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Add device rhythm',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      footer: Obx(
        () => AppLiquidGlassButton(
          label: 'Save',
          width: double.infinity,
          isLoading: controller.saving.value,
          onPressed: controller.loading.value
              ? null
              : () async {
                  if (await controller.save() && mounted) {
                    setState(() => _leaving = true);
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => Get.back(result: true),
                    );
                  }
                },
        ),
      ),
    ),
  );
}
