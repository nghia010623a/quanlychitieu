import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_date_time.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/budget.dart';

/// Result returned from [showPeriodPickerSheet] (UI-08.3).
class PeriodPickerResult {
  const PeriodPickerResult({
    required this.periodType,
    required this.startDate,
    required this.endDate,
  });

  final BudgetPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
}

/// Computes default start and end dates for a given [BudgetPeriodType].
(DateTime, DateTime) defaultDatesForPeriod(
  BudgetPeriodType type, {
  DateTime? reference,
}) {
  final ref = reference ?? DateTime.now();
  switch (type) {
    case BudgetPeriodType.week:
      final weekday = ref.weekday;
      final start = DateTime(ref.year, ref.month, ref.day - (weekday - 1));
      final end = start.add(const Duration(days: 6));
      return (start, end);
    case BudgetPeriodType.month:
      final start = DateTime(ref.year, ref.month, 1);
      final end = DateTime(ref.year, ref.month + 1, 0);
      return (start, end);
    case BudgetPeriodType.quarter:
      final quarterStartMonth = ((ref.month - 1) ~/ 3) * 3 + 1;
      final start = DateTime(ref.year, quarterStartMonth, 1);
      final end = DateTime(ref.year, quarterStartMonth + 3, 0);
      return (start, end);
    case BudgetPeriodType.custom:
      final start = DateTime(ref.year, ref.month, 1);
      final end = DateTime(ref.year, ref.month + 1, 0);
      return (start, end);
  }
}

