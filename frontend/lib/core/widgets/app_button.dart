import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, disabled, danger }

enum AppSmallButtonVariant { primary, secondary, sent, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.height = 56,
    this.expand = true,
    this.leading,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final double height;
  final bool expand;
  final Widget? leading;

  bool get _isDisabled =>
      variant == AppButtonVariant.disabled || onPressed == null;

  Color get _background {
    return switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => AppColors.white,
      AppButtonVariant.disabled => AppColors.disabledSurface,
      AppButtonVariant.danger => AppColors.danger,
    };
  }

  Color get _foreground {
    return switch (variant) {
      AppButtonVariant.disabled => AppColors.disabledText,
      AppButtonVariant.danger => AppColors.white,
      _ => AppColors.navy,
    };
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: AppDurations.quick,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: AppRadii.pillBorder,
        boxShadow: switch (variant) {
          AppButtonVariant.primary ||
          AppButtonVariant.secondary =>
            AppShadows.control,
          _ => null,
        },
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: AppTypography.button.copyWith(color: _foreground)),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: !_isDisabled,
      child: Opacity(
        opacity: _isDisabled && variant != AppButtonVariant.disabled ? 0.6 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDisabled ? null : onPressed,
            borderRadius: AppRadii.pillBorder,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppSmallButton extends StatelessWidget {
  const AppSmallButton({
    required this.label,
    this.onPressed,
    this.variant = AppSmallButtonVariant.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppSmallButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final background = switch (variant) {
      AppSmallButtonVariant.primary => AppColors.primary,
      _ => AppColors.progressTrack,
    };
    final foreground = switch (variant) {
      AppSmallButtonVariant.primary => AppColors.navy,
      AppSmallButtonVariant.secondary => AppColors.slate,
      AppSmallButtonVariant.sent => AppColors.disabledText,
      AppSmallButtonVariant.danger => AppColors.danger,
    };

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: background,
        borderRadius: AppRadii.pillBorder,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadii.pillBorder,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: foreground,
                height: 18 / 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
