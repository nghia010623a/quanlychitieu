import '../../domain/entities/budget.dart';

/// Data transfer model mapping between backend `Budget` JSON payloads and [BudgetEntity].
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
    super.budgetName,
    super.status,
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
      budgetName: entity.budgetName,
      status: entity.status,
      transactions: entity.transactions,
      referenceDate: entity.referenceDate,
    );
  }

  factory BudgetModel.fromJson(
    Map<String, dynamic> json, {
    required BudgetCategory category,
    List<BudgetTransactionItem>? transactions,
    DateTime? referenceDate,
  }) {
    final periodRaw = (json['period'] as String? ?? 'MONTH').toUpperCase();
    final periodType = switch (periodRaw) {
      'DAY' || 'WEEK' => BudgetPeriodType.week,
      'QUARTER' || 'YEAR' => BudgetPeriodType.quarter,
      'CUSTOM' => BudgetPeriodType.custom,
      _ => BudgetPeriodType.month,
    };

    final startDate = DateTime.parse(json['startDate'] as String);
    final rawEndDate = json['endDate'] as String?;
    final endDate = rawEndDate != null
        ? DateTime.parse(rawEndDate)
        : switch (periodType) {
            BudgetPeriodType.week => startDate.add(const Duration(days: 6)),
            BudgetPeriodType.month =>
              DateTime(startDate.year, startDate.month + 1, 0),
            BudgetPeriodType.quarter =>
              DateTime(startDate.year, startDate.month + 3, 0),
            BudgetPeriodType.custom => startDate,
          };

    final rawWalletIds = json['walletIds'] as List<dynamic>?;
    final singleWalletId =
        json['walletId'] ?? (json['wallet'] as Map<String, dynamic>?)?['walletId'];
    final walletIds = rawWalletIds != null && rawWalletIds.isNotEmpty
        ? rawWalletIds.map((e) => e.toString()).toList()
        : (singleWalletId != null ? [singleWalletId.toString()] : <String>[]);

    final statusRaw = (json['status'] as String? ?? 'ACTIVE').toUpperCase();
    final status = statusRaw == 'INACTIVE'
        ? BudgetEntityStatus.inactive
        : BudgetEntityStatus.active;

    final parsedTransactions = transactions ??
        (json['transactions'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((tx) {
              final rawTime = tx['transactionTime'] ?? tx['date'];
              final parsedDate = rawTime is String
                  ? DateTime.parse(rawTime)
                  : DateTime.now();
              return BudgetTransactionItem(
                id: (tx['transactionId'] ?? tx['id'] ?? '').toString(),
                title: (tx['title'] as String?) ?? 'Chi tiêu',
                walletId: (tx['walletId'] ?? '').toString(),
                walletName: (tx['walletName'] as String?) ?? '',
                date: parsedDate,
                amount: (tx['amount'] as num? ?? 0).toDouble(),
              );
            })
            .toList();

    return BudgetModel(
      id: json['budgetId'].toString(),
      category: category,
      limitAmount: (json['amount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num? ?? 0).toDouble(),
      periodType: periodType,
      startDate: startDate,
      endDate: endDate,
      walletIds: walletIds,
      alertPercent: (json['alertPercent'] as num? ?? 80).round(),
      repeatMonthly: json['repeatMonthly'] as bool? ?? true,
      budgetName: json['budgetName'] as String?,
      status: status,
      transactions: parsedTransactions,
      referenceDate: referenceDate,
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
      if (walletIds.isNotEmpty) 'walletId': walletIds.first,
      'walletIds': walletIds,
      'categoryId': category.id,
      'budgetName': displayName,
      'amount': limitAmount,
      'period': backendPeriod,
      'startDate': startDate.toIso8601String().split('T').first,
      'endDate': endDate.toIso8601String().split('T').first,
      'alertPercent': alertPercent,
      'status': status == BudgetEntityStatus.inactive ? 'INACTIVE' : 'ACTIVE',
      'repeatMonthly': repeatMonthly,
    };
  }
}
