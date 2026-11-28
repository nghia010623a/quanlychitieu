import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_category_icon.dart';
import '../../../../core/widgets/app_page_bar.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../widgets/budget_pickers.dart';
import 'budget_form_page.dart';
import 'budget_progress_page.dart';

/// UI-08.5 Chi tiết ngân sách.
class BudgetDetailPage extends StatefulWidget {
  const BudgetDetailPage({
    required this.repository,
    required this.budgetId,
    super.key,
  });

  final BudgetRepository repository;
  final String budgetId;

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  bool _isLoading = true;
  String? _errorMessage;
  BudgetEntity? _budget;
  List<BudgetWalletOption> _wallets = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.getBudgetById(widget.budgetId),
        widget.repository.getWallets(),
      ]);

      if (!mounted) return;
      setState(() {
        _budget = results[0] as BudgetEntity?;
        _wallets = results[1] as List<BudgetWalletOption>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String _walletNamesLabel(BudgetEntity budget) {
    if (_wallets.isNotEmpty && budget.walletIds.length >= _wallets.length) {
      return 'Tất cả ví';
    }
    final names = _wallets
        .where((w) => budget.walletIds.contains(w.id))
        .map((w) => w.name)
        .toList();
    if (names.isEmpty) return 'Chưa chọn ví';
    return names.join(', ');
  }

  Future<void> _openEdit() async {
    final budget = _budget;
    if (budget == null) return;

    final result = await Navigator.of(context).push<BudgetFormResult>(
      MaterialPageRoute(
        builder: (_) => BudgetFormPage(
          repository: widget.repository,
          existingBudget: budget,
        ),
      ),
    );

    if (!mounted) return;
    if (result?.deleted == true) {
      Navigator.of(context).pop();
      return;
    }
    await _loadData();
  }

  Future<void> _openQuickWalletPicker() async {
    final budget = _budget;
    if (budget == null || _wallets.isEmpty) return;

    final picked = await showWalletPickerSheet(
      context,
      wallets: _wallets,
      initialSelectedIds: budget.walletIds,
    );
    if (picked == null || !mounted) return;

    try {
      final updated = await widget.repository.updateBudget(
        budget.copyWith(walletIds: picked),
      );
      if (!mounted) return;
      setState(() => _budget = updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _openProgress() {
    final budget = _budget;
    if (budget == null) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BudgetProgressPage(budget: budget),
      ),
    );
  }

  void _showAllTransactions(BudgetEntity budget) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giao dịch · ${budget.category.name}',
                  style: AppTypography.title,
                ),
                const SizedBox(height: AppSpacing.md),
                if (budget.transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Chưa có giao dịch nào trong kỳ này.',
                      style: AppTypography.caption,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: budget.transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        return _TransactionRow(
                          item: budget.transactions[index],
                          referenceDate: budget.referenceDate,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budget = _budget;

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
            AppPageBar(
              title: 'Chi tiết ngân sách',
              trailing: budget == null
                  ? null
                  : Material(
                      color: AppColors.backgroundAccent,
                      borderRadius: AppRadii.iconBorder,
                      child: InkWell(
                        onTap: _openEdit,
                        borderRadius: AppRadii.iconBorder,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _isLoading
                  ? const AppStateView.loading()
                  : _errorMessage != null
                      ? AppStateView.error(
                          title: 'Không tải được chi tiết ngân sách',
                          subtitle: _errorMessage,
                          onAction: _loadData,
                        )
                      : budget == null
                          ? AppStateView.error(
                              title: 'Không tìm thấy ngân sách',
                              actionLabel: 'Quay lại',
                              onAction: () => Navigator.of(context).pop(),
                            )
                          : _buildContent(budget),
            ),
          ],
        ),
      ),
      bottomBar: _isLoading || budget == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Tiến độ chi tiêu',
                      variant: AppButtonVariant.secondary,
                      onPressed: _openProgress,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppButton(
                      label: 'Sửa ngân sách',
                      variant: AppButtonVariant.primary,
                      onPressed: _openEdit,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildContent(BudgetEntity budget) {
    final status = budget.healthStatus;
    final progressTone = switch (status) {
      BudgetHealthStatus.overLimit => AppProgressTone.danger,
      BudgetHealthStatus.nearLimit => AppProgressTone.warning,
      BudgetHealthStatus.onTrack => AppProgressTone.primary,
    };

    final badgeBg = switch (status) {
      BudgetHealthStatus.onTrack => const Color(0xFFE3F4EC),
      BudgetHealthStatus.nearLimit => AppColors.travelSurface,
      BudgetHealthStatus.overLimit => AppColors.shoppingSurface,
    };
    final badgeTextColor = switch (status) {
      BudgetHealthStatus.onTrack => const Color(0xFF2F8F6B),
      BudgetHealthStatus.nearLimit => AppColors.warningText,
      BudgetHealthStatus.overLimit => AppColors.dangerBright,
    };

    final remaining = budget.remainingAmount;
    final recent = budget.transactions.take(3).toList();
    final alertSubtitle =
        'Khi chi đạt ${budget.alertPercent}% · ${budget.repeatMonthly ? 'Lặp lại hằng kỳ' : 'Không lặp lại'}';

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppCategoryIcon(
                    icon: budget.category.icon,
                    tone: budget.category.tone,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category.name,
                          style: AppTypography.section,
                        ),
                        Text(
                          '${budget.periodSummaryLabel} · ${AppDateTime.formatCompactRange(budget.startDate, budget.endDate)}',
                          style: AppTypography.captionSmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: AppRadii.pillBorder,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status.label,
                      style: AppTypography.captionSmall.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: AppSpacing.xs,
                children: [
                  Text(
                    CurrencyFormatter.formatVnd(remaining.abs()),
                    style: AppTypography.display.copyWith(
                      color: remaining < 0
                          ? AppColors.dangerBright
                          : AppColors.navy,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      remaining >= 0 ? 'còn lại' : 'vượt hạn mức',
                      style: AppTypography.caption.copyWith(
                        fontSize: 13,
                        color: remaining < 0
                            ? AppColors.dangerBright
                            : AppColors.slate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppProgressBar(
                value: budget.progressRatio,
                tone: progressTone,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đã chi ${CurrencyFormatter.formatVnd(budget.spentAmount)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'Hạn mức ${CurrencyFormatter.formatVnd(budget.limitAmount)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Chi trung bình/ngày',
                value: CurrencyFormatter.formatVnd(budget.dailyAverage),
                footnote: '${budget.elapsedDays} ngày đã qua',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                label: 'Gợi ý chi/ngày',
                value: CurrencyFormatter.formatVnd(budget.dailySuggested),
                footnote: '${budget.remainingDays} ngày còn lại',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Ví áp dụng',
                value: _walletNamesLabel(budget),
                onTap: _openQuickWalletPicker,
              ),
              const Divider(height: 1, color: AppColors.progressTrack),
              _SettingRow(
                icon: Icons.notifications_none_rounded,
                label: 'Cảnh báo',
                value: alertSubtitle,
                onTap: _openEdit,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Giao dịch gần đây',
                      style: AppTypography.section,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAllTransactions(budget),
                    child: Text(
                      'Xem tất cả',
                      style: AppTypography.caption.copyWith(
                        color: const Color(0xFF3A8FDC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (recent.isEmpty)
                Text(
                  'Chưa có giao dịch chi tiêu nào thuộc ngân sách này.',
                  style: AppTypography.caption,
                )
              else
                for (var i = 0; i < recent.length; i++) ...[
                  _TransactionRow(
                    item: recent[i],
                    referenceDate: budget.referenceDate,
                  ),
                  if (i < recent.length - 1) const SizedBox(height: AppSpacing.md),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.footnote,
  });

  final String label;
  final String value;
  final String footnote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.captionSmall),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.section),
          const SizedBox(height: 2),
          Text(footnote, style: AppTypography.captionSmall),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: const Color(0xFF3699ED)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.captionSmall),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.slate,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.item,
    this.referenceDate,
  });

  final BudgetTransactionItem item;
  final DateTime? referenceDate;

  @override
  Widget build(BuildContext context) {
    final dayLabel = AppDateTime.formatRelativeDay(
      item.date,
      reference: referenceDate,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTypography.bodySemiBold),
              Text(
                '$dayLabel · ${item.walletName}',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          CurrencyFormatter.formatSignedVnd(item.amount),
          style: AppTypography.bodySemiBold,
        ),
      ],
    );
  }
}
