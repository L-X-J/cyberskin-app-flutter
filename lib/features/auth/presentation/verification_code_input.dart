// 验证码输入控件：一个真实编辑框覆盖 3+3 分组格子，支持粘贴、删改及自动填充。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 六位数字输入，六个格子共用一个编辑值，不维护六份焦点或输入状态。
final class VerificationCodeInput extends StatefulWidget {
  /// 创建分组输入控件；外部清空 value 会同步重置编辑框。
  const VerificationCodeInput({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  /// 当前验证码。
  final String value;

  /// 是否允许输入。
  final bool enabled;

  /// 数字输入回调，最多六位。
  final ValueChanged<String> onChanged;

  /// 键盘提交事件。
  final VoidCallback onSubmitted;

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

final class _VerificationCodeInputState extends State<VerificationCodeInput> {
  late final TextEditingController _editing = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refreshFocus);
  }

  /// 焦点只改变格子轮廓，不触发认证事件。
  void _refreshFocus() => setState(() {});

  @override
  void didUpdateWidget(VerificationCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_editing.text != widget.value) {
      _editing.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_refreshFocus);
    _focus.dispose();
    _editing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = constraints.maxWidth >= 300 ? 5.0 : 4.0;
                // 43px 格子为设计上限；窄屏仅收缩格宽，不缩放文字或整页。
                final cellWidth = ((constraints.maxWidth - 30 - gap * 4) / 6)
                    .clamp(0.0, 43.0);
                return Row(
                  children: [
                    for (var index = 0; index < 6; index++) ...[
                      if (index == 3)
                        const SizedBox(
                          width: 30,
                          child: Center(child: Text('-')),
                        )
                      else if (index > 0)
                        SizedBox(width: gap),
                      Container(
                        width: cellWidth,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              _focus.hasFocus &&
                                  index == widget.value.length.clamp(0, 5)
                              ? Border.all(
                                  color: AppColors.textOnAccent,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Text(
                          index < widget.value.length
                              ? widget.value[index]
                              : '',
                          style: AppTypography.subtitle.copyWith(
                            color: AppColors.surfaceDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        // 保留原生编辑、选择与自动填充，只把字形交给下方六格绘制。
        TextField(
          key: const ValueKey('verification-code-field'),
          controller: _editing,
          focusNode: _focus,
          // 验证码步骤挂载后立即弹出数字键盘，不要求再次点击六格输入。
          autofocus: true,
          enabled: widget.enabled,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: widget.onChanged,
          onSubmitted: (_) => widget.onSubmitted(),
          showCursor: false,
          enableInteractiveSelection: false,
          style: const TextStyle(color: Colors.transparent),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            labelText: '6-digit verification code',
            floatingLabelBehavior: FloatingLabelBehavior.never,
            labelStyle: TextStyle(color: Colors.transparent),
          ),
        ),
      ],
    ),
  );
}
