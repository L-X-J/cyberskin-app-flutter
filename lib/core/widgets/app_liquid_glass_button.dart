// 公共液态玻璃按钮：统一玻璃背景、按压形变、内辉光及可访问交互。
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
  /// 粉紫填充与淡紫内辉光。
  highlighted,

  /// 深色填充与单层紫色内阴影。
  subtle,

  /// 紧凑操作使用的白色 12% 透明玻璃填充。
  translucent,
}

/// 多页面共用的胶囊液态玻璃按钮，默认采用设计师确认的填充与内辉光。
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
    this.width,
    this.maxWidth,
    this.borderRadius,
    this.icon,
    this.leadingIcon,
    this.leadingWidget,
    this.child,
    this.iconSize = 24,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 24),
    this.textStyle = AppTypography.primaryButton,
    this.quality = LGQuality.standard,
    this.glassSettings = const LiquidGlassSettings(
      glassColor: Colors.transparent,
      thickness: 30,
      lightIntensity: 0.65,
      ambientStrength: 0,
      saturation: 1,
    ),
    this.fillColorOverride,
    this.labelColorOverride,
  }) : assert(height >= 20),
       assert(iconSize > 0),
       assert(icon == null || child == null),
       assert(leadingIcon == null || child == null),
       assert(leadingWidget == null || child == null),
       assert(leadingIcon == null || leadingWidget == null);

  /// 按钮显示与无障碍名称。
  final String label;

  /// 操作回调，为空时禁用。
  final VoidCallback? onPressed;

  /// 已确认的表面变体，默认使用淡紫内辉光款。
  final AppLiquidGlassButtonVariant variant;

  /// 覆盖变体默认填充色；为空时使用 [fillColor]。
  final Color? fillColorOverride;

  /// 覆盖文案颜色；为空时使用 [textStyle] 中的颜色。
  final Color? labelColorOverride;

  /// 由变体统一选择包含不透明度的主题填充，页面不复制色值。
  Color get fillColor =>
      fillColorOverride ??
      switch (variant) {
        AppLiquidGlassButtonVariant.highlighted =>
          AppColors.liquidGlassButtonFill,
        AppLiquidGlassButtonVariant.subtle =>
          AppColors.liquidGlassButtonSubtleFill,
        AppLiquidGlassButtonVariant.translucent =>
          AppColors.liquidGlassButtonTranslucentFill,
      };

  /// 按图层顺序排列的内阴影，不包含外投影。
  List<AppEffectSpec> get innerShadows => switch (variant) {
    AppLiquidGlassButtonVariant.highlighted => const [
      AppEffects.liquidGlassButtonInnerGlow,
    ],
    AppLiquidGlassButtonVariant.subtle => const [
      AppEffects.liquidGlassButtonSubtleInnerGlow,
    ],
    AppLiquidGlassButtonVariant.translucent => const [],
  };

  /// 加载时收拢为图标尺寸并禁止重复操作。
  final bool isLoading;

  /// 按钮高度；默认 58，紧凑操作可降至 32。
  final double height;

  /// 固定宽度；为空时根据内容自适应。
  final double? width;

  /// 可选最大宽度，约束自适应计算后的按钮宽度。
  final double? maxWidth;

  /// 圆角；为空时使用高度的一半，呈胶囊形。
  final double? borderRadius;

  /// 可选图标；提供时优先渲染为图标操作。
  final IconData? icon;

  /// 文案左侧图标；与 [icon] 的纯图标模式互斥。
  final IconData? leadingIcon;

  /// 文案左侧的自定义 Widget，优先级高于 [leadingIcon]，与 [icon]、[child] 互斥。
  ///
  /// 适用于需要自定义图标渲染（如带颜色的 SVG、动画图标）的紧凑按钮场景。
  /// 宽度测量时按 [iconSize] 估算占位，调用方可通过 [width] 固定宽度以避免偏差。
  final Widget? leadingWidget;

  /// 自定义按钮内容；用于仍需保留产品素材的液态玻璃小按钮。
  ///
  /// 与 [icon]、[leadingIcon] 互斥。按钮语义仍由 [label] 提供，内容本身不
  /// 再参与语义树，避免图片中的装饰信息覆盖可访问名称。
  final Widget? child;

  /// 图标大小。
  final double iconSize;

  /// 文案的水平留白；图标模式不使用该参数。
  final EdgeInsetsGeometry contentPadding;

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

  /// 所有有效激活共用轻触反馈；不等待平台响应，避免延迟业务回调。
  void _activate() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = _resolvedTextStyle(context);
    final Widget content;
    if (widget.isLoading) {
      content = const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textOnAccent,
        ),
      );
    } else if (widget.child case final child?) {
      content = child;
    } else if (widget.icon case final icon?) {
      content = Icon(
        icon,
        size: widget.iconSize,
        color: widget.textStyle.color ?? AppColors.textOnAccent,
      );
    } else {
      content = Padding(
        padding: widget.contentPadding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.leadingWidget case final lw?) ...[
              lw,
              const SizedBox(width: 6),
            ] else if (widget.leadingIcon case final icon?) ...[
              Icon(
                icon,
                size: widget.iconSize,
                color: widget.textStyle.color ?? AppColors.textOnAccent,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedW = _resolvedWidth(context, constraints, textStyle);
        final radius = widget.borderRadius ?? widget.height / 2;
        return SizedBox(
          width: resolvedW,
          height: widget.height,
          child: FocusableActionDetector(
            enabled: _enabled,
            onShowFocusHighlight: (value) => setState(() => _showFocus = value),
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  _activate();
                  return null;
                },
              ),
            },
            child: DecoratedBox(
              // FakeGlass multiplies dark tints against its backdrop. Painting
              // the prescribed tint underneath keeps its value stable on black.
              decoration: BoxDecoration(
                color: widget.fillColor,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: LGButton.custom(
                width: resolvedW,
                height: widget.height,
                label: widget.isLoading
                    ? '${widget.label}, loading'
                    : widget.label,
                enabled: _enabled,
                onTap: _activate,
                useOwnLayer: true,
                quality: widget.quality,
                settings: widget.glassSettings.copyWith(
                  glassColor: Colors.transparent,
                ),
                shape: LiquidRoundedRectangle(borderRadius: radius),
                child: ExcludeSemantics(
                  child: SizedBox.expand(
                    child: CustomPaint(
                      painter: _GlassInnerShadowPainter(
                        innerShadows: widget.innerShadows,
                        borderRadius: radius,
                      ),
                      foregroundPainter: _showFocus && _enabled
                          ? const _FocusRingPainter()
                          : null,
                      child: Center(child: content),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 继承主题字体，确保测量宽度与实际文字绘制一致。
  TextStyle _resolvedTextStyle(BuildContext context) =>
      widget.textStyle.copyWith(
        color: widget.labelColorOverride ?? widget.textStyle.color,
        decoration: widget.textStyle.decoration ?? TextDecoration.none,
        fontFamily:
            widget.textStyle.fontFamily ??
            Theme.of(context).textTheme.labelLarge?.fontFamily,
      );

  /// 紧凑文字按钮在 Row 等无界宽度中按内容定宽，并受最大宽度限制。
  ///
  /// 优先级：显式 [width] > [maxWidth]（直接使用，确保文字完整显示）> TextPainter 自适应。
  /// TextPainter 路径仅在未指定 [width]/[maxWidth] 时启用，此时以测量值为准；
  /// 调用方若遭遇字体加载时序差异导致的细微偏差，应改用 [width] 固定宽度。
  double _resolvedWidth(
    BuildContext context,
    BoxConstraints constraints,
    TextStyle textStyle,
  ) {
    if (widget.width != null) return widget.width!;
    if (widget.isLoading || widget.icon != null) return widget.height;
    final textPainter = TextPainter(
      text: TextSpan(text: widget.label, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final leadingWidth =
        (widget.leadingIcon != null || widget.leadingWidget != null)
        ? widget.iconSize + 6
        : 0;
    final measuredWidth =
        textPainter.width.ceilToDouble() +
        12 +
        leadingWidth +
        widget.contentPadding.horizontal;
    var resolved = measuredWidth;
    if (widget.maxWidth case final maxW?) {
      resolved = resolved.clamp(0.0, maxW);
    }
    if (constraints.hasBoundedWidth) {
      resolved = resolved.clamp(0.0, constraints.maxWidth);
    }
    return resolved;
  }
}

/// 仅补充设计要求的内阴影；玻璃 tint 和外缘由 LGButton 自己绘制。
final class _GlassInnerShadowPainter extends CustomPainter {
  _GlassInnerShadowPainter({
    required List<AppEffectSpec> innerShadows,
    required this.borderRadius,
  }) : innerShadows = List.unmodifiable(innerShadows),
       assert(
         innerShadows.every(
           (effect) => effect.kind == AppEffectKind.innerShadow,
         ),
       );

  final List<AppEffectSpec> innerShadows;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shape = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    canvas.save();
    canvas.clipRRect(shape);
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
  bool shouldRepaint(covariant _GlassInnerShadowPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
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
