import 'package:flutter/material.dart';

import '../../../../core/utils/app_date_time.dart';
import '../../../../core/widgets/app_category_icon.dart';

/// Budget cycle period matching UI-08.2 / UI-08.3 and backend `BudgetPeriod`.
enum BudgetPeriodType {
  week('Tuần', 'Hằng tuần'),
  month('Tháng', 'Hằng tháng'),
  quarter('Quý', 'Hằng quý'),
  custom('Tùy chỉnh', 'Tùy chỉnh');

  const BudgetPeriodType(this.shortLabel, this.sheetLabel);

  final String shortLabel;
  final String sheetLabel;
}

/// Budget lifecycle status matching backend `BudgetStatus` (`ACTIVE`, `INACTIVE`).
enum BudgetEntityStatus {
  active,
  inactive,
}

/// Visual status for a budget based on spent vs limit and alert threshold.
enum BudgetHealthStatus {
  onTrack('Trong hạn mức'),
  nearLimit('Sắp hết'),
  overLimit('Vượt hạn mức');

  const BudgetHealthStatus(this.label);

  final String label;
}

/// Category metadata used when creating or displaying budgets (maps to `categories`).
class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.tone,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final IconData icon;
  final AppCategoryTone tone;
  final bool isDefault;
}

/// Wallet option available for applying a budget (maps to `wallets`).
class BudgetWalletOption {
  const BudgetWalletOption({
    required this.id,
    required this.name,
    required this.balance,
    this.currency = 'VND',
  });

  final String id;
  final String name;
  final double balance;
  final String currency;
}

/// Transaction item counted against a budget.
class BudgetTransactionItem {
  const BudgetTransactionItem({
    required this.id,
    required this.title,
    required this.walletId,
    required this.walletName,
    required this.date,
    required this.amount,
  });

  final String id;
  final String title;
  final String walletId;
  final String walletName;
  final DateTime date;
  final double amount;
}

/// Daily spending point used for the progress chart in UI-08.6.
class BudgetDailyPoint {
  const BudgetDailyPoint({
    required this.date,
    required this.dailyAmount,
    required this.cumulativeAmount,
  });

  final DateTime date;
  final double dailyAmount;
  final double cumulativeAmount;
}

/// Alert milestone row in UI-08.6 (`50%`, `80%`, `100%`).
class BudgetMilestone {
  const BudgetMilestone({
    required this.percent,
    required this.targetAmount,
    this.achievedDate,
    this.projectedDate,
  });

  final int percent;
  final double targetAmount;
  final DateTime? achievedDate;
  final DateTime? projectedDate;

  bool get isAchieved => achievedDate != null;
}

/// Core domain entity for a user budget (maps to `budgets` table).
class BudgetEntity {
  const BudgetEntity({
    required this.id,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.walletIds,
    required this.alertPercent,
    required this.repeatMonthly,
    this.budgetName,
    this.status = BudgetEntityStatus.active,
    this.transactions = const [],
    this.referenceDate,
  });

  final String id;
  final BudgetCategory category;
  final double limitAmount;
  final double spentAmount;
  final BudgetPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> walletIds;
  final int alertPercent;
  final bool repeatMonthly;
  final String? budgetName;
  final BudgetEntityStatus status;
  final List<BudgetTransactionItem> transactions;
  final DateTime? referenceDate;

  String get displayName =>
      (budgetName != null && budgetName!.trim().isNotEmpty)
          ? budgetName!
          : category.name;

  DateTime get _today => referenceDate ?? DateTime(2026, 11, 15);

  double get remainingAmount => limitAmount - spentAmount;

  double get overLimitAmount =>
      spentAmount > limitAmount ? spentAmount - limitAmount : 0;

  double get progressRatio =>
      limitAmount <= 0 ? 0 : spentAmount / limitAmount;

  int get progressPercent => (progressRatio * 100).round();

  BudgetHealthStatus get healthStatus {
    if (progressPercent > 100) return BudgetHealthStatus.overLimit;
    if (progressPercent >= alertPercent) return BudgetHealthStatus.nearLimit;
    return BudgetHealthStatus.onTrack;
  }

  int get totalDays => endDate.difference(startDate).inDays + 1;

  int get elapsedDays {
    final diff = _today.difference(startDate).inDays;
    if (diff < 1) return 1;
    if (diff > totalDays) return totalDays;
    return diff;
  }

