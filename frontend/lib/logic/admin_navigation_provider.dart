import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom nav index for [AdminDashboard]: 0 Overview, 1 Users, 2 Reports, 3 Profile.
class AdminDashboardTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final adminDashboardTabProvider =
    NotifierProvider<AdminDashboardTabNotifier, int>(AdminDashboardTabNotifier.new);
