import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ng/app/app.dart';
import 'package:flutter_ng/app/di/app_dependencies.dart';

void main() {
  testWidgets('UI-08 budget list, detail, progress, create, and delete flow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 912);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final dependencies = AppDependencies.mock();
    await tester.pumpWidget(
      KeepooApp(
        dependencies: dependencies,
        useDevicePreview: false,
      ),
    );
    await tester.pumpAndSettle();

    // UI-08.1 List view renders seeded budgets and totals matching Figma.
    expect(find.text('Ngân sách'), findsWidgets);
    expect(find.text('5.350.000 ₫'), findsOneWidget);
    expect(find.text('4 ngân sách'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('Đi lại'), findsOneWidget);
    expect(find.text('Mua sắm'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nhà ở'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nhà ở'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ăn uống'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    // Navigate to UI-08.5 Detail view for Ăn uống.
    await tester.tap(find.text('Ăn uống'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết ngân sách'), findsOneWidget);
    expect(find.text('Trong hạn mức'), findsOneWidget);
    expect(find.text('1.200.000 ₫'), findsOneWidget);
    expect(find.text('Bún chả Hương Liên'), findsOneWidget);

    // Navigate to UI-08.6 Spending progress and toggle tabs.
    await tester.tap(find.text('Tiến độ chi tiêu'));
    await tester.pumpAndSettle();
    expect(find.text('Mốc cảnh báo'), findsOneWidget);
    expect(find.text('Tích lũy'), findsOneWidget);
    await tester.tap(find.text('Theo ngày'));
    await tester.pumpAndSettle();
    expect(find.text('Chi trong ngày'), findsOneWidget);

    // Back to Detail -> open UI-08.7 Edit -> delete with UI-08.8 dialog.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa ngân sách'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa ngân sách'), findsOneWidget);

    await tester.tap(find.text('Xóa ngân sách'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa ngân sách Ăn uống?'), findsOneWidget);
    await tester.tap(find.text('Giữ lại'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa ngân sách'), findsOneWidget);

    // Back to List -> open UI-08.2 Create -> UI-08.3 Period -> UI-08.4 Wallet -> UI-08.9 Created dialog.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ Tạo ngân sách'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo ngân sách'), findsWidgets);

    // Open UI-08.3 Period sheet.
    await tester.scrollUntilVisible(
      find.text('Thời gian áp dụng'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Thời gian áp dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn kỳ ngân sách'), findsOneWidget);
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    // Open UI-08.4 Wallet sheet.
    await tester.scrollUntilVisible(
      find.text('Áp dụng cho 3 ví'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Áp dụng cho 3 ví'));
    await tester.pumpAndSettle();
    expect(find.text('Ví tiền mặt'), findsOneWidget);
    await tester.tap(find.text('Xác nhận (3 ví)'));
    await tester.pumpAndSettle();

    // Enter limit amount and submit.
    await tester.scrollUntilVisible(
      find.byType(TextField),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '2000000');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo ngân sách').last);
    await tester.pumpAndSettle();

    // UI-08.9 confirmation dialog.
    expect(find.text('Đã tạo ngân sách'), findsOneWidget);
    await tester.tap(find.text('Xem ngân sách'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết ngân sách'), findsOneWidget);
  });

  testWidgets('UI-08.1 empty state displays quick category suggestions', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 912);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      KeepooApp(
        dependencies: AppDependencies.mock(),
        useDevicePreview: false,
      ),
    );
    await tester.pumpAndSettle();

    // Switch to December 2026 which has no seeded budgets.
    await tester.tap(find.text('Tháng 11/2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tháng 12/2026'));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có ngân sách nào'), findsOneWidget);
    expect(find.text('+ Tạo ngân sách đầu tiên'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
  });
}
