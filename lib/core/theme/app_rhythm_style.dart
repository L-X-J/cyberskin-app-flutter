// Ardot 自定义节奏六态的视觉参数；画板基准 402×874。
import 'package:flutter/material.dart';

/// 六张节奏设计稿共享的颜色和几何参数。
abstract final class AppRhythmStyle {
  /// 页面基底色。
  static const background = Color(0xFF09090A);

  /// 背景主蓝色光晕。
  static const blue = Color(0xFF3F3ECA);

  /// 背景右下紫色光晕。
  static const purple = Color(0xFF7244E0);

  /// 背景右上浅色光晕。
  static const haze = Color(0xFF9F88BD);

  /// 片段与弹层的深色表面。
  static const panel = Color(0xFF080A3D);

  /// 面板内发光颜色。
  static const panelGlow = Color(0xFF7E6EED);

  /// 选中态与日期徽标强调色。
  static const pink = Color(0xFFD173AB);

  /// 计时圆盘中心强调色。
  static const pinkBright = Color(0xFFFF30A4);

  /// 次级说明文字颜色。
  static const secondary = Color(0xFFA9A4C3);

  /// 透明玻璃表面的浅色填充。
  static const glass = Color(0x26FFFFFF);

  /// 通道参数标签底色。
  static const chip = Color(0xFF5050A3);

  /// 节奏面板统一圆角。
  static const radius = BorderRadius.all(Radius.circular(32));

  /// 设计画板两侧内容留白。
  static const pagePadding = 22.0;

  /// 宽屏操作列宽度上限，不对整页缩放。
  static const maxWidth = 600.0;
}
