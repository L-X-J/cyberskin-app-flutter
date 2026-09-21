// 应用主题入口与稳定视觉 token 的定义位置。
import 'package:flutter/material.dart';

/// 应用主题 token 及 Material 主题构建入口。
abstract final class AppTheme {
  /// 生成初始 Material 配色方案的品牌种子色。
  static const Color brandSeed = Color(0xFF0D9488);

  /// 构建当前应用壳层使用的浅色主题。
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: brandSeed);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
    );
  }
}
