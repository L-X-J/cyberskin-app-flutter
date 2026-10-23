// 自由控制加热横向组件（Heat Bar Control）；
// 对应 heat-b.png，提供全宽卡片、能力提示、液态玻璃开关和可监听的开关状态。

import 'package:cyberskin_app/core/extensions/string_extensions.dart';
import 'package:cyberskin_app/core/theme/app_theme.dart';
import 'package:cyberskin_app/core/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../domain/entities/free_control_layout.dart';

/// 加热 1x2 横向开关卡片（对应 heat-b.png，标准规格 358x105）。
final class HeatBarControl extends StatefulWidget {
  /// 创建横向加热开关卡片。
  const HeatBarControl({
    super.key,
    required this.config,
    this.initialValue = false,
    this.onChanged,
    this.height = 105,
  });

  /// 模块配置。
  final FreeControlComponentConfig config;

  /// 初始开关状态。
  final bool initialValue;

  /// 开关状态变化回调。
  final ValueChanged<bool>? onChanged;

  /// 外部约束高度。
  final double? height;

  @override
  State<HeatBarControl> createState() => _HeatBarControlState();
}

final class _HeatBarControlState extends State<HeatBarControl> {
  late bool _isOn = widget.initialValue;

  @override
  void didUpdateWidget(covariant HeatBarControl oldWidget) {
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
    return Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AppTheme.freeControlBoxDecoration,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                color: Color(0xFFF4C18C),
                size: 28,
              ),
              const SizedBox(width: 10),
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
          Row(
            children: [
              const SizedBox(width: 30),
              // 状态文案与火焰图标作为一组占据开关左侧的剩余宽度：文案可收缩并省略，
              // 避免窄屏或大字号下溢出，同时保持开关贴右。
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _isOn ? 'Heating' : 'Not enabled',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppImage.load(
                      'device_modules/heat/heat'.assetsPng,
                      width: 50,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 130,
                child: _HeatSwitch(isOn: _isOn, onTap: _toggle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 横向卡片复用的液态玻璃开关，保持与 HeatToggleControl 相同的交互语义。
final class _HeatSwitch extends StatelessWidget {
  const _HeatSwitch({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      child: LGButton.custom(
        onTap: onTap,
        width: double.infinity,
        height: 48,
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
              child: Container(
                width: 60,
                height: double.infinity,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFFD35B4A),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: isOn ? Alignment.centerLeft : Alignment.centerRight,
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
    );
  }
}
