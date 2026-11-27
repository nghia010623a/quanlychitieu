import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/budgets/budgets.dart';
import '../app_shell.dart';
import '../di/app_dependencies.dart';

/// Centralized named route definitions matching `project structure.md`.
abstract final class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String budgets = '/budgets';
  static const String budgetForm = '/budgets/form';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AppDependencies dependencies,
  ) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const loginWidget(),
          settings: settings,
        );
      case budgets:
        return MaterialPageRoute<void>(
          builder: (_) => BudgetListPage(
            repository: dependencies.budgetRepository,
            showBackButton: true,
          ),
          settings: settings,
        );
      case budgetForm:
        final existing = settings.arguments as BudgetEntity?;
        return MaterialPageRoute<void>(
          builder: (_) => BudgetFormPage(
            repository: dependencies.budgetRepository,
            existingBudget: existing,
          ),
          settings: settings,
        );
      case home:
      default:
        return MaterialPageRoute<void>(
          builder: (_) => AppShell(
            dependencies: dependencies,
            initialIndex: 2,
          ),
          settings: settings,
        );
    }
  }
}
