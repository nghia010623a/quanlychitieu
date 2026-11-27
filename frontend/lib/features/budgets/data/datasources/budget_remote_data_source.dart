import 'package:flutter/material.dart';

import '../../../../core/widgets/app_category_icon.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../models/budget_model.dart';

/// Remote/mock data source contract for the budgets feature.
abstract class BudgetRemoteDataSource {
  Future<List<BudgetCategory>> fetchCategories();

  Future<List<BudgetWalletOption>> fetchWallets();

  Future<List<BudgetPeriodFilterOption>> fetchPeriodFilters();

  Future<List<BudgetModel>> fetchBudgets({
    String? periodFilterId,
    String? walletId,
  });

  Future<BudgetModel?> fetchBudgetById(String budgetId);

  Future<BudgetModel> createBudget({
    required BudgetCategory category,
    required double limitAmount,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> walletIds,
    required int alertPercent,
    required bool repeatMonthly,
  });

  Future<BudgetModel> updateBudget(BudgetEntity budget);

  Future<void> deleteBudget(String budgetId);
}

/// In-memory mock implementation matching UI-08 Figma values until backend APIs are ready.
class MockBudgetRemoteDataSource implements BudgetRemoteDataSource {
  MockBudgetRemoteDataSource() {
    _seedInitialData();
  }

  static final DateTime _referenceToday = DateTime(2026, 11, 15);

  static const List<BudgetCategory> _categories = [
    BudgetCategory(
      id: 'cat_food',
      name: 'Ăn uống',
      icon: Icons.restaurant_rounded,
      tone: AppCategoryTone.food,
    ),
    BudgetCategory(
      id: 'cat_travel',
      name: 'Đi lại',
      icon: Icons.directions_car_outlined,
      tone: AppCategoryTone.travel,
    ),
    BudgetCategory(
      id: 'cat_shopping',
      name: 'Mua sắm',
      icon: Icons.shopping_bag_outlined,
      tone: AppCategoryTone.shopping,
    ),
    BudgetCategory(
      id: 'cat_home',
      name: 'Nhà ở',
      icon: Icons.home_outlined,
      tone: AppCategoryTone.neutral,
    ),
    BudgetCategory(
      id: 'cat_entertainment',
      name: 'Giải trí',
      icon: Icons.sports_esports_outlined,
      tone: AppCategoryTone.food,
    ),
    BudgetCategory(
      id: 'cat_health',
      name: 'Sức khỏe',
      icon: Icons.favorite_border_rounded,
      tone: AppCategoryTone.shopping,
    ),
    BudgetCategory(
      id: 'cat_other',
      name: 'Khác',
      icon: Icons.grid_view_rounded,
      tone: AppCategoryTone.neutral,
    ),
  ];

  static const List<BudgetWalletOption> _wallets = [
    BudgetWalletOption(
      id: 'w_cash',
      name: 'Ví tiền mặt',
      balance: 1200000,
    ),
    BudgetWalletOption(
      id: 'w_saving',
      name: 'Ví tiết kiệm',
      balance: 4200000,
    ),
    BudgetWalletOption(
      id: 'w_vcb',
      name: 'Ví Vietcombank',
      balance: 8500000,
    ),
  ];

  static final List<BudgetPeriodFilterOption> _periodFilters = [
    BudgetPeriodFilterOption(
      id: '2026-11',
      label: 'Tháng 11/2026',
      summaryHeading: 'Tổng chi tháng 11',
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
    ),
    BudgetPeriodFilterOption(
      id: '2026-10',
      label: 'Tháng 10/2026',
      summaryHeading: 'Tổng chi tháng 10',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
    ),
    BudgetPeriodFilterOption(
      id: '2026-12',
      label: 'Tháng 12/2026',
      summaryHeading: 'Tổng chi tháng 12',
      startDate: DateTime(2026, 12, 1),
      endDate: DateTime(2026, 12, 31),
    ),
  ];

  final List<BudgetModel> _budgets = [];
  int _nextId = 100;

