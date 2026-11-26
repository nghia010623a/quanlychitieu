import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.navy,
        surface: AppColors.white,
        onSurface: AppColors.navy,
        error: AppColors.danger,
        onError: AppColors.white,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineMedium: AppTypography.display,
        headlineSmall: AppTypography.titleLarge,
        titleLarge: AppTypography.title,
        titleMedium: AppTypography.section,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        labelLarge: AppTypography.button,
      ),
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
