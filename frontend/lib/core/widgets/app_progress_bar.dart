import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum AppProgressTone { primary, warning, danger, success }

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.tone = AppProgressTone.primary,
    super.key,
  });

  final double value;
  final AppProgressTone tone;

  Color get _color => switch (tone) {
        AppProgressTone.primary => AppColors.primary,
        AppProgressTone.warning => AppColors.warning,
        AppProgressTone.danger => AppColors.dangerBright,
        AppProgressTone.success => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.clamp(0.0, 1.0).toDouble();

    return Semantics(
      value: '${(normalizedValue * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppRadii.pillBorder,
        child: SizedBox(
          height: 8,
          child: LinearProgressIndicator(
            value: normalizedValue,
            backgroundColor: AppColors.progressTrack,
            valueColor: AlwaysStoppedAnimation(_color),
          ),
        ),
      ),
    );
  }
}
