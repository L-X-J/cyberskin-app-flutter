// 通用模式切换 2x2 卡片（伸缩/震动 mode_2x2）；
// 无波纹动画，模式按钮来自后台配置，档位选中状态由 gearCurrent 驱动。
// 主题色 accentColor/glowColor 由调用方（薄封装）注入。

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_liquid_glass_button.dart';
import '../../domain/entities/free_control_layout.dart';

/// 伸缩/震动 2x2 模式切换卡片（对应 telescopic_mode_2x2 / vibration_mode_2x2）。
///
/// 模式列表来自 [FreeControlComponentConfig.modes]，选中档位用 1-based [initialGear]
/// 表示，回调 [onGearChanged] 传出选中档位号（与协议模式号对齐）。
final class ModeMultiControl extends StatefulWidget {
  /// 创建模式切换卡片。
  const ModeMultiControl({
    super.key,
    required this.config,
    required this.accentColor,
    required this.glowColor,
    this.height,
    this.initialValue = true,
    this.initialGear,
    this.onChanged,
    this.onGearChanged,
  });

  /// 模块配置；模式名称由 [FreeControlComponentConfig.modes] 提供。
  final FreeControlComponentConfig config;

  /// 主题强调色（按钮选中态、图标颜色）。
  final Color accentColor;

  /// 发光色（按钮选中态外发光）。
  final Color glowColor;

  /// 外部约束高度。
  final double? height;

  /// 初始开关状态。
  final bool initialValue;

  /// 初始选中档位（1-based）；为 null 时采用 [FreeControlComponentConfig.gearCurrent]。
  final int? initialGear;

  /// 开关状态变化回调。
  final ValueChanged<bool>? onChanged;

  /// 档位选中回调（1-based 档位号）。
  final ValueChanged<int>? onGearChanged;

  /// 根据后台模式数量估算布局所需高度，供网格分配空间。
  ///
  /// [availableWidth] 为卡片实际可用宽度，默认 358 dp（设计稿基准）。
  /// 开关关闭时的折叠高度：顶部 padding + 标题行 + 间距 + 状态行 + 底部 padding。
  static const double _collapsedHeight = 116.0;

  static double estimatedHeight(
    FreeControlComponentConfig config, {
    double availableWidth = 358.0,
    bool isOn = true,
  }) {
    // 关闭状态下不展示模式按钮，直接返回折叠高度。
    if (!isOn || config.modes.isEmpty) return _collapsedHeight;
    var rows = 1;
    var rowWidth = 0.0;
    final innerWidth = availableWidth - 32; // 左右各 16px padding
    for (final mode in config.modes) {
      final buttonWidth = math.max(96.0, mode.length * 12.0 + 36.0);
      if (rowWidth > 0 && rowWidth + 10 + buttonWidth > innerWidth) {
        rows++;
        rowWidth = buttonWidth;
      } else {
        rowWidth += (rowWidth == 0 ? 0 : 10) + buttonWidth;
      }
    }
    return 115 + rows * 90 + (rows - 1) * 8;
  }

  @override
  State<ModeMultiControl> createState() => _ModeMultiControlState();
}

final class _ModeMultiControlState extends State<ModeMultiControl> {
  late bool _isOn = widget.initialValue;
  // 设备未上报时默认选中第 1 档，而非后台配置的 gearCurrent（避免默认高亮非第一项）。
  late int? _selectedGear = widget.initialGear ?? 1;