  void _seedInitialData() {
    _budgets
      ..clear()
      ..addAll([
        BudgetModel(
          id: 'b_food_nov',
          category: _categories[0],
          limitAmount: 3000000,
          spentAmount: 1800000,
          periodType: BudgetPeriodType.month,
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 30),
          walletIds: const ['w_cash', 'w_vcb'],
          alertPercent: 80,
          repeatMonthly: true,
          referenceDate: _referenceToday,
          transactions: [
            BudgetTransactionItem(
              id: 't1',
              title: 'Bún chả Hương Liên',
              walletId: 'w_cash',
              walletName: 'Ví tiền mặt',
              date: DateTime(2026, 11, 15),
              amount: -85000,
            ),
            BudgetTransactionItem(
              id: 't2',
              title: 'Cà phê Highlands',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 11, 14),
              amount: -59000,
            ),
            BudgetTransactionItem(
              id: 't3',
              title: 'Đi chợ cuối tuần',
              walletId: 'w_cash',
              walletName: 'Ví tiền mặt',
              date: DateTime(2026, 11, 12),
              amount: -320000,
            ),
            BudgetTransactionItem(
              id: 't4',
              title: 'Ăn tối gia đình',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 11, 9),
              amount: -640000,
            ),
            BudgetTransactionItem(
              id: 't5',
              title: 'Siêu thị WinMart',
              walletId: 'w_cash',
              walletName: 'Ví tiền mặt',
              date: DateTime(2026, 11, 5),
              amount: -696000,
            ),
          ],
        ),
        BudgetModel(
          id: 'b_travel_nov',
          category: _categories[1],
          limitAmount: 1000000,
          spentAmount: 850000,
          periodType: BudgetPeriodType.month,
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 30),
          walletIds: const ['w_cash', 'w_vcb'],
          alertPercent: 80,
          repeatMonthly: true,
          referenceDate: _referenceToday,
          transactions: [
            BudgetTransactionItem(
              id: 't6',
              title: 'Đổ xăng Petrolimex',
              walletId: 'w_cash',
              walletName: 'Ví tiền mặt',
              date: DateTime(2026, 11, 14),
              amount: -180000,
            ),
            BudgetTransactionItem(
              id: 't7',
              title: 'Grab đi làm',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 11, 11),
              amount: -245000,
            ),
            BudgetTransactionItem(
              id: 't8',
              title: 'Vé gửi xe tháng',
              walletId: 'w_cash',
              walletName: 'Ví tiền mặt',
              date: DateTime(2026, 11, 2),
              amount: -425000,
            ),
          ],
        ),
        BudgetModel(
          id: 'b_shopping_nov',
          category: _categories[2],
          limitAmount: 1500000,
          spentAmount: 1900000,
          periodType: BudgetPeriodType.month,
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 30),
          walletIds: const ['w_saving', 'w_vcb'],
          alertPercent: 80,
          repeatMonthly: false,
          referenceDate: _referenceToday,
          transactions: [
            BudgetTransactionItem(
              id: 't9',
              title: 'Uniqlo áo khoác',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 11, 13),
              amount: -1190000,
            ),
            BudgetTransactionItem(
              id: 't10',
              title: 'Shopee đồ gia dụng',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 11, 7),
              amount: -710000,
            ),
          ],
        ),
        BudgetModel(
          id: 'b_home_nov',
          category: _categories[3],
          limitAmount: 2500000,
          spentAmount: 800000,
          periodType: BudgetPeriodType.month,
          startDate: DateTime(2026, 11, 1),
          endDate: DateTime(2026, 11, 30),
          walletIds: const ['w_cash', 'w_saving', 'w_vcb'],
          alertPercent: 80,
          repeatMonthly: true,
          referenceDate: _referenceToday,
          transactions: [
            BudgetTransactionItem(
              id: 't11',
              title: 'Tiền điện tháng 11',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 11, 10),
              amount: -520000,
            ),
            BudgetTransactionItem(
              id: 't12',
              title: 'Tiền internet FPT',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 11, 5),
              amount: -280000,
            ),
          ],
        ),
        BudgetModel(
          id: 'b_food_oct',
          category: _categories[0],
          limitAmount: 2800000,
          spentAmount: 2150000,
          periodType: BudgetPeriodType.month,
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 31),
          walletIds: const ['w_cash', 'w_vcb'],
          alertPercent: 80,
          repeatMonthly: true,
          referenceDate: DateTime(2026, 10, 31),
          transactions: [
            BudgetTransactionItem(
              id: 't13',
              title: 'Tổng hợp ăn uống tháng 10',
              walletId: 'w_vcb',
              walletName: 'Ví Vietcombank',
              date: DateTime(2026, 10, 28),
              amount: -2150000,
            ),
          ],
        ),
      ]);
  }

  @override
  Future<List<BudgetCategory>> fetchCategories() async => _categories;

  @override
  Future<List<BudgetWalletOption>> fetchWallets() async => _wallets;

  @override
  Future<List<BudgetPeriodFilterOption>> fetchPeriodFilters() async =>
      _periodFilters;

  @override
  Future<List<BudgetModel>> fetchBudgets({
    String? periodFilterId,
    String? walletId,
  }) async {
    final filter = periodFilterId == null
        ? _periodFilters.first
        : _periodFilters.firstWhere(
            (p) => p.id == periodFilterId,
            orElse: () => _periodFilters.first,
          );

    return _budgets.where((b) {
      final overlapsPeriod = !b.endDate.isBefore(filter.startDate) &&
          !b.startDate.isAfter(filter.endDate);
      final matchesWallet = walletId == null ||
          walletId.isEmpty ||
          b.walletIds.contains(walletId);
      return overlapsPeriod && matchesWallet;
    }).toList();
  }

  @override
  Future<BudgetModel?> fetchBudgetById(String budgetId) async {
    for (final budget in _budgets) {
      if (budget.id == budgetId) return budget;
    }
    return null;
  }

  @override
  Future<BudgetModel> createBudget({
    required BudgetCategory category,
    required double limitAmount,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> walletIds,
    required int alertPercent,
    required bool repeatMonthly,
  }) async {
    _nextId++;
    final created = BudgetModel(
      id: 'b_$_nextId',
      category: category,
      limitAmount: limitAmount,
      spentAmount: 0,
      periodType: periodType,
      startDate: startDate,
      endDate: endDate,
      walletIds: List<String>.from(walletIds),
      alertPercent: alertPercent,
      repeatMonthly: repeatMonthly,
      referenceDate: _referenceToday,
    );
    _budgets.insert(0, created);
    return created;
  }

  @override
  Future<BudgetModel> updateBudget(BudgetEntity budget) async {
    final model = BudgetModel.fromEntity(budget);
    final index = _budgets.indexWhere((b) => b.id == model.id);
    if (index != -1) {
      _budgets[index] = model;
    }
    return model;
  }

  @override
  Future<void> deleteBudget(String budgetId) async {
    _budgets.removeWhere((b) => b.id == budgetId);
  }
}
