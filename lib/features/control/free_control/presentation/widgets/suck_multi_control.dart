// 自由控制吸附/吮吸多模式组件（Suck Multi Control）；
// 对应 suck-b.png，使用 Canvas 重绘 Group 6.svg / img_group_90.svg，
// 并在开启状态下以波纹动画表达吸气、放气状态，模式按钮来自后台配置并流式排列。

import 'dart:math' as math;

import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/free_control_layout.dart';

/// 设备上报的吮吸运动状态；未上报时保持 idle，不播放波纹动画。
enum SuckMotionState {
  /// 没有设备上报的吸气/放气状态。
  idle,

  /// 设备正在吸气。
  inhaling,

  /// 设备正在放气。
  exhaling,
}

/// 吮吸 2x2 多模式卡片（对应 suck-b.png，标准规格 358x231）。
final class SuckMultiControl extends StatefulWidget {
  /// 创建吮吸多模式卡片。
  const SuckMultiControl({
    super.key,
    required this.config,
    this.initialValue = true,
    this.initialMode,
    this.motionState = SuckMotionState.idle,
    this.onChanged,
    this.onModeChanged,
    this.height,
  });

  /// 模块配置，模式列表由 [FreeControlComponentConfig.modes] 提供。
  final FreeControlComponentConfig config;

  /// 初始开关状态；对应设计稿的 ON 基准状态。
  final bool initialValue;

  /// 初始模式；为空时采用后台列表第一项。
  final String? initialMode;

  /// 设备当前吸气/放气状态；未上报时不播放波纹。
  final SuckMotionState motionState;

  /// 开关状态变化回调。
  final ValueChanged<bool>? onChanged;

  /// 模式变化回调。
  final ValueChanged<String>? onModeChanged;

  /// 外部约束高度。
  final double? height;

  /// 根据后台模式数量估算布局所需高度，供自由控制网格分配空间。
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
    return 115 + rows * 60 + (rows - 1) * 8;
  }

  @override
  State<SuckMultiControl> createState() => _SuckMultiControlState();
}

final class _SuckMultiControlState extends State<SuckMultiControl>
    with SingleTickerProviderStateMixin {
  late bool _isOn = widget.initialValue;
  late String? _selectedMode = widget.initialMode ?? _firstMode;
  late final AnimationController _waveController;

  String? get _firstMode =>
      widget.config.modes.isEmpty ? null : widget.config.modes.first;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncWaveAnimation();
  }

  @override
  void didUpdateWidget(covariant SuckMultiControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _setEnabled(widget.initialValue, notify: false);
    }
    if (widget.motionState != oldWidget.motionState) _syncWaveAnimation();
    if (widget.config.modes != oldWidget.config.modes &&
        !widget.config.modes.contains(_selectedMode)) {
      _selectedMode = _firstMode;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _setEnabled(bool value, {required bool notify}) {
    setState(() => _isOn = value);
    _syncWaveAnimation();
    if (notify) widget.onChanged?.call(value);
  }

  void _syncWaveAnimation() {
    final shouldAnimate = _isOn && widget.motionState != SuckMotionState.idle;
    if (shouldAnimate) {
      if (!_waveController.isAnimating) _waveController.repeat(reverse: true);
    } else {
      _waveController.stop();
      _waveController.value = 0;
    }
  }

  /// 状态行文案：关闭时提示未启用，开启后显示设备上报的吸气/放气状态。
  String get _statusText {
    if (!_isOn) return 'Not enabled';
    return switch (widget.motionState) {
      SuckMotionState.inhaling => 'Inhaling',
      SuckMotionState.exhaling => 'Exhaling',
      SuckMotionState.idle => 'Enabled',
    };
  }

  void _selectMode(String mode) {
    setState(() => _selectedMode = mode);
    widget.onModeChanged?.call(mode);
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
                const Icon(
                  Icons.album_outlined,
                  color: Color(0xFFFFA4D9),
                  size: 28,
                ),
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
                    _statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) => CustomPaint(
                    size: const Size(52, 52),
                    painter: _SuckWaveLogoPainter(
                      progress: _waveController.value,
                      enabled: _isOn,
                      motionState: widget.motionState,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 144,
                  child: _SuckMultiSwitch(
                    isOn: _isOn,
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
    final modes = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final mode in widget.config.modes)
          _SuckModeButton(
            label: mode,
            selected: mode == _selectedMode,
            onTap: () => _selectMode(mode),
          ),
      ],
    );
    if (widget.height == null) return modes;
    return modes;
  }
}

