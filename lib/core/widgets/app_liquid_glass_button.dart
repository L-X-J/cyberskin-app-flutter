// 公共液态玻璃按钮：统一玻璃背景、按压形变、双层内阴影及可访问交互。
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../theme/app_colors.dart';
import '../theme/app_effects.dart';
import '../theme/app_typography.dart';

/// 设计师确认的公共液态玻璃表面变体，不代表禁用或加载状态。
enum AppLiquidGlassButtonVariant {
  /// 粉紫填充、白色内高光和淡紫内阴影。
  highlighted,

  /// 深色填充与单层紫色内阴影。
  subtle,
}

/// 多页面共用的胶囊液态玻璃按钮，默认采用设计师确认的透明填充与双层内阴影。
///
/// standard 适用于滚动表单；premium 只用于固定布局且支持 shader 的环境。
/// 内阴影列表按设计图层从上到下排列，组件不承载业务状态或网络调用。
final class AppLiquidGlassButton extends StatefulWidget {
  /// 创建按钮；加载或回调为空时禁止点击和键盘激活。
  const AppLiquidGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppLiquidGlassButtonVariant.highlighted,
    this.isLoading = false,
    this.height = 58,
    this.textStyle = AppTypography.primaryButton,
    this.quality = LGQuality.standard,
    this.glassSettings = const LiquidGlassSettings(
      // 玻璃负责背景透射，表面颜色及静止高光由明确的设计规格决定。
      glassColor: Colors.transparent,
      lightIntensity: 0,
      ambientStrength: 0,
      saturation: 1,
    ),
  }) : assert(height >= 48);

  /// 按钮显示与无障碍名称。
  final String label;

  /// 操作回调，为空时禁用。
  final VoidCallback? onPressed;

  /// 已确认的表面变体，默认使用双层内阴影款。
  final AppLiquidGlassButtonVariant variant;

  /// 由变体统一选择包含不透明度的主题填充，页面不复制色值。
  Color get fillColor => switch (variant) {
    AppLiquidGlassButtonVariant.highlighted => AppColors.liquidGlassButtonFill,
    AppLiquidGlassButtonVariant.subtle => AppColors.liquidGlassButtonSubtleFill,
  };

  /// 按图层顺序排列的内阴影，不包含外投影。
  List<AppEffectSpec> get innerShadows => switch (variant) {
    AppLiquidGlassButtonVariant.highlighted => const [
      AppEffects.subtleInnerHighlight,
      AppEffects.liquidGlassButtonInnerGlow,
    ],
    AppLiquidGlassButtonVariant.subtle => const [
      AppEffects.liquidGlassButtonSubtleInnerGlow,
    ],
  };

  /// 加载时保持尺寸并禁止重复操作。
  final bool isLoading;

  /// 胶囊高度，最小触控高度为 48。
  final double height;

  /// 文案规格，字体族默认继承应用主题。
  final TextStyle textStyle;

  /// 滚动布局使用 standard；固定区域可显式选择 premium。
  final LGQuality quality;

  /// 玻璃光学参数，不替代填充与内阴影规格。
  final LiquidGlassSettings glassSettings;

  @override
  State<AppLiquidGlassButton> createState() => _AppLiquidGlassButtonState();
}

final class _AppLiquidGlassButtonState extends State<AppLiquidGlassButton> {
  bool _showFocus = false;

  /// 加载期间禁止键盘提交，保持与触控一致的契约。
  bool get _enabled => !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: _enabled,
      onShowFocusHighlight: (value) => setState(() => _showFocus = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (_enabled) widget.onPressed!();
            return null;
          },
        ),
      },
      child: LayoutBuilder(
        builder: (context, constraints) => LGButton.custom(
          width: constraints.maxWidth,
          height: widget.height,
          label: widget.isLoading ? '${widget.label}, loading' : widget.label,
          enabled: _enabled,
          onTap: () {
            if (_enabled) widget.onPressed!();
          },
          useOwnLayer: true,
          quality: widget.quality,
          settings: widget.glassSettings,
          shape: LiquidRoundedRectangle(borderRadius: widget.height / 2),
          child: ExcludeSemantics(
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _GlassSurfacePainter(
                  fillColor: widget.fillColor,
                  innerShadows: widget.innerShadows,
                ),
                foregroundPainter: _showFocus && _enabled
                    ? const _FocusRingPainter()
                    : null,
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnAccent,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: widget.textStyle.copyWith(
                              decoration:
                                  widget.textStyle.decoration ??
                                  TextDecoration.none,
                              fontFamily:
                                  widget.textStyle.fontFamily ??
                                  Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.fontFamily,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 表面规格绘制在玻璃层之后，文字不参与背景滤镜。
final class _GlassSurfacePainter extends CustomPainter {
  _GlassSurfacePainter({
    required this.fillColor,
    required List<AppEffectSpec> innerShadows,
  }) : innerShadows = List.unmodifiable(innerShadows),
       assert(
         innerShadows.every(
           (effect) => effect.kind == AppEffectKind.innerShadow,
         ),
       );

  final Color fillColor;
  final List<AppEffectSpec> innerShadows;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRRect(shape, Paint()..color = fillColor);
    for (final effect in innerShadows.reversed) {
      _paintInnerShadow(canvas, shape, effect);
    }
    canvas.restore();
  }

  /// 模糊反向遮罩产生内阴影；正扩展使镂空内缩，设计 blur / 2 映射为 sigma。
  void _paintInnerShadow(Canvas canvas, RRect shape, AppEffectSpec effect) {
    final sigma = (effect.blurMin ?? 0) / 2;
    final spread = effect.spreadMin ?? 0;
    final offset = Offset(effect.offsetX ?? 0, effect.offsetY ?? 0);
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        shape.outerRect.inflate(sigma * 4 + spread.abs() + offset.distance + 1),
      )
      ..addRRect(shape.deflate(spread).shift(offset));
    final paint = Paint()
      ..color = effect.color.withValues(alpha: effect.opacityMin ?? 1);
    if (sigma > 0) {
      paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma);
    }
    canvas.drawPath(mask, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassSurfacePainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      !listEquals(oldDelegate.innerShadows, innerShadows);
}

/// 键盘焦点增加可见轮廓，不改变静止状态的设计表面。
final class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(1),
        Radius.circular(size.height / 2),
      ),
      Paint()
        ..color = AppColors.textOnAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusRingPainter oldDelegate) => false;
}
