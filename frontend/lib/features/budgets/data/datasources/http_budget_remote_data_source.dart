import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_category_icon.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../models/budget_model.dart';
import 'budget_remote_data_source.dart';

/// HTTP implementation of [BudgetRemoteDataSource] backed by Spring Boot `/api/*` endpoints.
class HttpBudgetRemoteDataSource implements BudgetRemoteDataSource {
  HttpBudgetRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Map<String, BudgetCategory> _categoryCache = const {};

  @override
  Future<List<BudgetCategory>> fetchCategories() async {
    final decoded = await apiClient.get(
      '/categories',
      queryParameters: const {'type': 'EXPENSE'},
    );
    final list = _asJsonMapList(decoded);
    final categories = list.map(_mapCategory).toList();
    _categoryCache = {
      for (final category in categories) category.id: category,
    };
    return categories;
  }

  @override
  Future<List<BudgetWalletOption>> fetchWallets() async {
    final decoded = await apiClient.get('/wallets');
    final list = _asJsonMapList(decoded);
    return list.map(_mapWallet).toList();
  }

  @override
  Future<List<BudgetPeriodFilterOption>> fetchPeriodFilters() async {
    final decoded = await apiClient.get('/budgets/periods');
    final list = _asJsonMapList(decoded);
    return list.map(_mapPeriodFilter).toList();
  }

  @override
  Future<List<BudgetModel>> fetchBudgets({
    String? periodFilterId,
    String? walletId,
  }) async {
    final categoriesById = await _ensureCategoryCache();
    final decoded = await apiClient.get(
      '/budgets',
      queryParameters: {
        'periodFilterId': periodFilterId,
        'walletId': walletId,
      },
    );
    final list = _asJsonMapList(decoded);
    final now = DateTime.now();
    return list
        .map(
          (json) => BudgetModel.fromJson(
            json,
            category: _resolveCategory(json, categoriesById),
            referenceDate: now,
          ),
        )
        .toList();
  }

  @override
  Future<BudgetModel?> fetchBudgetById(String budgetId) async {
    final categoriesById = await _ensureCategoryCache();
    try {
      final decoded = await apiClient.get('/budgets/$budgetId');
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return BudgetModel.fromJson(
        decoded,
        category: _resolveCategory(decoded, categoriesById),
        referenceDate: DateTime.now(),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
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
    final payload = BudgetModel(
      id: '',
      category: category,
      limitAmount: limitAmount,
      spentAmount: 0,
      periodType: periodType,
      startDate: startDate,
      endDate: endDate,
      walletIds: walletIds,
      alertPercent: alertPercent,
      repeatMonthly: repeatMonthly,
      budgetName: category.name,
    ).toJson()
      ..remove('budgetId');

    final decoded = await apiClient.post('/budgets', body: payload);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Phản hồi tạo ngân sách từ máy chủ không hợp lệ',
      );
    }
    return BudgetModel.fromJson(
      decoded,
      category: category,
      referenceDate: DateTime.now(),
    );
  }

  @override
  Future<BudgetModel> updateBudget(BudgetEntity budget) async {
    final model = BudgetModel.fromEntity(budget);
    final decoded = await apiClient.put(
      '/budgets/${budget.id}',
      body: model.toJson(),
    );
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Phản hồi cập nhật ngân sách từ máy chủ không hợp lệ',
      );
    }
    return BudgetModel.fromJson(
      decoded,
      category: budget.category,
      referenceDate: DateTime.now(),
    );
  }

  @override
  Future<void> deleteBudget(String budgetId) {
    return apiClient.delete('/budgets/$budgetId');
  }

  Future<Map<String, BudgetCategory>> _ensureCategoryCache() async {
    if (_categoryCache.isNotEmpty) {
      return _categoryCache;
    }
    await fetchCategories();
    return _categoryCache;
  }

  List<Map<String, dynamic>> _asJsonMapList(dynamic decoded) {
    if (decoded is! List) {
      return const [];
    }
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  BudgetCategory _mapCategory(Map<String, dynamic> json) {
    final id = (json['categoryId'] ?? json['id']).toString();
    final name = (json['categoryName'] ?? json['name'] ?? 'Danh mục').toString();
    final visuals = _resolveCategoryVisuals(name);
    return BudgetCategory(
      id: id,
      name: name,
      icon: visuals.$1,
      tone: visuals.$2,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  BudgetWalletOption _mapWallet(Map<String, dynamic> json) {
    return BudgetWalletOption(
      id: (json['walletId'] ?? json['id']).toString(),
      name: (json['walletName'] ?? json['name'] ?? 'Ví').toString(),
      balance: (json['balance'] as num? ?? 0).toDouble(),
      currency: (json['currency'] as String?) ?? 'VND',
    );
  }

  BudgetPeriodFilterOption _mapPeriodFilter(Map<String, dynamic> json) {
    return BudgetPeriodFilterOption(
      id: json['id'].toString(),
      label: json['label'].toString(),
      summaryHeading: json['summaryHeading'].toString(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );
  }

  BudgetCategory _resolveCategory(
    Map<String, dynamic> json,
    Map<String, BudgetCategory> categoriesById,
  ) {
    final rawCategoryId = json['categoryId'];
    if (rawCategoryId != null) {
      final cached = categoriesById[rawCategoryId.toString()];
      if (cached != null) {
        return cached;
      }
    }
    final fallbackName =
        (json['categoryName'] ?? json['budgetName'] ?? 'Khác').toString();
    final visuals = _resolveCategoryVisuals(fallbackName);
    return BudgetCategory(
      id: rawCategoryId?.toString() ?? 'other',
      name: fallbackName,
      icon: visuals.$1,
      tone: visuals.$2,
    );
  }

  (IconData, AppCategoryTone) _resolveCategoryVisuals(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ăn') || lower.contains('uống') || lower.contains('food')) {
      return (Icons.restaurant_rounded, AppCategoryTone.food);
    }
    if (lower.contains('đi lại') ||
        lower.contains('di chuyển') ||
        lower.contains('xăng') ||
        lower.contains('xe')) {
      return (Icons.directions_car_outlined, AppCategoryTone.travel);
    }
    if (lower.contains('mua') || lower.contains('shop')) {
      return (Icons.shopping_bag_outlined, AppCategoryTone.shopping);
    }
    if (lower.contains('nhà') || lower.contains('thuê') || lower.contains('điện')) {
      return (Icons.home_outlined, AppCategoryTone.neutral);
    }
    if (lower.contains('giải trí') || lower.contains('phim') || lower.contains('game')) {
      return (Icons.sports_esports_outlined, AppCategoryTone.food);
    }
    if (lower.contains('sức khỏe') || lower.contains('y tế') || lower.contains('thuốc')) {
      return (Icons.favorite_border_rounded, AppCategoryTone.shopping);
    }
    if (lower.contains('học') || lower.contains('giáo dục')) {
      return (Icons.school_outlined, AppCategoryTone.travel);
    }
    if (lower.contains('hóa đơn') || lower.contains('tiện ích')) {
      return (Icons.receipt_long_outlined, AppCategoryTone.neutral);
    }
    return (Icons.grid_view_rounded, AppCategoryTone.neutral);
  }
}