  @override
  void didUpdateWidget(covariant ModeMultiControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _setEnabled(widget.initialValue, notify: false);
    }
    // 只在设备真实上报了档位时（initialGear != null）才用上报值纠正显示；
    // 若上报值为 null（设备未回报），保留用户刚点击的乐观回显，避免闪烁。
    if (widget.initialGear != null &&
        widget.initialGear != oldWidget.initialGear) {
      setState(() => _selectedGear = widget.initialGear);
    }
  }

  void _setEnabled(bool value, {required bool notify}) {
    setState(() => _isOn = value);
    if (notify) widget.onChanged?.call(value);
  }

  void _selectGear(int gear) {
    setState(() => _selectedGear = gear);
    widget.onGearChanged?.call(gear);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 关闭时折叠到内容高度，避免卡片内出现大片空白；
      // 开启时使用网格分配的固定高度以确保模式按钮完整显示。
      height: _isOn ? widget.height : null,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: AppTheme.freeControlBoxDecoration,
      child: LiquidGlassLayer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, color: widget.accentColor, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.config.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isOn ? 'Enabled' : 'Not enabled',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 144,
                  child: _ModeMultiSwitch(
                    isOn: _isOn,
                    accentColor: widget.accentColor,
                    onTap: () => _setEnabled(!_isOn, notify: true),
                  ),
                ),
              ],
            ),
            if (_isOn && widget.config.modes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildModeContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeContent() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < widget.config.modes.length; i++)
          _ModeModeButton(
            label: widget.config.modes[i],
            selected: _selectedGear == i + 1,
            accentColor: widget.accentColor,
            glowColor: widget.glowColor,
            onTap: () => _selectGear(i + 1),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 内部私有组件
// ─────────────────────────────────────────────────────────────────────────────

/// ON/OFF 拨动开关，Canvas 重绘滑块片段，动画对齐 SuckToggleControl._SuckSwitch。
final class _ModeMultiSwitch extends StatelessWidget {
  const _ModeMultiSwitch({
    required this.isOn,
    required this.accentColor,
    required this.onTap,
  });

  final bool isOn;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      child: Semantics(
        button: true,
        toggled: isOn,
        label: isOn ? 'on' : 'off',
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
                alignment:
                    isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: 62,
                    height: 40,
                    child: CustomPaint(
                      painter: _ModeToggleSegmentPainter(
                        accentColor: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment:
                      isOn ? Alignment.centerLeft : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      isOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color:
                            isOn ? Colors.white : const Color(0xFFA6A1C1),
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

/// Canvas 重绘滑块片段；外圆角矩形 + 内辉光，主题色由 [accentColor] 注入。
final class _ModeToggleSegmentPainter extends CustomPainter {
  const _ModeToggleSegmentPainter({required this.accentColor});

  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 62;
    final scaleY = size.height / 40;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 外层深色圆角矩形底色
    final outerColor = Color.lerp(accentColor, Colors.black, 0.72)!;
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, 62, 40, const Radius.circular(20)),
      Paint()..color = outerColor,
    );

    // 内层辉光：模糊层 + 半透明层，颜色取自 accentColor
    final inner = RRect.fromLTRBR(10, 8, 52, 32, const Radius.circular(12));
    canvas.drawRRect(
      inner,
      Paint()
        ..color = accentColor.withAlpha(0x80)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.8),
    );
    canvas.drawRRect(inner, Paint()..color = accentColor.withAlpha(0x24));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ModeToggleSegmentPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}

/// 模式选择按钮；选中时显示主题强调色渐变背景和外发光。
final class _ModeModeButton extends StatelessWidget {
  const _ModeModeButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.glowColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final Color glowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppLiquidGlassButton(
      label: label,
      onPressed: onTap,
      height: 48,
      variant: AppLiquidGlassButtonVariant.translucent,
      // 选中时用强调色作为玻璃填充；未选中时保持默认透明玻璃。
      fillColorOverride: selected ? accentColor.withValues(alpha: 0.30) : null,
      // 选中时文案用全白，未选中时用半透明白。
      labelColorOverride: selected
          ? Colors.white
          : Colors.white.withValues(alpha: 0.65),
      glassSettings: LiquidGlassSettings(
        glassColor: selected
            ? accentColor.withAlpha(50)
            : Colors.white.withAlpha(20),
        thickness: 30,
        lightIntensity: selected ? 0.75 : 0.55,
        ambientStrength: 0,
        saturation: 1,
      ),
    );
  }
}
