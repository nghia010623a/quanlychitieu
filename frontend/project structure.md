lib/
├── main.dart
├── app/                                 # Khởi tạo ứng dụng, điều hướng, DI
│   ├── app.dart                         # MaterialApp, Theme, Route khởi đầu
│   ├── app_shell.dart                   # BottomNavigationBar (Tổng quan, Giao dịch, Ngân sách, Nhóm, Cá nhân)
│   ├── di/
│   │   └── app_dependencies.dart        # Khởi tạo & inject các Repository, ApiClient, AuthSession
│   └── router/
│       └── app_routes.dart              # Định nghĩa tên các route màn hình
│
├── core/                                # Tài nguyên dùng chung toàn dự án
│   ├── config/
│   │   └── app_config.dart              # Base URL của backend Java Spring Boot, timeout
│   ├── network/
│   │   └── api_client.dart              # HTTP/Dio client tự động gắn JWT Bearer Token & xử lý refresh token
│   ├── storage/
│   │   └── auth_session.dart            # Lưu trữ access_token, refresh_token, user_id (SharedPreferences/SecureStorage)
│   ├── theme/
│   │   ├── app_design_tokens.dart       # Bảng màu, bo góc, khoảng cách theo Figma Keepoo
│   │   └── app_theme.dart               # ThemeData sáng/tối, định dạng chữ
│   ├── utils/
│   │   ├── app_date_time.dart           # Format ngày/giờ hiển thị giao dịch, ngân sách
│   │   └── currency_formatter.dart      # Định dạng tiền tệ (VND, USD)
│   └── widgets/                         # Các widget tái sử dụng
│       ├── app_avatar.dart
│       ├── app_back_button.dart
│       ├── app_page_bar.dart
│       ├── app_state_view.dart          # Màn hình Loading, Empty, Error chuẩn
│       └── otp_code_input.dart
│
└── features/                            # Chia theo 5 nhóm chức năng tương ứng 5 thành viên
├── auth/                            # [Thành viên 1: Nguyễn Đức Nghĩa] Tài khoản & Đăng nhập
│   ├── auth.dart                    # Barrel file export các màn hình/service của auth
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── auth_remote_data_source.dart
│   │   │   └── google_sign_in_data_source.dart
│   │   ├── models/                  # UserModel, AuthTokenModel (map với bảng users, user_sessions)
│   │   └── repositories/
│   │       └── auth_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   │   └── auth_repository.dart
│   │   └── usecases/
│   └── presentation/
│       ├── pages/
│       │   ├── welcome_page.dart
│       │   ├── login_page.dart
│       │   ├── registration_page.dart
│       │   ├── password_reset_page.dart
│       │   └── profile_page.dart    # Hồ sơ cá nhân, đổi mật khẩu, liên kết ngân hàng
│       └── widgets/
│
├── wallets/                         # [Thành viên 2: Nguyễn Thị Duyên] Tổng quan (Dashboard) & Ví
│   ├── wallets.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   └── wallet_remote_data_source.dart
│   │   ├── models/                  # WalletModel, BankAccountModel (bảng wallets, bank_accounts)
│   │   └── repositories/
│   │       └── wallet_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   │       └── wallet_repository.dart
│   └── presentation/
│       ├── pages/
│       │   ├── dashboard_page.dart  # Màn hình Tổng quan số dư, biểu đồ thu chi
│       │   ├── wallet_list_page.dart
│       │   ├── wallet_detail_page.dart
│       │   └── wallet_form_page.dart # Tạo / Sửa ví cá nhân
│       └── widgets/
│
├── transactions/                    # [Thành viên 3: Lê Phương Thảo] Giao dịch & Danh mục
│   ├── transactions.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   └── transaction_remote_data_source.dart
│   │   ├── models/                  # TransactionModel, CategoryModel (bảng transactions, categories)
│   │   └── repositories/
│   │       └── transaction_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   │       └── transaction_repository.dart
│   └── presentation/
│       ├── pages/
│       │   ├── transaction_list_page.dart   # Lịch sử giao dịch + bộ lọc
│       │   ├── transaction_detail_page.dart
│       │   └── category_manage_page.dart    # Quản lý danh mục thu/chi
│       └── widgets/
│           └── add_transaction_sheet.dart   # Bảng trượt thêm/sửa giao dịch nhanh (UI-03)
│
├── budgets/                         # [Thành viên 4: Quản Trí Đức] Ngân sách & Nhắc nhở
│   ├── budgets.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   └── budget_remote_data_source.dart
│   │   ├── models/                  # BudgetModel, ReminderModel (bảng budgets, reminders)
│   │   └── repositories/
│   │       └── budget_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   │       └── budget_repository.dart
│   └── presentation/
│       ├── pages/
│       │   ├── budget_list_page.dart        # Danh sách & thanh tiến độ cảnh báo 80%/100%
│       │   ├── budget_detail_page.dart
│       │   └── budget_form_page.dart        # Tạo/sửa ngân sách, chọn kỳ & ví
│       └── widgets/
│
├── groups/                          # [Thành viên 5: Nguyễn Quốc Việt] Quỹ nhóm & Kết bạn
│   ├── groups.dart
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── group_remote_data_source.dart
│   │   │   └── friend_remote_data_source.dart
│   │   ├── models/                  # FinanceGroupModel, GroupMemberModel, FriendRequestModel
│   │   └── repositories/
│   │       ├── group_repository_impl.dart
│   │       └── friend_repository_impl.dart
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   │       ├── group_repository.dart
│   │       └── friend_repository.dart
│   └── presentation/
│       ├── pages/
│       │   ├── group_list_page.dart         # Danh sách ví nhóm
│       │   ├── group_detail_page.dart       # Chi tiết quỹ, lịch sử đóng góp, thêm tiền/chi nhóm
│       │   ├── group_form_page.dart         # Tạo quỹ nhóm & phân quyền thành viên
│       │   └── friends_page.dart            # Tìm bạn, gửi/xử lý lời mời kết bạn, chuyển tiền P2P
│       └── widgets/
│
└── notifications/                   # Dùng chung / Tích hợp thông báo biến động số dư & nhắc nhở
    ├── notifications.dart
    ├── data/
    ├── domain/
    └── presentation/
        └── pages/
            └── notifications_page.dart