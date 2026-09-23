// 应用全局深色 Material 主题的组装入口。
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_theme_extensions.dart';
import 'app_typography.dart';

/// 构建项目唯一的 Material 3 深色主题。
abstract final class AppTheme {
  /// 构建应用根组件使用的暗色主题。
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnAccent,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnAccent,
      tertiary: AppColors.accentBlue,
      onTertiary: AppColors.textOnAccent,
      error: AppColors.error,
      onError: AppColors.textOnAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceTint: AppColors.primary,
      outline: AppColors.borderGray40,
    );
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.radiusMd)),
      borderSide: BorderSide(color: AppColors.borderWhite10),
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffold,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      textTheme: AppTypography.textTheme,
      primaryTextTheme: AppTypography.textTheme,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      disabledColor: AppColors.textDisabled,
      extensions: const <ThemeExtension<dynamic>>[AppThemeExtension()],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitle,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: TextStyle(color: AppColors.textHint),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        enabledBorder: inputBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.radiusMd)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.radiusMd)),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.radiusMd)),
          borderSide: BorderSide(color: AppColors.errorLight, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnAccent,
          disabledBackgroundColor: AppColors.surfaceBluePurple,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTypography.primaryButton,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          minimumSize: const Size(64, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textDisabled,
          side: const BorderSide(color: AppColors.borderWhite10),
          textStyle: AppTypography.primaryButton,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          disabledForegroundColor: AppColors.textDisabled,
          textStyle: AppTypography.confirmButton,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
