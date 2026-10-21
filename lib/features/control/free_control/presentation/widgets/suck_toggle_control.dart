// 自由控制吸附/吮吸开关组件（Suck Toggle Control）；
// 对应 suck-a.png，提供 1x1 卡片布局、Canvas 重绘的 Group 28 开关和状态回调。

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/free_control_layout.dart';

/// 吸附/吮吸 1x1 开关卡片（对应 suck-a.png，标准规格 172x105）。
final class SuckToggleControl extends StatefulWidget {
  /// 创建吸附/吮吸开关卡片。
  const SuckToggleControl({
    super.key,
    required this.config,
    this.initialValue = true,
    this.onChanged,
    this.height,
  });

  /// 模块配置。
  final FreeControlComponentConfig config;

  /// 初始开关状态；对应 suck-a.png 的 ON 基准状态。
  final bool initialValue;

  /// 开关状态变化回调。
  final ValueChanged<bool>? onChanged;

  /// 外部约束高度；未指定时保持 172:105 比例。
  final double? height;

  @override
  State<SuckToggleControl> createState() => _SuckToggleControlState();
}

final class _SuckToggleControlState extends State<SuckToggleControl> {
  late bool _isOn = widget.initialValue;

  @override
  void didUpdateWidget(covariant SuckToggleControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅在外部状态（设备上报）真正变化时同步，避免覆盖用户刚点击、设备尚未回报的状态。
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() => _isOn = widget.initialValue);
    }
  }

  void _toggle() {
    final next = !_isOn;
    setState(() => _isOn = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: widget.height,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: AppTheme.freeControlBoxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.album_outlined,
                color: Color(0xFFB28AFF),
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.config.displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const Spacer(),
          _SuckSwitch(isOn: _isOn, onTap: _toggle),
        ],
      ),
    );

    return widget.height == null
        ? AspectRatio(aspectRatio: 172 / 105, child: card)
        : card;
  }
}

final class _SuckSwitch extends StatelessWidget {
  const _SuckSwitch({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      child: Semantics(
        button: true,
        toggled: isOn,
        label: 'Suck ${isOn ? 'on' : 'off'}',
        child: LGButton.custom(
          onTap: onTap,
          width: double.infinity,
          height: 52,
          useOwnLayer: true,
          settings: LiquidGlassSettings(
            glassColor: const Color(0xFFF8F8F8).withAlpha(50),
          ),
          quality: LGQuality.standard,
          shape: const LiquidRoundedRectangle(borderRadius: 90),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: SizedBox(
                    width: 62,
                    height: 40,
                    child: CustomPaint(painter: _SuckToggleSegmentPainter()),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: isOn
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      isOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isOn ? Colors.white : const Color(0xFFA6A1C1),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Canvas 重绘 Group 28.svg 的紫色按钮片段。
final class _SuckToggleSegmentPainter extends CustomPainter {
  const _SuckToggleSegmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 62;
    final scaleY = size.height / 40;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final outer = RRect.fromLTRBR(0, 0, 62, 40, const Radius.circular(20));
    canvas.drawRRect(outer, Paint()..color = const Color(0xFF2E0E72));

    final inner = RRect.fromLTRBR(10, 8, 52, 32, const Radius.circular(12));
    final glowPaint = Paint()
      ..color = const Color(0x806E49BF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.8);
    canvas.drawRRect(inner, glowPaint);
    canvas.drawRRect(inner, Paint()..color = const Color(0x246E49BF));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SuckToggleSegmentPainter oldDelegate) => false;
}
