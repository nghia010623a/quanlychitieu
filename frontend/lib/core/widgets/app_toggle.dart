import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class AppToggle extends StatelessWidget {
  const AppToggle({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: SizedBox(
          width: 46,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: AppDurations.quick,
              curve: const Cubic(0, 0, 0.58, 1),
              width: 46,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? AppColors.primary : AppColors.disabledSurface,
                borderRadius: AppRadii.pillBorder,
              ),
              child: AnimatedAlign(
                duration: AppDurations.quick,
                curve: const Cubic(0, 0, 0.58, 1),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(dimension: 22),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
