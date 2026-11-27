import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_data_source.dart';

/// Repository implementation delegating budget operations to [BudgetRemoteDataSource].
class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({required this.remoteDataSource});

  final BudgetRemoteDataSource remoteDataSource;

  @override
  Future<List<BudgetCategory>> getCategories() =>
      remoteDataSource.fetchCategories();

  @override
  Future<List<BudgetWalletOption>> getWallets() =>
      remoteDataSource.fetchWallets();

  @override
  Future<List<BudgetPeriodFilterOption>> getPeriodFilters() =>
      remoteDataSource.fetchPeriodFilters();

  @override
  Future<List<BudgetEntity>> getBudgets({
    String? periodFilterId,
    String? walletId,
  }) =>
      remoteDataSource.fetchBudgets(
        periodFilterId: periodFilterId,
        walletId: walletId,
      );

  @override
  Future<BudgetEntity?> getBudgetById(String budgetId) =>
      remoteDataSource.fetchBudgetById(budgetId);

  @override
  Future<BudgetEntity> createBudget({
    required BudgetCategory category,
    required double limitAmount,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> walletIds,
    required int alertPercent,
    required bool repeatMonthly,
  }) =>
      remoteDataSource.createBudget(
        category: category,
        limitAmount: limitAmount,
        periodType: periodType,
        startDate: startDate,
        endDate: endDate,
        walletIds: walletIds,
        alertPercent: alertPercent,
        repeatMonthly: repeatMonthly,
      );

  @override
  Future<BudgetEntity> updateBudget(BudgetEntity budget) =>
      remoteDataSource.updateBudget(budget);

  @override
  Future<void> deleteBudget(String budgetId) =>
      remoteDataSource.deleteBudget(budgetId);
}
