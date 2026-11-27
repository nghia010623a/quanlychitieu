import '../../features/budgets/budgets.dart';

/// Shared application dependency container.
class AppDependencies {
  AppDependencies._({required this.budgetRepository});

  factory AppDependencies.mock() {
    final budgetDataSource = MockBudgetRemoteDataSource();
    return AppDependencies._(
      budgetRepository: BudgetRepositoryImpl(
        remoteDataSource: budgetDataSource,
      ),
    );
  }

  final BudgetRepository budgetRepository;
}
