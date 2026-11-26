import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum AppCategoryTone { food, travel, shopping, neutral }

class AppCategoryIcon extends StatelessWidget {
  const AppCategoryIcon({
    required this.icon,
    this.tone = AppCategoryTone.neutral,
    this.size = 40,
    super.key,
  });

  final IconData icon;
  final AppCategoryTone tone;
  final double size;

  Color get _background => switch (tone) {
        AppCategoryTone.food => AppColors.foodSurface,
        AppCategoryTone.travel => AppColors.travelSurface,
        AppCategoryTone.shopping => AppColors.shoppingSurface,
        AppCategoryTone.neutral => AppColors.primarySurface,
      };

  Color get _foreground => switch (tone) {
        AppCategoryTone.travel => AppColors.warningText,
        AppCategoryTone.shopping => AppColors.dangerBright,
        _ => const Color(0xFF3699ED),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: AppRadii.iconBorder,
      ),
      child: Icon(icon, size: size / 2, color: _foreground),
    );
  }
}
