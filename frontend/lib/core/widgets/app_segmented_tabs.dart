import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  }) : assert(labels.length > 1);

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadii.pillBorder,
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              child: Material(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: AppRadii.pillBorder,
                child: InkWell(
                  onTap: () => onChanged(index),
                  borderRadius: AppRadii.pillBorder,
                  child: Center(
                    child: Text(
                      labels[index],
                      style: AppTypography.label.copyWith(
                        color: selected ? AppColors.navy : AppColors.slate,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
