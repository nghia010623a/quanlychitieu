import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_ng/core/network/api_client.dart';
import 'package:flutter_ng/core/storage/auth_session.dart';
import 'package:flutter_ng/features/budgets/budgets.dart';

void main() {
  tearDown(() {
    AuthSession.instance.clear();
  });

  test('HttpBudgetRemoteDataSource maps categories, wallets, periods, budgets, and CRUD', () async {
    AuthSession.instance.setUserId(7);

    final recordedRequests = <http.Request>[];
    final mockClient = MockClient((request) async {
      recordedRequests.add(request);
      final path = request.url.path;

      if (request.method == 'GET' && path == '/api/categories') {
        return http.Response(
          jsonEncode([
            {
              'categoryId': 5,
              'categoryName': 'Ăn uống',
              'categoryType': 'EXPENSE',
              'isDefault': true,
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'GET' && path == '/api/wallets') {
        return http.Response(
          jsonEncode([
            {
              'walletId': 2,
              'walletName': 'Ví tiền mặt',
              'balance': 1200000,
              'currency': 'VND',
              'walletType': 'PERSONAL',
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'GET' && path == '/api/budgets/periods') {
        return http.Response(
          jsonEncode([
            {
              'id': '2026-11',
              'label': 'Tháng 11/2026',
              'summaryHeading': 'Tổng chi tháng 11',
              'startDate': '2026-11-01',
              'endDate': '2026-11-30',
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'GET' && path == '/api/budgets') {
        return http.Response(
          jsonEncode([
            {
              'budgetId': 10,
              'walletId': 2,
              'walletIds': [2],
              'categoryId': 5,
              'categoryName': 'Ăn uống',
              'budgetName': 'Ăn uống',
              'amount': 3000000,
              'spentAmount': 1800000,
              'period': 'MONTH',
              'startDate': '2026-11-01',
              'endDate': '2026-11-30',
              'alertPercent': 80,
              'status': 'ACTIVE',
              'repeatMonthly': true,
              'transactions': [
                {
                  'transactionId': 101,
                  'title': 'Bún chả Hương Liên',
                  'walletId': 2,
                  'walletName': 'Ví tiền mặt',
                  'transactionTime': '2026-11-15T12:30:00',
                  'amount': -85000,
                },
              ],
            },
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'GET' && path == '/api/budgets/999') {
        return http.Response(
          jsonEncode({'status': 404, 'message': 'Không tìm thấy ngân sách'}),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'POST' && path == '/api/budgets') {
        final sent = jsonDecode(request.body) as Map<String, dynamic>;
        expect(sent.containsKey('budgetId'), isFalse);
        expect(sent['categoryId'], '5');
        expect(sent['amount'], 2000000);
        return http.Response(
          jsonEncode({
            'budgetId': 12,
            'walletId': 2,
            'walletIds': [2],
            'categoryId': 5,
            'categoryName': 'Ăn uống',
            'budgetName': 'Ăn uống',
            'amount': 2000000,
            'spentAmount': 0,
            'period': 'MONTH',
            'startDate': '2026-11-01',
            'endDate': '2026-11-30',
            'alertPercent': 80,
            'status': 'ACTIVE',
            'repeatMonthly': true,
            'transactions': [],
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'PUT' && path == '/api/budgets/12') {
        return http.Response(
          jsonEncode({
            'budgetId': 12,
            'walletId': 2,
            'walletIds': [2],
            'categoryId': 5,
            'categoryName': 'Ăn uống',
            'budgetName': 'Ăn uống',
            'amount': 2500000,
            'spentAmount': 0,
            'period': 'MONTH',
            'startDate': '2026-11-01',
            'endDate': '2026-11-30',
            'alertPercent': 90,
            'status': 'ACTIVE',
            'repeatMonthly': true,
            'transactions': [],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      if (request.method == 'DELETE' && path == '/api/budgets/12') {
        return http.Response('', 204);
      }

      return http.Response('Not found', 404);
    });

    final apiClient = ApiClient(
      client: mockClient,
      baseUrl: 'http://localhost:8080/api',
    );
    final dataSource = HttpBudgetRemoteDataSource(apiClient: apiClient);

    final categories = await dataSource.fetchCategories();
    expect(categories, hasLength(1));
    expect(categories.first.id, '5');
    expect(categories.first.name, 'Ăn uống');

    final wallets = await dataSource.fetchWallets();
    expect(wallets, hasLength(1));
    expect(wallets.first.id, '2');

    final periods = await dataSource.fetchPeriodFilters();
    expect(periods.first.id, '2026-11');

    final budgets = await dataSource.fetchBudgets(
      periodFilterId: '2026-11',
      walletId: '2',
    );
    expect(budgets, hasLength(1));
    expect(budgets.first.id, '10');
    expect(budgets.first.spentAmount, 1800000);
    expect(budgets.first.transactions.first.title, 'Bún chả Hương Liên');
    expect(budgets.first.transactions.first.amount, -85000);

    final missing = await dataSource.fetchBudgetById('999');
    expect(missing, isNull);

    final created = await dataSource.createBudget(
      category: categories.first,
      limitAmount: 2000000,
      periodType: BudgetPeriodType.month,
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
      walletIds: const ['2'],
      alertPercent: 80,
      repeatMonthly: true,
    );
    expect(created.id, '12');

    final updated = await dataSource.updateBudget(
      created.copyWith(limitAmount: 2500000, alertPercent: 90),
    );
    expect(updated.limitAmount, 2500000);
    expect(updated.alertPercent, 90);

    await dataSource.deleteBudget('12');

    for (final req in recordedRequests) {
      expect(req.headers['X-User-Id'], '7');
    }
  });

  test('ApiClient surfaces backend error message cleanly', () async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'status': 400,
          'error': 'Bad Request',
          'message': 'Hạn mức ngân sách phải lớn hơn 0',
        }),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final apiClient = ApiClient(
      client: mockClient,
      baseUrl: 'http://localhost:8080/api',
    );

    expect(
      () => apiClient.post('/budgets', body: {'amount': 0}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.message,
              'message',
              'Hạn mức ngân sách phải lớn hơn 0',
            ),
      ),
    );
  });
}
