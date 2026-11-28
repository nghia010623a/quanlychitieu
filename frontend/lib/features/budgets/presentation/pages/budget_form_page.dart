import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page_bar.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../../../core/widgets/app_toggle.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../widgets/budget_dialogs.dart';
import '../widgets/budget_pickers.dart';

/// Result returned when closing [BudgetFormPage] in edit mode.
class BudgetFormResult {
  const BudgetFormResult({this.savedBudget, this.deleted = false});

  final BudgetEntity? savedBudget;
  final bool deleted;
}

/// UI-08.2 Tạo ngân sách & UI-08.7 Sửa ngân sách.
class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({
    required this.repository,
    this.existingBudget,
    this.initialCategory,
    this.initialStartDate,
    this.initialEndDate,
    super.key,
  });

  final BudgetRepository repository;
  final BudgetEntity? existingBudget;
  final BudgetCategory? initialCategory;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  bool get isEditing => existingBudget != null;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  static const List<int> _alertOptions = [50, 70, 80, 90];

  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<BudgetCategory> _categories = const [];
  List<BudgetWalletOption> _wallets = const [];

  late BudgetCategory _selectedCategory;
  late BudgetPeriodType _periodType;
  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _selectedWalletIds;
  late int _alertPercent;
  late bool _repeatMonthly;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _initForm();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  Future<void> _initForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        widget.repository.getCategories(),
        widget.repository.getWallets(),
      ]);

      final categories = results[0] as List<BudgetCategory>;
      final wallets = results[1] as List<BudgetWalletOption>;
      final existing = widget.existingBudget;

      if (existing == null && categories.isEmpty) {
        if (!mounted) return;
        setState(() {
          _categories = categories;
          _wallets = wallets;
          _errorMessage = 'Chưa có danh mục chi tiêu nào để tạo ngân sách.';
          _isLoading = false;
        });
        return;
      }

      if (existing != null) {
        _selectedCategory = categories.firstWhere(
          (c) => c.id == existing.category.id,
          orElse: () => existing.category,
        );
        _periodType = existing.periodType;
        _startDate = existing.startDate;
        _endDate = existing.endDate;
        _selectedWalletIds = List<String>.from(existing.walletIds);
        _alertPercent = existing.alertPercent;
        _repeatMonthly = existing.repeatMonthly;
        _amountController.text =
            CurrencyFormatter.formatVnd(existing.limitAmount, withSymbol: false);
      } else {
        _selectedCategory = widget.initialCategory ?? categories.first;
        _periodType = BudgetPeriodType.month;
        final defaultRange = defaultDatesForPeriod(
          BudgetPeriodType.month,
          reference: widget.initialStartDate,
        );
        _startDate = widget.initialStartDate ?? defaultRange.$1;
        _endDate = widget.initialEndDate ?? defaultRange.$2;
        _selectedWalletIds = wallets.map((w) => w.id).toList();
        _alertPercent = 80;
        _repeatMonthly = true;
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _wallets = wallets;
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

  double? get _parsedAmount =>
      CurrencyFormatter.tryParseVnd(_amountController.text);

  bool get _canSubmit =>
      (_parsedAmount ?? 0) > 0 &&
      _selectedWalletIds.isNotEmpty &&
      _errorMessage == null &&
      !_isSaving;

  String get _walletSummaryTitle {
    if (_wallets.isNotEmpty && _selectedWalletIds.length >= _wallets.length) {
      return 'Tất cả ví';
    }
    final names = _wallets
        .where((w) => _selectedWalletIds.contains(w.id))
        .map((w) => w.name)
        .toList();
    if (names.isEmpty) return 'Chưa chọn ví';
    return names.join(', ');
  }

  Future<void> _openPeriodSheet() async {
    final picked = await showPeriodPickerSheet(
      context,
      initialPeriod: _periodType,
      initialStart: _startDate,
      initialEnd: _endDate,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _periodType = picked.periodType;
      _startDate = picked.startDate;
      _endDate = picked.endDate;
    });
  }

  Future<void> _openWalletSheet() async {
    final picked = await showWalletPickerSheet(
      context,
      wallets: _wallets,
      initialSelectedIds: _selectedWalletIds,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedWalletIds = picked);
  }

  void _onPeriodTabChanged(int index) {
    final nextType = BudgetPeriodType.values[index];
    if (nextType == BudgetPeriodType.custom) {
      _openPeriodSheet();
      return;
    }
    final range = defaultDatesForPeriod(nextType);
    setState(() {
      _periodType = nextType;
      _startDate = range.$1;
      _endDate = range.$2;
    });
  }

  Future<void> _submit() async {
    final amount = _parsedAmount;
    if (amount == null || amount <= 0 || _selectedWalletIds.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      if (widget.isEditing) {
        final existing = widget.existingBudget!;
        final updated = await widget.repository.updateBudget(
          existing.copyWith(
            category: _selectedCategory,
            budgetName: _selectedCategory.name,
            limitAmount: amount,
            periodType: _periodType,
            startDate: _startDate,
            endDate: _endDate,
            walletIds: _selectedWalletIds,
            alertPercent: _alertPercent,
            repeatMonthly: _repeatMonthly,
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(BudgetFormResult(savedBudget: updated));
      } else {
        final created = await widget.repository.createBudget(
          category: _selectedCategory,
          limitAmount: amount,
          periodType: _periodType,
          startDate: _startDate,
          endDate: _endDate,
          walletIds: _selectedWalletIds,
          alertPercent: _alertPercent,
          repeatMonthly: _repeatMonthly,
        );
        if (!mounted) return;
        await showBudgetCreatedDialog(context, budget: created);
        if (!mounted) return;
        Navigator.of(context).pop(created);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existingBudget;
    if (existing == null) return;

    final confirmed = await showDeleteBudgetDialog(
      context,
      categoryName: existing.category.name,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await widget.repository.deleteBudget(existing.id);
      if (!mounted) return;
      Navigator.of(context).pop(const BudgetFormResult(deleted: true));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              title: widget.isEditing ? 'Sửa ngân sách' : 'Tạo ngân sách',
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _isLoading
                  ? const AppStateView.loading()
                  : _errorMessage != null
                      ? AppStateView.error(
                          title: 'Không tải được dữ liệu tạo ngân sách',
                          subtitle: _errorMessage,
                          onAction: _initForm,
                        )
                      : _buildFormBody(),
            ),
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
              child: _buildBottomButtons(),
            ),
    );
  }

  Widget _buildFormBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      children: [
        Text('Danh mục', style: AppTypography.bodySemiBold),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _categories.map((category) {
            final selected = category.id == _selectedCategory.id;
            return _SelectablePill(
              label: category.name,
              selected: selected,
              height: 44,
              horizontalPadding: AppSpacing.lg,
              onTap: () => setState(() => _selectedCategory = category),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Hạn mức chi tiêu', style: AppTypography.bodySemiBold),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadii.cardBorder,
            boxShadow: AppShadows.control,
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              VndInputFormatter(),
            ],
            style: AppTypography.body,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: 'Ví dụ: 3.000.000 ₫',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.placeholder,
              ),
              suffixText: _amountController.text.isEmpty ? null : '₫',
              suffixStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.slate,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 12,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Kỳ ngân sách', style: AppTypography.bodySemiBold),
        const SizedBox(height: AppSpacing.xs),
        AppSegmentedTabs(
          labels: BudgetPeriodType.values.map((e) => e.shortLabel).toList(),
          selectedIndex: _periodType.index,
          onChanged: _onPeriodTabChanged,
        ),
        const SizedBox(height: AppSpacing.xs),
        _PickerTile(
          icon: Icons.calendar_today_outlined,
          label: 'Thời gian áp dụng',
          value: AppDateTime.formatDateRange(_startDate, _endDate),
          onTap: _openPeriodSheet,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Ví áp dụng', style: AppTypography.bodySemiBold),
        const SizedBox(height: AppSpacing.xs),
        _PickerTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Áp dụng cho ${_selectedWalletIds.length} ví',
          value: _walletSummaryTitle,
          onTap: _openWalletSheet,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Cảnh báo khi chi đạt', style: AppTypography.bodySemiBold),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (var i = 0; i < _alertOptions.length; i++) ...[
              Expanded(
                child: _SelectablePill(
                  label: '${_alertOptions[i]}%',
                  selected: _alertPercent == _alertOptions[i],
                  height: 40,
                  onTap: () =>
                      setState(() => _alertPercent = _alertOptions[i]),
                ),
              ),
              if (i < _alertOptions.length - 1)
                const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
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
                child: const Icon(
                  Icons.repeat_rounded,
                  size: 18,
                  color: Color(0xFF3699ED),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lặp lại hằng kỳ', style: AppTypography.bodySemiBold),
                    Text(
                      'Tự tạo ngân sách mới khi kỳ kết thúc',
                      style: AppTypography.captionSmall,
                    ),
                  ],
                ),
              ),
              AppToggle(
                value: _repeatMonthly,
                semanticLabel: 'Lặp lại hằng kỳ',
                onChanged: (value) => setState(() => _repeatMonthly = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    if (widget.isEditing) {
      return Row(
        children: [
          Expanded(
            child: Material(
              color: AppColors.shoppingSurface,
              borderRadius: AppRadii.pillBorder,
              child: InkWell(
                onTap: _confirmDelete,
                borderRadius: AppRadii.pillBorder,
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  child: Text(
                    'Xóa ngân sách',
                    style: AppTypography.button.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: AppButton(
              label: 'Lưu thay đổi',
              variant: _canSubmit
                  ? AppButtonVariant.primary
                  : AppButtonVariant.disabled,
              onPressed: _canSubmit ? _submit : null,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Hủy',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: AppButton(
            label: 'Tạo ngân sách',
            variant: _canSubmit
                ? AppButtonVariant.primary
                : AppButtonVariant.disabled,
            onPressed: _canSubmit ? _submit : null,
          ),
        ),
      ],
    );
  }
}

class _SelectablePill extends StatelessWidget {
  const _SelectablePill({
    required this.label,
    required this.selected,
    required this.height,
    required this.onTap,
    this.horizontalPadding = 0,
  });

  final String label;
  final bool selected;
  final double height;
  final double horizontalPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: AppRadii.pillBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillBorder,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillBorder,
            boxShadow: AppShadows.control,
          ),
          alignment: horizontalPadding > 0 ? null : Alignment.center,
          child: Center(
            widthFactor: horizontalPadding > 0 ? 1 : null,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: (selected
                      ? AppTypography.button
                      : AppTypography.bodySemiBold)
                  .copyWith(
                fontSize: height < 44 ? 13 : 14,
                color: selected || height >= 44
                    ? AppColors.navy
                    : AppColors.slate,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
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
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      onTap: onTap,
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
                  style: AppTypography.bodySemiBold,
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
    );
  }
}
