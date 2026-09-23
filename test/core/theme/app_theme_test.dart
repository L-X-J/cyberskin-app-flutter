import 'package:cyberskin_app/core/theme/app_blur.dart';
import 'package:cyberskin_app/core/theme/app_colors.dart';
import 'package:cyberskin_app/core/theme/app_effects.dart';
import 'package:cyberskin_app/core/theme/app_gradients.dart';
import 'package:cyberskin_app/core/theme/app_radius.dart';
import 'package:cyberskin_app/core/theme/app_theme.dart';
import 'package:cyberskin_app/core/theme/app_theme_extensions.dart';
import 'package:cyberskin_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cyberskin theme tokens', () {
    test('uses an explicit Material 3 dark color scheme', () {
      final theme = AppTheme.dark();

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(AppColors.scaffold, const Color(0xFF09090A));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF09090A));
      expect(theme.textTheme.bodyMedium?.fontSize, AppTypography.size16);
      expect(theme.textTheme.bodyMedium?.decoration, TextDecoration.none);
    });

    test('covers standard and custom typography roles', () {
      final textTheme = AppTypography.textTheme;

      expect(textTheme.displayLarge?.fontSize, 40);
      expect(textTheme.headlineLarge?.fontWeight, FontWeight.w600);
      expect(textTheme.headlineMedium?.fontSize, 26);
      expect(textTheme.bodyLarge?.fontSize, 18);
      expect(textTheme.bodySmall?.fontSize, 14);
      expect(textTheme.labelLarge?.fontSize, 20);
      expect(AppTypography.modeTitle.fontWeight, FontWeight.w900);
      expect(AppTypography.minimumHint.fontSize, 8);
    });

    test('keeps gradient colors and report blur values', () {
      expect(AppGradients.standard.purplePinkEmphasis.colors, const [
        Color(0xFFC477FF),
        Color(0xFFF025FA),
      ]);
      expect(
        AppGradients.standard.purpleBackgroundAmbient.colors.last,
        const Color(0xB38E41B3),
      );
      expect(AppBlur.glass, 10);
      expect(AppBlur.glassStrong, 20);
      expect(AppBlur.ambientThree, 160);
    });

    test('exposes rounded geometry and full theme extension', () {
      final theme = AppTheme.dark();
      final extension = theme.extension<AppThemeExtension>();

      expect(AppRadius.radiusCard, 32);
      expect(AppRadius.radiusPill, 100);
      expect(extension, isNotNull);
      expect(
        extension!.gradients.blueSupport,
        AppGradients.standard.blueSupport,
      );
      expect(extension.glass.surfaceColor, AppColors.secondarySurface);
      expect(extension.glass.blurSigma, 10);
      expect(extension.effects.purpleGlow.kind, AppEffectKind.innerShadow);
      expect(extension.effects.purpleGlow.opacityMin, 0.41);
      expect(
        extension.effects.subtleWhiteDropShadow.kind,
        AppEffectKind.dropShadow,
      );
      expect(extension.effects.deepPurpleGlow.opacityMin, isNull);
    });
  });
}
