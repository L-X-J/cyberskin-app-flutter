// 公共双层渐变卡片的设计参数；业务颜色由调用方覆盖。
import 'package:flutter/material.dart';

/// 双层卡片表面的设计规格与工程径向范围。
abstract final class AppLayeredGradientStyle {
  /// 底层纯色与上层渐变终点的默认颜色。
  static const baseColor = Color(0xFFD94126);

  /// 上层从顶部黑色中心向外过渡到底色。
  static const gradientStart = Colors.black;

  /// 顶部中央为径向渐变起点。
  static const gradientCenter = Alignment.topCenter;

  /// 以短边为径向范围，方形型号卡底部到达渐变终点。
  ///
  /// 根据 build/ui/img.png 的明暗分布调整；设计未标注椭圆尺寸，
  /// 非方形卡片可由调用方覆盖，不将该值视为设计工具的原始几何参数。
  static const gradientRadius = 1.0;

  /// 上层图层模糊，使用 AppBlur 的统一工程映射。
  static const layerBlur = 14.0;

  /// 底层内阴影的颜色、模糊及偏移。
  static const innerShadowColor = Color(0xFFF9765F);

  /// 底层内阴影的设计模糊半径。
  static const innerShadowBlur = 20.0;

  /// 底层内阴影向下偏移一个逻辑像素。
  static const innerShadowOffset = Offset(0, 1);
}
