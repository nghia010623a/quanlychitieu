import '../entities/budget.dart';

/// Filter option shown in the period dropdown pill on UI-08.1.
class BudgetPeriodFilterOption {
  const BudgetPeriodFilterOption({
    required this.id,
    required this.label,
    required this.summaryHeading,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String label;
  final String summaryHeading;
  final DateTime startDate;
  final DateTime endDate;
}

/// Abstract contract for budget operations (implemented by mock/API repository).
abstract class BudgetRepository {
  Future<List<BudgetCategory>> getCategories();

  Future<List<BudgetWalletOption>> getWallets();

  Future<List<BudgetPeriodFilterOption>> getPeriodFilters();

  Future<List<BudgetEntity>> getBudgets({
    String? periodFilterId,
    String? walletId,
  });

  Future<BudgetEntity?> getBudgetById(String budgetId);

  Future<BudgetEntity> createBudget({
    required BudgetCategory category,
    required double limitAmount,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> walletIds,
    required int alertPercent,
    required bool repeatMonthly,
  });

  Future<BudgetEntity> updateBudget(BudgetEntity budget);

  Future<void> deleteBudget(String budgetId);
}
