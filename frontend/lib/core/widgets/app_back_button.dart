import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Standard 40x40 rounded back button used in Keepoo page bars.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    this.onPressed,
    this.icon = Icons.arrow_back_rounded,
    super.key,
  });

  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Quay lại',
      child: Material(
        color: AppColors.backgroundAccent,
        borderRadius: AppRadii.iconBorder,
        child: InkWell(
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          borderRadius: AppRadii.iconBorder,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              icon,
              size: 20,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}
