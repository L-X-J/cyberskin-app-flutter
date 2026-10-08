// 应用阴影与辉光规格：区分内阴影/外阴影并保留 Figma 报告给出的范围。
import 'package:flutter/material.dart';

/// 阴影类别，避免把内阴影误当成 Flutter 外投影。
enum AppEffectKind {
  /// 需要裁切绘制在形状内部的阴影。
  innerShadow,

  /// 绘制在形状外部的阴影。
  dropShadow,
}

/// 一个效果的设计参数；未提供的参数保持 null，不推断为设计事实。
@immutable
final class AppEffectSpec {
  /// 创建具名视觉效果规格。
  const AppEffectSpec({
    required this.kind,
    required this.color,
    this.opacityMin,
    this.opacityMax,
    this.blurMin,
    this.blurMax,
    this.spreadMin,
    this.spreadMax,
    this.offsetX,
    this.offsetY,
  });

  /// 效果类别。
  final AppEffectKind kind;

  /// Figma 报告中的颜色基色。
  final Color color;

  /// 已知不透明度范围下限。
  final double? opacityMin;

  /// 已知不透明度范围上限。
  final double? opacityMax;

  /// 已知 blur 范围下限。
  final double? blurMin;

  /// 已知 blur 范围上限。
  final double? blurMax;

  /// 已知 spread 范围下限。
  final double? spreadMin;

  /// 已知 spread 范围上限。
  final double? spreadMax;

  /// 报告明确提供时的水平偏移。
  final double? offsetX;

  /// 报告明确提供时的垂直偏移。
  final double? offsetY;
}

/// Figma 报告中的阴影与辉光效果参数集合。
abstract final class AppEffects {
  /// Purple Glow 内阴影。
  static const AppEffectSpec purpleGlow = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFF8230FD),
    opacityMin: 0.41,
    opacityMax: 0.41,
    blurMin: 20,
    blurMax: 20,
    spreadMin: 10,
    spreadMax: 10,
  );

  /// Subtle Inner Highlight 内阴影。
  static const AppEffectSpec subtleInnerHighlight = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFFFFFFFF),
    opacityMin: 0.25,
    opacityMax: 0.25,
    blurMin: 4,
    blurMax: 4,
    offsetY: 4,
  );

  /// 公共液态玻璃按钮第二层内阴影；未注明偏移按 (0, 0) 绘制。
  static const AppEffectSpec liquidGlassButtonInnerGlow = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFFC59EFF),
    opacityMin: 0.40,
    opacityMax: 0.40,
    blurMin: 20,
    blurMax: 20,
    spreadMin: 10,
    spreadMax: 10,
    offsetX: 0,
    offsetY: 0,
  );

  /// 公共液态玻璃按钮深色款的单层紫色内阴影。
  static const AppEffectSpec liquidGlassButtonSubtleInnerGlow = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFF8230FD),
    opacityMin: 0.40,
    opacityMax: 0.40,
    blurMin: 20,
    blurMax: 20,
    spreadMin: 10,
    spreadMax: 10,
    offsetX: 0,
    offsetY: 0,
  );

  /// Soft Raised Highlight 内阴影。
  static const AppEffectSpec softRaisedHighlight = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFFFFFFFF),
    opacityMin: 0.33,
    opacityMax: 0.33,
    blurMin: 20,
    blurMax: 20,
    spreadMin: 6,
    spreadMax: 6,
    offsetY: 4,
  );

  /// Strong Inner Glow 内阴影。
  static const AppEffectSpec strongInnerGlow = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFFFFFFFF),
    opacityMin: 0.50,
    opacityMax: 0.60,
    blurMin: 23,
    blurMax: 26,
    spreadMin: 11,
    spreadMax: 13,
  );

  /// Deep Purple Glow 内阴影。
  static const AppEffectSpec deepPurpleGlow = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFF7E6EED),
    blurMin: 48,
    blurMax: 48,
  );

  /// Magenta Bottom Glow 内阴影。
  static const AppEffectSpec magentaBottomGlow = AppEffectSpec(
    kind: AppEffectKind.innerShadow,
    color: Color(0xFFC741AB),
    blurMin: 25,
    blurMax: 25,
    offsetY: -3,
  );

  /// Subtle White Drop Shadow 外阴影。
  static const AppEffectSpec subtleWhiteDropShadow = AppEffectSpec(
    kind: AppEffectKind.dropShadow,
    color: Color(0xFFFFFFFF),
    opacityMin: 0.25,
    opacityMax: 0.25,
    blurMin: 4,
    blurMax: 4,
  );
}
