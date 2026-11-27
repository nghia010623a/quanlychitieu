import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_state_view.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/budgets/budgets.dart';
import 'di/app_dependencies.dart';

/// Main BottomNavigationBar shell matching `project structure.md`:
/// Tổng quan, Giao dịch, Ngân sách, Nhóm, Cá nhân.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.dependencies,
    this.initialIndex = 2,
    super.key,
  });

  final AppDependencies dependencies;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _ModulePlaceholderPage(
        title: 'Tổng quan',
        subtitle: 'Màn hình Dashboard & Ví sẽ được tích hợp tại đây.',
        icon: Icons.dashboard_outlined,
      ),
      const _ModulePlaceholderPage(
        title: 'Giao dịch',
        subtitle: 'Lịch sử giao dịch và danh mục sẽ được tích hợp tại đây.',
        icon: Icons.receipt_long_outlined,
      ),
      BudgetListPage(
        repository: widget.dependencies.budgetRepository,
        showBackButton: false,
      ),
      const _ModulePlaceholderPage(
        title: 'Nhóm',
        subtitle: 'Quỹ nhóm và bạn bè sẽ được tích hợp tại đây.',
        icon: Icons.group_outlined,
      ),
      const loginWidget(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: const Color(0xFF3699ED),
        unselectedItemColor: AppColors.slate,
        selectedLabelStyle: AppTypography.captionSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTypography.captionSmall,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz_rounded),
            label: 'Giao dịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline_rounded),
            activeIcon: Icon(Icons.pie_chart_rounded),
            label: 'Ngân sách',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Nhóm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

class _ModulePlaceholderPage extends StatelessWidget {
  const _ModulePlaceholderPage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppStateView.empty(
        title: title,
        subtitle: subtitle,
        icon: icon,
      ),
    );
  }
}