/// Canvas 重绘 img_group_90.svg 的吮吸开关按钮片段。
final class _SuckMultiSwitch extends StatelessWidget {
  const _SuckMultiSwitch({required this.isOn, required this.onTap});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
                  width: 69,
                  height: 40,
                  child: CustomPaint(painter: _SuckMultiSegmentPainter()),
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
                      color: isOn ? Colors.white : const Color(0xFFA6A1C1),
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

final class _SuckMultiSegmentPainter extends CustomPainter {
  const _SuckMultiSegmentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 69, size.height / 40);
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, 69, 40, const Radius.circular(20)),
      Paint()..color = const Color(0xFF721177),
    );
    final inner = RRect.fromLTRBR(14, 8, 56, 32, const Radius.circular(12));
    canvas.drawRRect(
      inner,
      Paint()
        ..color = const Color(0x80BF31C7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.8),
    );
    canvas.drawRRect(inner, Paint()..color = const Color(0x24BF31C7));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SuckMultiSegmentPainter oldDelegate) => false;
}

/// Canvas 重绘 Group 6.svg，并在开启时绘制吸气/放气的向外、向内波纹。
final class _SuckWaveLogoPainter extends CustomPainter {
  const _SuckWaveLogoPainter({
    required this.progress,
    required this.enabled,
    required this.motionState,
  });

  final double progress;
  final bool enabled;
  final SuckMotionState motionState;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2;
    final scale = radius / 26;
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Group 6.svg 的内阴影叠加后呈现“中心深紫、边缘紫红”的圆形渐变。
    // 用径向渐变直接表达最终视觉，避免把滤镜错误地渲染成一块平面深色。
    final circleBounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.center,
          radius: 0.72,
          colors: [
            Color(0xFF503C61),
            Color(0xFFC759AF),
            Color(0xFF8B3F85),
            Color(0xFFC759AF),
          ],
          stops: [0.0, 0.52, 0.82, 1.0],
        ).createShader(circleBounds),
    );
    canvas.save();
    canvas.clipPath(circlePath);

    // filter0_ii effect1：白色 25% 的柔和内侧反光。
    canvas.drawCircle(
      center,
      radius - 1.0 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20.0 * scale),
    );

    // 动态波纹只作为设备状态的附加层，不改变 Group 6.svg 的静态主体颜色。
    if (enabled && motionState != SuckMotionState.idle) {
      final waveColor = motionState == SuckMotionState.inhaling
          ? const Color(0xFFFF9BDA)
          : const Color(0xFFC18BFF);
      for (var index = 0; index < 3; index++) {
        final phase = (progress + index / 3) % 1;
        final waveRadius = radius * (0.24 + phase * 0.66);
        final alpha = ((1 - phase) * 0.48).clamp(0.0, 1.0);
        canvas.drawCircle(
          center,
          waveRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * scale
            ..color = waveColor.withValues(alpha: alpha),
        );
      }
    }
    canvas.restore();

    // SVG 的两层白色同心圆；目标图使用更清晰的 3px 级描边。
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..color = Colors.white;
    canvas.drawCircle(center, radius * 0.394, ringPaint);
    canvas.drawCircle(center, radius * 0.183, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _SuckWaveLogoPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.enabled != enabled ||
      oldDelegate.motionState != motionState;
}

final class _SuckModeButton extends StatelessWidget {
  const _SuckModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppLiquidGlassButton(
      label: label,
      onPressed: onTap,
      height: 48,
      variant: AppLiquidGlassButtonVariant.translucent,
      glassSettings: LiquidGlassSettings(
        glassColor: const Color(0xFFF8F8F8).withAlpha(50),
      ),
    );
  }
}