/// Shows UI-08.3 bottom sheet to select budget period.
Future<PeriodPickerResult?> showPeriodPickerSheet(
  BuildContext context, {
  required BudgetPeriodType initialPeriod,
  required DateTime initialStart,
  required DateTime initialEnd,
}) {
  return showModalBottomSheet<PeriodPickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.navy.withValues(alpha: 0.4),
    builder: (sheetContext) {
      var selected = initialPeriod;
      var customStart = initialStart;
      var customEnd = initialEnd;

      return StatefulBuilder(
        builder: (context, setModalState) {
          final weekDates = defaultDatesForPeriod(BudgetPeriodType.week);
          final monthDates = defaultDatesForPeriod(BudgetPeriodType.month);
          final quarterDates = defaultDatesForPeriod(BudgetPeriodType.quarter);

          Future<void> pickCustomRange() async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2024, 1, 1),
              lastDate: DateTime(2030, 12, 31),
              initialDateRange: DateTimeRange(start: customStart, end: customEnd),
            );
            if (picked != null) {
              setModalState(() {
                selected = BudgetPeriodType.custom;
                customStart = picked.start;
                customEnd = picked.end;
              });
            }
          }

          return _KeepooBottomSheetFrame(
            title: 'Chọn kỳ ngân sách',
            subtitle: 'Hạn mức sẽ được tính lại theo từng kỳ.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RadioPeriodTile(
                  title: 'Hằng tuần',
                  subtitle:
                      'Thứ Hai – Chủ nhật · ${AppDateTime.formatCompactRange(weekDates.$1, weekDates.$2)}',
                  selected: selected == BudgetPeriodType.week,
                  onTap: () => setModalState(() => selected = BudgetPeriodType.week),
                ),
                const SizedBox(height: AppSpacing.sm),
                _RadioPeriodTile(
                  title: 'Hằng tháng',
                  subtitle: AppDateTime.formatDateRange(monthDates.$1, monthDates.$2),
                  selected: selected == BudgetPeriodType.month,
                  onTap: () => setModalState(() => selected = BudgetPeriodType.month),
                ),
                const SizedBox(height: AppSpacing.sm),
                _RadioPeriodTile(
                  title: 'Hằng quý',
                  subtitle:
                      'Quý ${((quarterDates.$1.month - 1) ~/ 3) + 1}/${quarterDates.$1.year} · ${AppDateTime.formatCompactRange(quarterDates.$1, quarterDates.$2)}',
                  selected: selected == BudgetPeriodType.quarter,
                  onTap: () =>
                      setModalState(() => selected = BudgetPeriodType.quarter),
                ),
                const SizedBox(height: AppSpacing.sm),
                _RadioPeriodTile(
                  title: 'Tùy chỉnh',
                  subtitle: selected == BudgetPeriodType.custom
                      ? AppDateTime.formatDateRange(customStart, customEnd)
                      : 'Tự chọn ngày bắt đầu và kết thúc',
                  selected: selected == BudgetPeriodType.custom,
                  onTap: () async {
                    setModalState(() => selected = BudgetPeriodType.custom);
                    await pickCustomRange();
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Áp dụng',
                  onPressed: () {
                    final range = selected == BudgetPeriodType.custom
                        ? (customStart, customEnd)
                        : defaultDatesForPeriod(selected);
                    Navigator.of(sheetContext).pop(
                      PeriodPickerResult(
                        periodType: selected,
                        startDate: range.$1,
                        endDate: range.$2,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Shows UI-08.4 bottom sheet to select applied wallets.
Future<List<String>?> showWalletPickerSheet(
  BuildContext context, {
  required List<BudgetWalletOption> wallets,
  required List<String> initialSelectedIds,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.navy.withValues(alpha: 0.4),
    builder: (sheetContext) {
      final selectedIds = Set<String>.from(initialSelectedIds);
      final totalBalance =
          wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);

      return StatefulBuilder(
        builder: (context, setModalState) {
          final allSelected =
              wallets.isNotEmpty && selectedIds.length == wallets.length;

          void toggleAll() {
            setModalState(() {
              if (allSelected) {
                selectedIds.clear();
              } else {
                selectedIds
                  ..clear()
                  ..addAll(wallets.map((w) => w.id));
              }
            });
          }

          void toggleWallet(String id) {
            setModalState(() {
              if (selectedIds.contains(id)) {
                selectedIds.remove(id);
              } else {
                selectedIds.add(id);
              }
            });
          }

          final count = selectedIds.length;
          final confirmLabel =
              count == 0 ? 'Chọn ít nhất 1 ví' : 'Xác nhận ($count ví)';

          return _KeepooBottomSheetFrame(
            title: 'Ví áp dụng',
            subtitle:
                'Chỉ giao dịch từ các ví đã chọn mới được tính vào ngân sách.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WalletCheckboxTile(
                  title: 'Tất cả ví',
                  subtitle:
                      '${wallets.length} ví · ${CurrencyFormatter.formatVnd(totalBalance)}',
                  checked: allSelected,
                  onTap: toggleAll,
                ),
                for (final wallet in wallets) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _WalletCheckboxTile(
                    title: wallet.name,
                    subtitle:
                        'Số dư ${CurrencyFormatter.formatVnd(wallet.balance)}',
                    checked: selectedIds.contains(wallet.id),
                    onTap: () => toggleWallet(wallet.id),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: confirmLabel,
                  variant: count == 0
                      ? AppButtonVariant.disabled
                      : AppButtonVariant.primary,
                  onPressed: count == 0
                      ? null
                      : () => Navigator.of(sheetContext).pop(
                            wallets
                                .where((w) => selectedIds.contains(w.id))
                                .map((w) => w.id)
                                .toList(),
                          ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _KeepooBottomSheetFrame extends StatelessWidget {
  const _KeepooBottomSheetFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F172D4D),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.disabledSurface,
                    borderRadius: AppRadii.pillBorder,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: AppTypography.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: AppTypography.caption,
              ),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioPeriodTile extends StatelessWidget {
  const _RadioPeriodTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.white,
      borderRadius: AppRadii.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardBorder,
            border: Border.all(
              color: selected ? const Color(0xFF76B6F2) : AppColors.progressTrack,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF3A8FDC)
                        : AppColors.disabledSurface,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3A8FDC),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodySemiBold),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletCheckboxTile extends StatelessWidget {
  const _WalletCheckboxTile({
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? AppColors.primarySoft : AppColors.white,
      borderRadius: AppRadii.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.cardBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardBorder,
            border: Border.all(
              color: checked ? const Color(0xFF76B6F2) : AppColors.progressTrack,
              width: checked ? 1.5 : 1,
            ),
          ),
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
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: Color(0xFF3699ED),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodySemiBold),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checked ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: checked
                      ? null
                      : Border.all(
                          color: AppColors.disabledSurface,
                          width: 2,
                        ),
                ),
                alignment: Alignment.center,
                child: checked
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.navy,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
