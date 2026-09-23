// 应用文字系统：标准 TextTheme 与额外语义变体共享字号、字重和行高常量。
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 语义化字重映射，便于未来统一替换字体族或平台字重策略。
abstract final class AppFontWeights {
  /// Regular 字重。
  static const FontWeight regular = FontWeight.w400;

  /// Medium 字重。
  static const FontWeight medium = FontWeight.w500;

  /// Semibold 字重。
  static const FontWeight semibold = FontWeight.w600;

  /// Demibold 语义入口；当前平台映射为 w600。
  static const FontWeight demibold = FontWeight.w600;

  /// Heavy 字重。
  static const FontWeight heavy = FontWeight.w900;
}

/// Cyberskin 的完整 Material 文字层级和设计稿语义变体。
abstract final class AppTypography {
  /// 8px 文字规格，单位为 logical px。
  static const double size8 = 8;

  /// 10px 文字规格。
  static const double size10 = 10;

  /// 11px 文字规格。
  static const double size11 = 11;

  /// 12px 文字规格。
  static const double size12 = 12;

  /// 14px 文字规格。
  static const double size14 = 14;

  /// 16px 文字规格。
  static const double size16 = 16;

  /// 18px 文字规格。
  static const double size18 = 18;

  /// 20px 文字规格。
  static const double size20 = 20;

  /// 22px 文字规格。
  static const double size22 = 22;

  /// 26px 文字规格。
  static const double size26 = 26;

  /// 28px 文字规格。
  static const double size28 = 28;

  /// 40px 文字规格。
  static const double size40 = 40;

  /// Figma 未给出行高时使用的工程默认倍数。
  static const double defaultLineHeight = 1.2;

  /// 计时器：40px Semibold。
  static const TextStyle timer = TextStyle(
    fontSize: size40,
    fontWeight: AppFontWeights.semibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 模式标题：28px Heavy。
  static const TextStyle modeTitle = TextStyle(
    fontSize: size28,
    fontWeight: AppFontWeights.heavy,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 页面主标题：28px Demibold。
  static const TextStyle pageTitle = TextStyle(
    fontSize: size28,
    fontWeight: AppFontWeights.demibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 产品名称：26px Demibold。
  static const TextStyle productName = TextStyle(
    fontSize: size26,
    fontWeight: AppFontWeights.demibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 副标题：22px Semibold。
  static const TextStyle subtitle = TextStyle(
    fontSize: size22,
    fontWeight: AppFontWeights.semibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 主要按钮：20px Medium。
  static const TextStyle primaryButton = TextStyle(
    fontSize: size20,
    fontWeight: AppFontWeights.medium,
    height: defaultLineHeight,
    color: AppColors.textOnAccent,
  );

  /// 中标题：20px Demibold。
  static const TextStyle sectionTitle = TextStyle(
    fontSize: size20,
    fontWeight: AppFontWeights.demibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 列表标题：18px Semibold。
  static const TextStyle listTitle = TextStyle(
    fontSize: size18,
    fontWeight: AppFontWeights.semibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 确认按钮：18px Medium。
  static const TextStyle confirmButton = TextStyle(
    fontSize: size18,
    fontWeight: AppFontWeights.medium,
    height: defaultLineHeight,
    color: AppColors.textOnAccent,
  );

  /// 18px 正文。
  static const TextStyle bodyLarge = TextStyle(
    fontSize: size18,
    fontWeight: AppFontWeights.regular,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 最常用正文：16px Regular。
  static const TextStyle bodyMedium = TextStyle(
    fontSize: size16,
    fontWeight: AppFontWeights.regular,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// Stop 等强调操作：16px Heavy。
  static const TextStyle stopButton = TextStyle(
    fontSize: size16,
    fontWeight: AppFontWeights.heavy,
    height: defaultLineHeight,
    color: AppColors.textOnAccent,
  );

  /// 时间及数值：16px Demibold。
  static const TextStyle numericValue = TextStyle(
    fontSize: size16,
    fontWeight: AppFontWeights.demibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 标签：14px Medium。
  static const TextStyle tag = TextStyle(
    fontSize: size14,
    fontWeight: AppFontWeights.medium,
    height: defaultLineHeight,
    color: AppColors.textSecondary,
  );

  /// 协议与说明：14px Regular。
  static const TextStyle bodySmall = TextStyle(
    fontSize: size14,
    fontWeight: AppFontWeights.regular,
    height: defaultLineHeight,
    color: AppColors.textSecondary,
  );

  /// 小徽标：12px Regular。
  static const TextStyle badge = TextStyle(
    fontSize: size12,
    fontWeight: AppFontWeights.regular,
    height: defaultLineHeight,
    color: AppColors.textSecondary,
  );

  /// 强调徽标：12px Demibold。
  static const TextStyle badgeStrong = TextStyle(
    fontSize: size12,
    fontWeight: AppFontWeights.demibold,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 辅助说明：11px Regular。
  static const TextStyle helperText = TextStyle(
    fontSize: size11,
    fontWeight: AppFontWeights.regular,
    height: defaultLineHeight,
    color: AppColors.textMuted,
  );

  /// 微标签：10px Regular。
  static const TextStyle microLabel = TextStyle(
    fontSize: size10,
    fontWeight: AppFontWeights.regular,
    height: defaultLineHeight,
    color: AppColors.textTertiary,
  );

  /// 强调微标签：10px Heavy。
  static const TextStyle microStrong = TextStyle(
    fontSize: size10,
    fontWeight: AppFontWeights.heavy,
    height: defaultLineHeight,
    color: AppColors.textPrimary,
  );

  /// 最小操作提示：8px Medium。
  static const TextStyle minimumHint = TextStyle(
    fontSize: size8,
    fontWeight: AppFontWeights.medium,
    height: defaultLineHeight,
    color: AppColors.textMuted,
  );

  /// Material 标准语义映射到共享文字基准。
  static TextTheme get textTheme => const TextTheme(
    displayLarge: timer,
    displayMedium: subtitle,
    displaySmall: sectionTitle,
    headlineLarge: pageTitle,
    headlineMedium: productName,
    headlineSmall: subtitle,
    titleLarge: sectionTitle,
    titleMedium: listTitle,
    titleSmall: numericValue,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: primaryButton,
    labelMedium: tag,
    labelSmall: badge,
  ).apply(decoration: TextDecoration.none);
}
