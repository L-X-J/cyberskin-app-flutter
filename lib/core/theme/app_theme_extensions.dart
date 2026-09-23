// ThemeExtension 扩展：让渐变、玻璃与辉光规格可从 BuildContext 的 Theme 获取。
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_blur.dart';
import 'app_colors.dart';
import 'app_effects.dart';
import 'app_gradients.dart';

/// 玻璃表面参数；ImageFilter sigma 使用标注为临时映射的 Flutter 默认值。
@immutable
final class AppGlassTokens {
  /// 创建玻璃表面设计 token。
  const AppGlassTokens({
    this.surfaceColor = AppColors.secondarySurface,
    this.blurSigma = AppBlur.glass * AppBlur.flutterSigmaScale,
    this.strongBlurSigma = AppBlur.glassStrong * AppBlur.flutterSigmaScale,
  });

  /// 玻璃材质表面颜色。
  final Color surfaceColor;

  /// 普通玻璃效果的 Flutter sigma。
  final double blurSigma;

  /// 强玻璃效果的 Flutter sigma。
  final double strongBlurSigma;

  /// 创建普通玻璃背景滤镜。
  ImageFilter get backgroundFilter =>
      ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);

  /// 创建强玻璃背景滤镜。
  ImageFilter get strongBackgroundFilter =>
      ImageFilter.blur(sigmaX: strongBlurSigma, sigmaY: strongBlurSigma);
}

/// 可经由 [ThemeData.extensions] 获取的品牌视觉能力。
@immutable
final class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  /// 创建主题扩展；默认引用本项目唯一标准视觉 token 集。
  const AppThemeExtension({
    this.gradients = AppGradients.standard,
    this.glass = const AppGlassTokens(),
    this.effects = const AppThemeEffects(),
  });

  /// 标准渐变集合。
  final AppGradients gradients;

  /// 玻璃表面和滤镜参数。
  final AppGlassTokens glass;

  /// 阴影与辉光效果规格。
  final AppThemeEffects effects;

  @override
  AppThemeExtension copyWith({
    AppGradients? gradients,
    AppGlassTokens? glass,
    AppThemeEffects? effects,
  }) => AppThemeExtension(
    gradients: gradients ?? this.gradients,
    glass: glass ?? this.glass,
    effects: effects ?? this.effects,
  );

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      gradients: AppGradients(
        purplePinkEmphasis: LinearGradient.lerp(
          gradients.purplePinkEmphasis,
          other.gradients.purplePinkEmphasis,
          t,
        )!,
        brandPinkPurple: LinearGradient.lerp(
          gradients.brandPinkPurple,
          other.gradients.brandPinkPurple,
          t,
        )!,
        grayPurpleTransition: LinearGradient.lerp(
          gradients.grayPurpleTransition,
          other.gradients.grayPurpleTransition,
          t,
        )!,
        blueSupport: LinearGradient.lerp(
          gradients.blueSupport,
          other.gradients.blueSupport,
          t,
        )!,
        darkPurpleAmbient: RadialGradient.lerp(
          gradients.darkPurpleAmbient,
          other.gradients.darkPurpleAmbient,
          t,
        )!,
        redWarningAmbient: RadialGradient.lerp(
          gradients.redWarningAmbient,
          other.gradients.redWarningAmbient,
          t,
        )!,
        purpleBackgroundAmbient: RadialGradient.lerp(
          gradients.purpleBackgroundAmbient,
          other.gradients.purpleBackgroundAmbient,
          t,
        )!,
      ),
      glass: AppGlassTokens(
        surfaceColor: Color.lerp(
          glass.surfaceColor,
          other.glass.surfaceColor,
          t,
        )!,
        blurSigma: _lerpDouble(glass.blurSigma, other.glass.blurSigma, t),
        strongBlurSigma: _lerpDouble(
          glass.strongBlurSigma,
          other.glass.strongBlurSigma,
          t,
        ),
      ),
      // 规格对象记录离散报告数据，不在主题过渡期间伪造插值结果。
      effects: t < 0.5 ? effects : other.effects,
    );
  }

  /// 插值数值属性。
  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Figma 内外阴影与辉光的主题访问集合。
@immutable
final class AppThemeEffects {
  /// 创建效果集合，默认绑定报告中的七项原始效果规格。
  const AppThemeEffects({
    this.purpleGlow = AppEffects.purpleGlow,
    this.subtleInnerHighlight = AppEffects.subtleInnerHighlight,
    this.softRaisedHighlight = AppEffects.softRaisedHighlight,
    this.strongInnerGlow = AppEffects.strongInnerGlow,
    this.deepPurpleGlow = AppEffects.deepPurpleGlow,
    this.magentaBottomGlow = AppEffects.magentaBottomGlow,
    this.subtleWhiteDropShadow = AppEffects.subtleWhiteDropShadow,
  });

  /// Purple Glow 内阴影规格。
  final AppEffectSpec purpleGlow;

  /// Subtle Inner Highlight 内阴影规格。
  final AppEffectSpec subtleInnerHighlight;

  /// Soft Raised Highlight 内阴影规格。
  final AppEffectSpec softRaisedHighlight;

  /// Strong Inner Glow 内阴影规格。
  final AppEffectSpec strongInnerGlow;

  /// Deep Purple Glow 内阴影规格。
  final AppEffectSpec deepPurpleGlow;

  /// Magenta Bottom Glow 内阴影规格。
  final AppEffectSpec magentaBottomGlow;

  /// Subtle White Drop Shadow 外阴影规格。
  final AppEffectSpec subtleWhiteDropShadow;
}
