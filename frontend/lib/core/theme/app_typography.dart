import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Be Vietnam Pro styles used throughout the Figma file.
abstract final class AppTypography {
  static const String _fontFamily = 'BeVietnamPro';

  static TextStyle _style({
    required double size,
    required double height,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.navy,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle get display =>
      _style(size: 28, height: 36, weight: FontWeight.w700);
  static TextStyle get titleLarge =>
      _style(size: 24, height: 36, weight: FontWeight.w600);
  static TextStyle get title =>
      _style(size: 20, height: 28, weight: FontWeight.w700);
  static TextStyle get section =>
      _style(size: 16, height: 24, weight: FontWeight.w700);
  static TextStyle get cardTitle =>
      _style(size: 15, height: 24, weight: FontWeight.w600);
  static TextStyle get body =>
      _style(size: 14, height: 21, weight: FontWeight.w400);
  static TextStyle get bodyMedium =>
      _style(size: 14, height: 21, weight: FontWeight.w500);
  static TextStyle get bodySemiBold =>
      _style(size: 14, height: 21, weight: FontWeight.w600);
  static TextStyle get button =>
      _style(size: 14, height: 21, weight: FontWeight.w700);
  static TextStyle get label =>
      _style(size: 13, height: 20, weight: FontWeight.w600);
  static TextStyle get caption => _style(
    size: 12,
    height: 20,
    color: AppColors.slate,
  );
  static TextStyle get captionSmall => _style(
    size: 11,
    height: 17,
    color: AppColors.muted,
  );
}