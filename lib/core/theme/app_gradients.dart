// 应用渐变 token：保留每类渐变语义，临时几何参数不冒充 Figma 标注。
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 设计系统渐变集合，可直接传入 BoxDecoration.gradient。
final class AppGradients {
  /// 创建完整渐变集合；方向、中心和半径是可替换的工程默认参数。
  const AppGradients({
    this.purplePinkEmphasis = const LinearGradient(
      colors: [Color(0xFFC477FF), Color(0xFFF025FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.brandPinkPurple = const LinearGradient(
      colors: [Color(0xFF9B29B4), Color(0xFFEB72FB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.grayPurpleTransition = const LinearGradient(
      colors: [Color(0xFFC0C0C0), Color(0xFFD23CD9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.blueSupport = const LinearGradient(
      colors: [Color(0xFF1A37A1), Color(0xFF1590DC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.darkPurpleAmbient = const RadialGradient(
      colors: [Color(0xFF150616), Color(0xFF733691)],
      center: Alignment.center,
      radius: 0.75,
    ),
    this.redWarningAmbient = const RadialGradient(
      colors: [Color(0xFF000000), AppColors.error],
      center: Alignment.center,
      radius: 0.75,
    ),
    this.purpleBackgroundAmbient = const RadialGradient(
      colors: [Color(0xFF141414), Color(0xB38E41B3)],
      center: Alignment.center,
      radius: 0.75,
    ),
  });

  /// 应用级标准渐变集合。
  static const AppGradients standard = AppGradients();

  /// 紫粉强调渐变。
  final LinearGradient purplePinkEmphasis;

  /// 品牌粉紫渐变。
  final LinearGradient brandPinkPurple;

  /// 灰紫过渡渐变。
  final LinearGradient grayPurpleTransition;

  /// 蓝色辅助渐变。
  final LinearGradient blueSupport;

  /// 暗紫氛围光。
  final RadialGradient darkPurpleAmbient;

  /// 红色警告氛围光。
  final RadialGradient redWarningAmbient;

  /// 紫色背景氛围。
  final RadialGradient purpleBackgroundAmbient;
}
