import '../../domain/entities/budget.dart';

/// Data transfer model mapping between JSON payloads and [BudgetEntity].
class BudgetModel extends BudgetEntity {
  const BudgetModel({
    required super.id,
    required super.category,
    required super.limitAmount,
    required super.spentAmount,
    required super.periodType,
    required super.startDate,
    required super.endDate,
    required super.walletIds,
    required super.alertPercent,
    required super.repeatMonthly,
    super.transactions,
    super.referenceDate,
  });

  factory BudgetModel.fromEntity(BudgetEntity entity) {
    return BudgetModel(
      id: entity.id,
      category: entity.category,
      limitAmount: entity.limitAmount,
      spentAmount: entity.spentAmount,
      periodType: entity.periodType,
      startDate: entity.startDate,
      endDate: entity.endDate,
      walletIds: List<String>.from(entity.walletIds),
      alertPercent: entity.alertPercent,
      repeatMonthly: entity.repeatMonthly,
      transactions: entity.transactions,
      referenceDate: entity.referenceDate,
    );
  }

  factory BudgetModel.fromJson(
    Map<String, dynamic> json, {
    required BudgetCategory category,
    List<BudgetTransactionItem> transactions = const [],
  }) {
    final periodRaw = (json['period'] as String? ?? 'MONTH').toUpperCase();
    final periodType = switch (periodRaw) {
      'DAY' || 'WEEK' => BudgetPeriodType.week,
      'QUARTER' || 'YEAR' => BudgetPeriodType.quarter,
      'CUSTOM' => BudgetPeriodType.custom,
      _ => BudgetPeriodType.month,
    };

    return BudgetModel(
      id: json['budgetId'].toString(),
      category: category,
      limitAmount: (json['amount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num? ?? 0).toDouble(),
      periodType: periodType,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      walletIds: (json['walletIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      alertPercent: (json['alertPercent'] as num? ?? 80).round(),
      repeatMonthly: json['repeatMonthly'] as bool? ?? true,
      transactions: transactions,
    );
  }

  Map<String, dynamic> toJson() {
    final backendPeriod = switch (periodType) {
      BudgetPeriodType.week => 'WEEK',
      BudgetPeriodType.month => 'MONTH',
      BudgetPeriodType.quarter => 'CUSTOM',
      BudgetPeriodType.custom => 'CUSTOM',
    };

    return {
      'budgetId': id,
      'categoryId': category.id,
      'budgetName': category.name,
      'amount': limitAmount,
      'period': backendPeriod,
      'startDate': startDate.toIso8601String().split('T').first,
      'endDate': endDate.toIso8601String().split('T').first,
      'walletIds': walletIds,
      'alertPercent': alertPercent,
      'repeatMonthly': repeatMonthly,
    };
  }
}
