import '../../core/network/api_client.dart';
import '../../features/budgets/budgets.dart';

/// Shared application dependency container.
class AppDependencies {
  AppDependencies._({required this.budgetRepository});

  /// In-memory mock dependencies used by isolated widget tests.
  factory AppDependencies.mock() {
    final budgetDataSource = MockBudgetRemoteDataSource();
    return AppDependencies._(
      budgetRepository: BudgetRepositoryImpl(
        remoteDataSource: budgetDataSource,
      ),
    );
  }

  /// Live HTTP dependencies connected to the Spring Boot backend.
  factory AppDependencies.remote({ApiClient? apiClient}) {
    final client = apiClient ?? ApiClient();
    final budgetDataSource = HttpBudgetRemoteDataSource(apiClient: client);
    return AppDependencies._(
      budgetRepository: BudgetRepositoryImpl(
        remoteDataSource: budgetDataSource,
      ),
    );
  }

  final BudgetRepository budgetRepository;
}
