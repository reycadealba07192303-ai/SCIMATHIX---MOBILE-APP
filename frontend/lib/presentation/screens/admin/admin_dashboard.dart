import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/logic/theme_provider.dart';
import 'package:scimathix/logic/admin_navigation_provider.dart';
import 'package:scimathix/presentation/screens/admin/dashboard/admin_home_view.dart';
import 'package:scimathix/presentation/screens/admin/users/admin_user_management_screen.dart';
import 'package:scimathix/presentation/screens/admin/reports/admin_reports_screen.dart';
import 'package:scimathix/presentation/screens/admin/profile/admin_profile_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // Force rebuild on theme change
    final user = ref.watch(authProvider).user;
    final currentIndex = ref.watch(adminDashboardTabProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildTabBody(currentIndex, user?.name ?? 'Admin'),
      bottomNavigationBar: _buildBottomNavigationBar(currentIndex),
    );
  }

  Widget _buildTabBody(int index, String adminName) {
    switch (index) {
      case 1:
        return AdminUserManagementScreen();
      case 2:
        return AdminReportsScreen();
      case 3:
        return AdminProfileScreen();
      case 0:
      default:
        return AdminHomeView(name: adminName);
    }
  }

  Widget _buildBottomNavigationBar(int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(adminDashboardTabProvider.notifier).setTab(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.subtleText,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_pie),
            activeIcon: Icon(CupertinoIcons.chart_pie_fill),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_2),
            activeIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_chart),
            activeIcon: Icon(CupertinoIcons.doc_chart_fill),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            activeIcon: Icon(CupertinoIcons.person_fill),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