  int get remainingDays {
    final diff = endDate.difference(_today).inDays + 1;
    if (diff < 0) return 0;
    return diff;
  }

  double get dailyAverage =>
      elapsedDays <= 0 ? 0 : spentAmount / elapsedDays;

  double get dailySuggested {
    if (remainingAmount <= 0) return 0;
    if (remainingDays <= 0) return remainingAmount;
    return remainingAmount / remainingDays;
  }

  String get periodSummaryLabel {
    return switch (periodType) {
      BudgetPeriodType.month => AppDateTime.formatMonthYear(startDate),
      BudgetPeriodType.week =>
        'Tuần ${AppDateTime.formatCompactRange(startDate, endDate)}',
      BudgetPeriodType.quarter =>
        'Quý ${((startDate.month - 1) ~/ 3) + 1}/${startDate.year}',
      BudgetPeriodType.custom => AppDateTime.formatCompactRange(startDate, endDate),
    };
  }

  /// Generates daily and cumulative points up to [_today].
  List<BudgetDailyPoint> buildDailySeries() {
    final daysPassed = elapsedDays;
    if (daysPassed <= 0 || spentAmount <= 0) {
      return [
        BudgetDailyPoint(
          date: startDate,
          dailyAmount: 0,
          cumulativeAmount: 0,
        ),
      ];
    }

    // Weight factors give a natural spending curve while summing to spentAmount.
    const weights = <double>[
      0.03, 0.04, 0.03, 0.05, 0.08, 0.09, 0.07,
      0.11, 0.08, 0.06, 0.12, 0.07, 0.06, 0.11,
    ];
    final points = <BudgetDailyPoint>[];
    var totalWeight = 0.0;
    for (var i = 0; i < daysPassed; i++) {
      totalWeight += weights[i % weights.length];
    }

    var cumulative = 0.0;
    for (var i = 0; i < daysPassed; i++) {
      final date = startDate.add(Duration(days: i));
      final w = weights[i % weights.length] / totalWeight;
      final daily = (spentAmount * w).roundToDouble();
      cumulative = i == daysPassed - 1 ? spentAmount : cumulative + daily;
      points.add(
        BudgetDailyPoint(
          date: date,
          dailyAmount: daily,
          cumulativeAmount: cumulative,
        ),
      );
    }
    return points;
  }

  /// Estimates milestone achieved/projected dates for 50%, [alertPercent], and 100%.
  List<BudgetMilestone> buildMilestones() {
    final percents = <int>{50, alertPercent, 100}.toList()..sort();
    final series = buildDailySeries();
    final avg = dailyAverage;

    return percents.map((percent) {
      final target = limitAmount * (percent / 100.0);
      DateTime? achieved;
      for (final point in series) {
        if (point.cumulativeAmount >= target) {
          achieved = point.date;
          break;
        }
      }

      DateTime? projected;
      if (achieved == null && avg > 0) {
        final daysToReach = ((target - spentAmount) / avg).ceil();
        projected = _today.add(Duration(days: daysToReach));
      }

      return BudgetMilestone(
        percent: percent,
        targetAmount: target,
        achievedDate: achieved,
        projectedDate: projected,
      );
    }).toList();
  }

  /// Projected date when the budget reaches 100% at the current daily pace.
  DateTime? get projectedExhaustionDate {
    if (dailyAverage <= 0 || limitAmount <= 0) return null;
    if (spentAmount >= limitAmount) return _today;
    final daysLeftAtPace = ((limitAmount - spentAmount) / dailyAverage).ceil();
    return _today.add(Duration(days: daysLeftAtPace));
  }

  BudgetEntity copyWith({
    String? id,
    BudgetCategory? category,
    double? limitAmount,
    double? spentAmount,
    BudgetPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? walletIds,
    int? alertPercent,
    bool? repeatMonthly,
    String? budgetName,
    BudgetEntityStatus? status,
    List<BudgetTransactionItem>? transactions,
    DateTime? referenceDate,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      walletIds: walletIds ?? this.walletIds,
      alertPercent: alertPercent ?? this.alertPercent,
      repeatMonthly: repeatMonthly ?? this.repeatMonthly,
      budgetName: budgetName ?? this.budgetName,
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      referenceDate: referenceDate ?? this.referenceDate,
    );
  }
}
