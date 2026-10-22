// 自定义片段时长输入；复用领域边界并保留非法输入供用户修正。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../domain/entities/rhythm_program.dart';

/// 自定义整数秒输入弹窗，提交有效值后返回秒数。
final class RhythmDurationDialog extends StatefulWidget {
  /// 初始秒数来自当前草稿。
  const RhythmDurationDialog({super.key, required this.initialValue});

  /// 当前草稿秒数。
  final int initialValue;

  @override
  State<RhythmDurationDialog> createState() => _RhythmDurationDialogState();
}

final class _RhythmDurationDialogState extends State<RhythmDurationDialog> {
  final _form = GlobalKey<FormState>();
  late String _draft = '${widget.initialValue}';

  void _submit() {
    if (_form.currentState!.validate()) Get.back(result: int.parse(_draft));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Duration in seconds'),
    scrollable: true,
    content: Form(
      key: _form,
      child: TextFormField(
        initialValue: _draft,
        autofocus: true,
        onChanged: (value) => _draft = value,
        onFieldSubmitted: (_) => _submit(),
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: RhythmStep.maxDurationSec.toString().length,
        decoration: const InputDecoration(
          labelText: 'Seconds',
          helperText:
              '${RhythmStep.minDurationSec}–${RhythmStep.maxDurationSec} seconds',
          errorMaxLines: 3,
        ),
        validator: (text) {
          final value = int.tryParse(text ?? '');
          return value != null && RhythmStep.isValidDuration(value)
              ? null
              : RhythmStep.durationError;
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Get.back<void>(),
        child: const Text('Cancel'),
      ),
      TextButton(onPressed: _submit, child: const Text('Confirm')),
    ],
  );
}
