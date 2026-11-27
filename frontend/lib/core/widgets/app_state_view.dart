import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Standard Loading, Empty, and Error state view.
class AppStateView extends StatelessWidget {
  const AppStateView.loading({
    this.title = 'Đang tải dữ liệu...',
    super.key,
  })  : _mode = _StateMode.loading,
        subtitle = null,
        icon = null,
        footer = null,
        actionLabel = null,
        onAction = null;

  const AppStateView.empty({
    required this.title,
    this.subtitle,
    this.icon = Icons.account_balance_wallet_outlined,
    this.footer,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : _mode = _StateMode.empty;

  const AppStateView.error({
    required this.title,
    this.subtitle,
    this.icon = Icons.error_outline_rounded,
    this.actionLabel = 'Thử lại',
    this.onAction,
    super.key,
  })  : _mode = _StateMode.error,
        footer = null;

  final _StateMode _mode;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? footer;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (_mode == _StateMode.loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.caption),
          ],
        ),
      );
    }

    final isError = _mode == _StateMode.error;
    final outerColor =
        isError ? AppColors.dangerSurface : AppColors.primarySurface;
    final iconColor = isError ? AppColors.danger : const Color(0xFF3699ED);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: outerColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.control,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 36, color: iconColor),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(fontSize: 18),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(fontSize: 13),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.lg),
              footer!,
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _StateMode { loading, empty, error }
