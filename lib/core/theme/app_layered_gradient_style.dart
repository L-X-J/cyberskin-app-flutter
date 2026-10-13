// 公共双层渐变卡片的设计参数；业务颜色由调用方覆盖。
import 'package:flutter/material.dart';

/// 双层卡片表面的设计规格与工程径向范围。
abstract final class AppLayeredGradientStyle {
  /// 底层纯色与上层渐变终点的默认颜色。
  static const baseColor = Color(0xFFD94126);

  /// 上层从顶部纯黑色向外过渡到底色（依据 Figma aaa.svg）。
  static const gradientStart = Colors.black;

  /// 顶部中央为径向渐变起点（依据 Figma aaa.svg: cx=73, cy=0）。
  static const gradientCenter = Alignment(0, -1.2);

  /// 渐变层垂直偏移逻辑像素。
  static const gradientOffsetY = 1.0;

  /// 上层图层模糊，依据 Figma aaa.svg 的 feGaussianBlur stdDeviation="7.05"。
  static const layerBlur = 7.05;

  /// 底层内阴影的颜色、模糊及偏移。
  static const innerShadowColor = Color(0xFFF9765F);

  /// 底层内阴影的设计模糊半径。
  static const innerShadowBlur = 20.0;

  /// 底层内阴影向下偏移一个逻辑像素。
  static const innerShadowOffset = Offset(0, 10);
}

/// 首页扫描卡的独立双层表面规格，不影响型号卡默认样式。
abstract final class AppScanCardStyle {
  /// 底层纯色。
  static const baseColor = Color(0xFFCD68BD);

  /// 上层径向渐变；首个色标前保持中心色。
  static const gradientColors = [Color(0xFF150616), Color(0xFF733691)];

  /// 径向色标位置，28% 表示色标而非中心坐标。
  static const gradientStops = [0.28, 1.0];

  /// 暗区中心位于卡片宽度中点、约 58% 高度。
  ///
  /// 该位置按 `img_group_58@3x.png` 校准，不能复用型号卡的顶部中心。
  static const gradientCenter = Alignment(0, 0.16);

  /// 以短边为尺度，保留约 17% 短边的暗核及其向外的模糊过渡。
  ///
  /// 参考图的黑色边缘在卡片中部收紧；`1.0` 会使暗核过宽。
  static const gradientRadius = 0.55;

  /// 椭圆暗区的横纵比；参考图横向扩散明显大于纵向。
  static const gradientAspectRatio = 2.1;

  /// 首页扫描卡的渐变垂直偏移逻辑像素。
  static const gradientOffsetY = 20.0;

  /// 仅应用于上层渐变的模糊。
  static const layerBlur = 30.0;

  /// 底层白色内阴影。
  static const innerShadowColor = Colors.white;

  /// 内阴影的模糊半径。
  static const innerShadowBlur = 20.0;

  /// 正扩散将阴影向卡片内部扩展。
  static const innerShadowSpread = 6.0;

  /// 内阴影垂直偏移。
  static const innerShadowOffset = Offset(0, 4);

  /// 白色阴影不透明度。
  static const innerShadowOpacity = 0.3;
}
