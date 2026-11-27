import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page_bar.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';
import '../../domain/entities/budget.dart';
import '../widgets/budget_progress_chart.dart';

/// UI-08.6 Tiến độ chi tiêu.
class BudgetProgressPage extends StatefulWidget {
  const BudgetProgressPage({
    required this.budget,
    super.key,
  });

  final BudgetEntity budget;

  @override
  State<BudgetProgressPage> createState() => _BudgetProgressPageState();
}

class _BudgetProgressPageState extends State<BudgetProgressPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    final milestones = budget.buildMilestones();

    return AppPageScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          0,
        ),
        child: Column(
          children: [
            const AppPageBar(title: 'Tiến độ chi tiêu'),
            const SizedBox(height: AppSpacing.lg),
            AppSegmentedTabs(
              labels: const ['Tích lũy', 'Theo ngày'],
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() => _selectedTab = index),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  BudgetProgressChartCard(
                    budget: budget,
                    isDailyMode: _selectedTab == 1,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PaceInsightBanner(budget: budget),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mốc cảnh báo', style: AppTypography.section),
                        const SizedBox(height: AppSpacing.md),
                        for (var i = 0; i < milestones.length; i++) ...[
                          _MilestoneRow(milestone: milestones[i]),
                          if (i < milestones.length - 1)
                            const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaceInsightBanner extends StatelessWidget {
  const _PaceInsightBanner({required this.budget});

  final BudgetEntity budget;

  @override
  Widget build(BuildContext context) {
    final evenDailyPace = budget.limitAmount / budget.totalDays;
    final isSpendingFast = budget.dailyAverage > evenDailyPace;
    final exhaustion = budget.projectedExhaustionDate;

    final String title;
    final String description;
    final Color backgroundColor;
    final Color iconColor;
    final IconData icon;

    if (budget.spentAmount > budget.limitAmount) {
      title = 'Đã vượt hạn mức ngân sách';
      description =
          'Bạn đã chi vượt ${CurrencyFormatter.formatVnd(budget.overLimitAmount)}. Hãy cân nhắc điều chỉnh hạn mức hoặc giảm chi tiêu.';
      backgroundColor = AppColors.shoppingSurface;
      iconColor = AppColors.dangerBright;
      icon = Icons.warning_amber_rounded;
    } else if (isSpendingFast && exhaustion != null) {
      final daysEarly =
          budget.endDate.difference(exhaustion).inDays.clamp(0, budget.totalDays);
      title = 'Đang chi nhanh hơn dự kiến';
      description =
          'Với tốc độ hiện tại, ngân sách sẽ hết vào ${AppDateTime.formatShortDayMonth(exhaustion)}'
          '${daysEarly > 0 ? ', sớm hơn $daysEarly ngày' : ''}. '
          'Hãy giữ mức ${CurrencyFormatter.formatVnd(budget.dailySuggested)}/ngày.';
      backgroundColor = AppColors.travelSurface;
      iconColor = AppColors.warningText;
      icon = Icons.warning_amber_rounded;
    } else {
      title = 'Chi tiêu đang đúng kế hoạch';
      description =
          'Tốc độ hiện tại ổn định. Bạn có thể chi tối đa ${CurrencyFormatter.formatVnd(budget.dailySuggested)}/ngày trong ${budget.remainingDays} ngày tới.';
      backgroundColor = const Color(0xFFE3F4EC);
      iconColor = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadii.cardBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySemiBold,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.caption.copyWith(color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});

  final BudgetMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final isAchieved = milestone.isAchieved;
    final ringColor = switch (milestone.percent) {
      >= 100 => AppColors.dangerBright,
      >= 70 => AppColors.warning,
      _ => AppColors.success,
    };

    final statusText = isAchieved
        ? 'Đã đạt ${AppDateTime.formatShortDayMonth(milestone.achievedDate!)}'
        : milestone.projectedDate != null
            ? 'Dự kiến ${AppDateTime.formatShortDayMonth(milestone.projectedDate!)}'
            : 'Chưa đạt';

    return Row(
      children: [
        if (isAchieved)
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.white,
            ),
          )
        else
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 2),
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            '${milestone.percent}% · ${CurrencyFormatter.formatVnd(milestone.targetAmount)}',
            style: AppTypography.bodySemiBold,
          ),
        ),
        Text(
          statusText,
          style: AppTypography.caption.copyWith(
            color: isAchieved ? AppColors.success : AppColors.slate,
            fontWeight: isAchieved ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
