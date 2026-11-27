import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/budget.dart';

/// Shows UI-08.8 confirmation dialog before deleting a budget.
Future<bool> showDeleteBudgetDialog(
  BuildContext context, {
  required String categoryName,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.navy.withValues(alpha: 0.4),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.profile),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.shoppingSurface,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 28,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Xóa ngân sách $categoryName?',
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Các giao dịch đã ghi nhận vẫn được giữ nguyên. Chỉ hạn mức và lịch sử tiến độ của ngân sách này bị xóa.',
                style: AppTypography.body.copyWith(color: AppColors.slate),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Xóa ngân sách',
                    style: AppTypography.button.copyWith(color: AppColors.white),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Giữ lại',
                    style: AppTypography.button.copyWith(color: AppColors.navy),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Shows UI-08.9 confirmation dialog after creating a budget.
Future<void> showBudgetCreatedDialog(
  BuildContext context, {
  required BudgetEntity budget,
}) async {
  final periodText = switch (budget.periodType) {
    BudgetPeriodType.month =>
      'tháng ${budget.startDate.month}/${budget.startDate.year}',
    BudgetPeriodType.week =>
      'tuần ${AppDateTime.formatCompactRange(budget.startDate, budget.endDate)}',
    BudgetPeriodType.quarter =>
      'quý ${((budget.startDate.month - 1) ~/ 3) + 1}/${budget.startDate.year}',
    BudgetPeriodType.custom =>
      'từ ${AppDateTime.formatCompactRange(budget.startDate, budget.endDate)}',
  };

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.navy.withValues(alpha: 0.4),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.profile),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  size: 28,
                  color: Color(0xFF3699ED),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Đã tạo ngân sách',
                style: AppTypography.title,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ngân sách ${budget.category.name} $periodText (${CurrencyFormatter.formatVnd(budget.limitAmount)}) đã được tạo. Keepoo sẽ nhắc bạn khi chi đạt ${budget.alertPercent}% hạn mức.',
                style: AppTypography.body.copyWith(color: AppColors.slate),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.navy,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Xem ngân sách',
                    style: AppTypography.button.copyWith(color: AppColors.navy),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
