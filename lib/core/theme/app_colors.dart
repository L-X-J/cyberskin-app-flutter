// 应用设计系统颜色 token：集中保留品牌、文字、背景和描边的原始语义。
import 'package:flutter/material.dart';

/// 应用设计系统使用的稳定颜色与透明色值。
abstract final class AppColors {
  /// App 页面统一背景底色。
  static const Color scaffold = Color(0xFF09090A);

  /// 默认深色表面。
  static const Color surface = Color(0xFF09090A);

  /// 黑色遮罩层，透明度为 40%。
  static const Color overlay = Color.fromRGBO(13, 13, 13, 0.40);

  /// 更深层的纯黑表面。
  static const Color surfaceDark = Color(0xFF020202);

  /// 品牌主紫色。
  static const Color primary = Color(0xFF7244E0);

  /// 品牌深紫变体。
  static const Color primaryVariant = Color(0xFF3F3ECA);

  /// 柔和紫色。
  static const Color primarySoft = Color(0xFF9F88BD);

  /// 浅紫色。
  static const Color primaryLight = Color(0xFFCAAEE1);

  /// 紫色辉光。
  static const Color primaryGlow = Color(0xFF8230FD);

  /// 粉紫色。
  static const Color secondary = Color(0xFFCD68BD);

  /// 深粉紫色。
  static const Color secondaryDark = Color(0xFF721177);

  /// 粉紫表面，透明度为 20%。
  static const Color secondarySurface = Color.fromRGBO(72, 29, 91, 0.20);

  /// 公共液态玻璃按钮填充：设计师确认的 #D173AB，20% 不透明度。
  static const Color liquidGlassButtonFill = Color.fromRGBO(
    209,
    115,
    171,
    0.20,
  );

  /// 公共液态玻璃按钮深色款填充：#7A576C，20% 不透明度。
  static const Color liquidGlassButtonSubtleFill = Color.fromRGBO(
    122,
    87,
    108,
    0.20,
  );

  /// 紧凑液态玻璃按钮填充：设计师确认的 #1FFFFFFF。
  static const Color liquidGlassButtonTranslucentFill = Color(0x1FFFFFFF);

  /// 辅助蓝紫色。
  static const Color accentBlue = Color(0xFF5358AD);

  /// 蓝紫表面。
  static const Color surfaceBluePurple = Color(0xFF262542);

  /// 错误色。
  static const Color error = Color(0xFFD94126);

  /// 浅错误色。
  static const Color errorLight = Color(0xFFF9765F);

  /// 主要文字颜色。
  static const Color textPrimary = Color(0xFFF8F8F8);

  /// 次要文字颜色。
  static const Color textSecondary = Color(0xFFDADADA);

  /// 第三级文字颜色。
  static const Color textTertiary = Color(0xFFCECECE);

  /// 辅助文字颜色。
  static const Color textAuxiliary = Color(0xFFD0D0D0);

  /// 弱化文字颜色。
  static const Color textMuted = Color(0xFFA5A5A5);

  /// 提示文字颜色。
  static const Color textHint = Color(0xFF8F8F8F);

  /// 注释文字颜色。
  static const Color textCaption = Color(0xFF828282);

  /// 禁用文字颜色。
  static const Color textDisabled = Color(0xFF5D5D5D);

  /// 强调表面上的文字颜色。
  static const Color textOnAccent = Color(0xFFFFFFFF);

  /// 白色 90% 不透明度。
  static const Color white90 = Color.fromRGBO(255, 255, 255, 0.90);

  /// 白色 80% 不透明度。
  static const Color white80 = Color.fromRGBO(255, 255, 255, 0.80);

  /// 白色 20% 不透明度。
  static const Color white20 = Color.fromRGBO(255, 255, 255, 0.20);

  /// 白色 12% 不透明度。
  static const Color white12 = Color.fromRGBO(255, 255, 255, 0.12);

  /// 白色 10% 不透明度。
  static const Color white10 = Color.fromRGBO(255, 255, 255, 0.10);

  /// 白色描边基色。
  static const Color borderWhite = Color(0xFFFFFFFF);

  /// 白色 10% 描边。
  static const Color borderWhite10 = Color.fromRGBO(255, 255, 255, 0.10);

  /// 灰色描边。
  static const Color borderGray = Color(0xFFCECECE);

  /// 灰色 40% 描边。
  static const Color borderGray40 = Color.fromRGBO(206, 206, 206, 0.40);

  /// 蓝色描边。
  static const Color borderBlue = Color(0xFFA8AEFF);

  /// 紫色描边。
  static const Color borderPurple = Color(0xFFDBA8FF);

  /// 按统一 alpha 参数派生颜色，避免页面自行拼接 ARGB 数值。
  static Color withAlpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
