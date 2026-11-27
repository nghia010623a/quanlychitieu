import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'app_back_button.dart';

/// Standard page header with optional back button, title, and trailing action.
class AppPageBar extends StatelessWidget {
  const AppPageBar({
    required this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    super.key,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (showBack) ...[
            AppBackButton(onPressed: onBack),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Decorative Keepoo page backdrop matching the soft blue tint and corner circles.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.body,
    this.bottomBar,
    super.key,
  });

  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -30,
            right: -38,
            child: IgnorePointer(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            left: -36,
            child: IgnorePointer(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: body),
                ?bottomBar,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
