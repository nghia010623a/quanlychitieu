import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_category_icon.dart';
import '../../../../core/widgets/app_page_bar.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import 'budget_detail_page.dart';
import 'budget_form_page.dart';

/// UI-08.1 Danh sách ngân sách (populated & empty state).
class BudgetListPage extends StatefulWidget {
  const BudgetListPage({
    required this.repository,
    this.showBackButton = false,
    this.onBack,
    super.key,
  });

  final BudgetRepository repository;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  State<BudgetListPage> createState() => _BudgetListPageState();
}

class _BudgetListPageState extends State<BudgetListPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<BudgetPeriodFilterOption> _periodFilters = const [];
  List<BudgetWalletOption> _wallets = const [];
  List<BudgetCategory> _categories = const [];
  List<BudgetEntity> _budgets = const [];

  String? _selectedPeriodId;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        widget.repository.getPeriodFilters(),
        widget.repository.getWallets(),
        widget.repository.getCategories(),
      ]);

      final periods = results[0] as List<BudgetPeriodFilterOption>;
      final wallets = results[1] as List<BudgetWalletOption>;
      final categories = results[2] as List<BudgetCategory>;

      final initialPeriodId =
          _selectedPeriodId ?? (periods.isNotEmpty ? periods.first.id : null);
      final budgets = await widget.repository.getBudgets(
        periodFilterId: initialPeriodId,
        walletId: _selectedWalletId,
      );

      if (!mounted) return;
      setState(() {
        _periodFilters = periods;
        _wallets = wallets;
        _categories = categories;
        _selectedPeriodId = initialPeriodId;
        _budgets = budgets;
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

  Future<void> _reloadBudgets() async {
    try {
      final budgets = await widget.repository.getBudgets(
        periodFilterId: _selectedPeriodId,
        walletId: _selectedWalletId,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        _budgets = budgets;
      });
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

  BudgetPeriodFilterOption? get _activePeriod {
    if (_periodFilters.isEmpty) return null;
    return _periodFilters.firstWhere(
      (p) => p.id == _selectedPeriodId,
      orElse: () => _periodFilters.first,
    );
  }

  String get _selectedWalletLabel {
    if (_selectedWalletId == null) return 'Tất cả ví';
    for (final wallet in _wallets) {
      if (wallet.id == _selectedWalletId) return wallet.name;
    }
    return 'Tất cả ví';
  }

  Future<void> _openPeriodFilterPicker() async {
    if (_periodFilters.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn kỳ hiển thị', style: AppTypography.title),
                const SizedBox(height: AppSpacing.md),
                for (final period in _periodFilters)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(period.label, style: AppTypography.bodySemiBold),
                    trailing: period.id == _selectedPeriodId
                        ? const Icon(Icons.check_rounded, color: Color(0xFF3699ED))
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(period.id),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null && picked != _selectedPeriodId) {
      setState(() => _selectedPeriodId = picked);
      await _reloadBudgets();
    }
  }

  Future<void> _openWalletFilterPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lọc theo ví', style: AppTypography.title),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Tất cả ví', style: AppTypography.bodySemiBold),
                  trailing: _selectedWalletId == null
                      ? const Icon(Icons.check_rounded, color: Color(0xFF3699ED))
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop('ALL'),
                ),
                for (final wallet in _wallets)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(wallet.name, style: AppTypography.bodySemiBold),
                    subtitle: Text(
                      CurrencyFormatter.formatVnd(wallet.balance),
                      style: AppTypography.caption,
                    ),
                    trailing: _selectedWalletId == wallet.id
                        ? const Icon(Icons.check_rounded, color: Color(0xFF3699ED))
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(wallet.id),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    final nextWalletId = picked == 'ALL' ? null : picked;
    if (nextWalletId != _selectedWalletId) {
      setState(() => _selectedWalletId = nextWalletId);
      await _reloadBudgets();
    }
  }

  Future<void> _openCreateBudget({BudgetCategory? initialCategory}) async {
    final createdBudget = await Navigator.of(context).push<BudgetEntity>(
      MaterialPageRoute(
        builder: (_) => BudgetFormPage(
          repository: widget.repository,
          initialCategory: initialCategory,
          initialStartDate: _activePeriod?.startDate,
          initialEndDate: _activePeriod?.endDate,
        ),
      ),
    );

    if (!mounted) return;
    await _reloadBudgets();

    if (createdBudget != null && mounted) {
      await _openDetail(createdBudget);
    }
  }

  Future<void> _openDetail(BudgetEntity budget) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BudgetDetailPage(
          repository: widget.repository,
          budgetId: budget.id,
        ),
      ),
    );
    if (mounted) {
      await _reloadBudgets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBudgets = _budgets.isNotEmpty;

    return AppPageScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageBar(
              title: 'Ngân sách',
              showBack: widget.showBackButton,
              onBack: widget.onBack,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFilterRow(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomBar: _isLoading || _errorMessage != null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: AppButton(
                label: hasBudgets
                    ? '+ Tạo ngân sách'
                    : '+ Tạo ngân sách đầu tiên',
                onPressed: () => _openCreateBudget(),
              ),
            ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _FilterPill(
            icon: Icons.calendar_today_outlined,
            label: _activePeriod?.label ?? 'Tháng 11/2026',
            onTap: _openPeriodFilterPicker,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _FilterPill(
            icon: Icons.account_balance_wallet_outlined,
            label: _selectedWalletLabel,
            onTap: _openWalletFilterPicker,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppStateView.loading();
    }
    if (_errorMessage != null) {
      return AppStateView.error(
        title: 'Không tải được ngân sách',
        subtitle: _errorMessage,
        onAction: _loadInitial,
      );
    }

    if (_budgets.isEmpty) {
      final quickCategories = _categories.take(3).toList();
      return AppStateView.empty(
        title: 'Chưa có ngân sách nào',
        subtitle:
            'Đặt hạn mức cho từng danh mục chi tiêu, Keepoo sẽ nhắc bạn khi sắp vượt.',
        footer: Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: quickCategories
              .map(
                (category) => _QuickCategoryChip(
                  label: category.name,
                  onTap: () => _openCreateBudget(initialCategory: category),
                ),
              )
              .toList(),
        ),
      );
    }

    final totalSpent =
        _budgets.fold<double>(0, (sum, item) => sum + item.spentAmount);
    final totalLimit =
        _budgets.fold<double>(0, (sum, item) => sum + item.limitAmount);
    final totalRemaining = totalLimit - totalSpent;
    final overCount = _budgets
        .where((b) => b.healthStatus == BudgetHealthStatus.overLimit)
        .length;
    final remainingDays = _budgets.first.remainingDays;
    final totalRatio = totalLimit <= 0 ? 0.0 : totalSpent / totalLimit;

    return RefreshIndicator(
      onRefresh: _reloadBudgets,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: [
          _SummaryCard(
            heading: _activePeriod?.summaryHeading ?? 'Tổng chi tháng 11',
            remainingDays: remainingDays,
            totalSpent: totalSpent,
            totalLimit: totalLimit,
            totalRemaining: totalRemaining,
            overLimitCount: overCount,
            progressRatio: totalRatio,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ngân sách của bạn',
                  style: AppTypography.section,
                ),
              ),
              Text(
                '${_budgets.length} ngân sách',
                style: AppTypography.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < _budgets.length; i++) ...[
            _BudgetListCard(
              budget: _budgets[i],
              onTap: () => _openDetail(_budgets[i]),
            ),
            if (i < _budgets.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppRadii.pillBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillBorder,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.pillBorder,
            boxShadow: AppShadows.control,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF3699ED)),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.slate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.heading,
    required this.remainingDays,
    required this.totalSpent,
    required this.totalLimit,
    required this.totalRemaining,
    required this.overLimitCount,
    required this.progressRatio,
  });

  final String heading;
  final int remainingDays;
  final double totalSpent;
  final double totalLimit;
  final double totalRemaining;
  final int overLimitCount;
  final double progressRatio;

  @override
  Widget build(BuildContext context) {
    final tone = totalSpent > totalLimit
        ? AppProgressTone.danger
        : progressRatio >= 0.8
            ? AppProgressTone.warning
            : AppProgressTone.primary;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(heading, style: AppTypography.caption),
              ),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadii.pillBorder,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Còn $remainingDays ngày',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.navy,
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
                CurrencyFormatter.formatVnd(totalSpent),
                style: AppTypography.display,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${CurrencyFormatter.formatVnd(totalLimit)}',
                  style: AppTypography.caption.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: progressRatio, tone: tone),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  totalRemaining >= 0
                      ? 'Còn lại ${CurrencyFormatter.formatVnd(totalRemaining)}'
                      : 'Vượt ${CurrencyFormatter.formatVnd(totalRemaining.abs())}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (overLimitCount > 0)
                Text(
                  '$overLimitCount ngân sách vượt hạn mức',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.dangerBright,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetListCard extends StatelessWidget {
  const _BudgetListCard({
    required this.budget,
    required this.onTap,
  });

  final BudgetEntity budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = budget.healthStatus;
    final progressTone = switch (status) {
      BudgetHealthStatus.overLimit => AppProgressTone.danger,
      BudgetHealthStatus.nearLimit => AppProgressTone.warning,
      BudgetHealthStatus.onTrack => AppProgressTone.primary,
    };

    final percentColor = switch (status) {
      BudgetHealthStatus.overLimit => AppColors.dangerBright,
      BudgetHealthStatus.nearLimit => AppColors.warningText,
      BudgetHealthStatus.onTrack => AppColors.navy,
    };

    final subtitleText = switch (status) {
      BudgetHealthStatus.overLimit =>
        'Vượt hạn mức ${CurrencyFormatter.formatVnd(budget.overLimitAmount)}',
      BudgetHealthStatus.nearLimit =>
        'Sắp hết · còn ${CurrencyFormatter.formatVnd(budget.remainingAmount)}',
      BudgetHealthStatus.onTrack =>
        'Đã chi ${CurrencyFormatter.formatVnd(budget.spentAmount)} / ${CurrencyFormatter.formatVnd(budget.limitAmount)}',
    };

    final subtitleColor = status == BudgetHealthStatus.overLimit
        ? AppColors.dangerBright
        : AppColors.slate;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppCategoryIcon(
                icon: budget.category.icon,
                tone: budget.category.tone,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category.name,
                      style: AppTypography.cardTitle,
                    ),
                    Text(
                      subtitleText,
                      style: AppTypography.captionSmall.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${budget.progressPercent}%',
                style: AppTypography.button.copyWith(color: percentColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            value: budget.progressRatio,
            tone: progressTone,
          ),
        ],
      ),
    );
  }
}

class _QuickCategoryChip extends StatelessWidget {
  const _QuickCategoryChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppRadii.pillBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillBorder,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillBorder,
            boxShadow: AppShadows.control,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 15, color: Color(0xFF3699ED)),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
