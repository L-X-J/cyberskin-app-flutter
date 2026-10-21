// 自由控制加热开关组件（Heat Toggle Control）；
// 对应 heat-a.png，提供 1x1 卡片布局、液态玻璃开关和可监听的开关状态。

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/free_control_layout.dart';

/// 加热 1x1 开关卡片（对应 heat-a.png，标准规格 172x105）。
final class HeatToggleControl extends StatefulWidget {
  /// 创建加热开关卡片。
  const HeatToggleControl({
    super.key,
    required this.config,
    this.initialValue = false,
    this.onChanged,
    this.height,
  });

  /// 模块配置。
  final FreeControlComponentConfig config;

  /// 初始开关状态。
  final bool initialValue;

  /// 开关状态变化回调。
  final ValueChanged<bool>? onChanged;

  /// 外部约束高度；未指定时保持 172:105 比例。
  final double? height;

  @override
  State<HeatToggleControl> createState() => _HeatToggleControlState();
}

final class _HeatToggleControlState extends State<HeatToggleControl> {
  late bool _isOn = widget.initialValue;

  @override
  void didUpdateWidget(covariant HeatToggleControl oldWidget) {
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
                Icons.local_fire_department_outlined,
                color: Color(0xFFFF6538),
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
          _HeatSwitch(isOn: _isOn, onTap: _toggle),
        ],
      ),
    );

    return widget.height == null
        ? AspectRatio(aspectRatio: 172 / 105, child: card)
        : card;
  }
}

/// 加热卡片共用的液态玻璃开关。
final class _HeatSwitch extends StatelessWidget {
  const _HeatSwitch({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      child: Semantics(
        button: true,
        toggled: isOn,
        label: 'Heat ${isOn ? 'on' : 'off'}',
        child: LGButton.custom(
          label: '',
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
                    child: CustomPaint(painter: _HeatToggleSegmentPainter()),
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
                        color: isOn ? Colors.white70 : const Color(0xFFA1A1C7),
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

/// Canvas 重绘 Group 27.svg 的红色按钮片段。
///
/// SVG 的几何为 62x40 圆角矩形，内部 42x24 的半透明暗红色区域使用
/// 1.9 的高斯模糊，保留在 Flutter 中可控且跨平台一致的绘制结果。
final class _HeatToggleSegmentPainter extends CustomPainter {
  const _HeatToggleSegmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 62;
    final scaleY = size.height / 40;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final outer = RRect.fromLTRBR(0, 0, 62, 40, const Radius.circular(20));
    canvas.drawRRect(outer, Paint()..color = const Color(0xFFCA5C4A));

    final inner = RRect.fromLTRBR(10, 8, 52, 32, const Radius.circular(12));
    // SVG 的 feGaussianBlur 会把暗红色向四周柔化；先绘制一层稍宽的
    // 漫反射，再叠加极低透明度的本体，避免边缘看起来像硬切色块。
    final glowPaint = Paint()
      ..color = const Color(0x66C70000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.8);
    canvas.drawRRect(inner, glowPaint);

    final innerPaint = Paint()..color = const Color(0x24C70000);
    canvas.drawRRect(inner, innerPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeatToggleSegmentPainter oldDelegate) => false;
}
