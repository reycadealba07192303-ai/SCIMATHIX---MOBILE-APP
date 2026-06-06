import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/admin/users/admin_add_user_screen.dart';
import 'package:scimathix/core/utils/app_logger.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _selectedFilter = 'All Users';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      List<dynamic> allUsers = [];
      
      if (_selectedFilter == 'Teachers') {
        allUsers = await apiService.getTeachers();
      } else if (_selectedFilter == 'Students') {
        allUsers = await apiService.getStudents();
      } else {
        final teachers = await apiService.getTeachers();
        final students = await apiService.getStudents();
        allUsers = [...teachers, ...students];
      }

      if (mounted) {
        setState(() {
          _users = allUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Fetch Users', e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || email.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildRoleTabs(),
            _buildUserCount(users.length),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : RefreshIndicator(
                    onRefresh: _fetchUsers,
                    color: AppTheme.primaryColor,
                    child: users.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            return FadeInUp(
                              delay: Duration(milliseconds: index < 10 ? index * 60 : 0),
                              child: _buildUserCard(users[index]),
                            );
                          },
                        ),
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(CupertinoIcons.person_add, color: Colors.white, size: 20),
        label: Text("Add User", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Icon(CupertinoIcons.back, color: AppTheme.textColor, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "User Management",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchUsers();
            },
            icon: Icon(CupertinoIcons.arrow_clockwise, color: AppTheme.subtleText, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textColor),
          decoration: InputDecoration(
            hintText: "Search by name or email...",
            hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText),
            prefixIcon: Icon(CupertinoIcons.search, color: AppTheme.subtleText, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          _buildTab("All Users", CupertinoIcons.person_2),
          const SizedBox(width: 8),
          _buildTab("Teachers", CupertinoIcons.briefcase),
          const SizedBox(width: 8),
          _buildTab("Students", CupertinoIcons.book),
        ],
      ),
    );
  }

  Widget _buildTab(String label, IconData icon) {
    bool isActive = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = label);
          _fetchUsers();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : AppTheme.subtleText),
              const SizedBox(width: 6),
              Text(
                label.replaceAll('All ', ''),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppTheme.subtleText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
      child: Row(
        children: [
          Text(
            "$count user${count != 1 ? 's' : ''} found",
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    String role = user['role'] ?? 'student';
    bool isTeacher = role.toLowerCase() == "teacher";
    String name = user['name'] ?? "Unknown";
    String email = user['email'] ?? "No email";
    bool isSuspended = !(user['isActive'] ?? true);
    Color roleColor = isTeacher ? AppTheme.secondaryColor : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSuspended ? Colors.orange.withOpacity(0.3) : AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserOptions(user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withOpacity(0.15),
                        roleColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: roleColor.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSuspended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Suspended",
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.orange),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withOpacity(0.15)),
                  ),
                  child: Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.person_2, size: 48, color: AppTheme.subtleText.withOpacity(0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            "No users found",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textColor),
          ),
          const SizedBox(height: 6),
          Text(
            "Try changing your filter or search query",
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
          ),
        ],
      ),
    );
  }

  void _showUserOptions(Map<String, dynamic> user) {
    bool isSuspended = !(user['isActive'] ?? true);
    String role = user['role'] ?? 'student';
    bool isTeacher = role.toLowerCase() == "teacher";
    Color roleColor = isTeacher ? AppTheme.secondaryColor : AppTheme.primaryColor;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // User info header
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [roleColor.withOpacity(0.15), roleColor.withOpacity(0.05)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user['name'] ?? "?")[0].toUpperCase(),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: roleColor, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? "User",
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user['email'] ?? "",
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActionSheetButton(
              isSuspended ? "Reactivate Account" : "Suspend Account",
              isSuspended ? CupertinoIcons.checkmark_shield : CupertinoIcons.nosign,
              isSuspended ? Colors.green : Colors.orange,
              () async {
                Navigator.pop(context);
                final success = await ref.read(apiServiceProvider).suspendUser(user['_id']);
                if (success) {
                   _fetchUsers();
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isSuspended ? "Account reactivated." : "Account suspended.")));
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update user status.")));
                }
              },
            ),
            _buildActionSheetButton(
              "Delete Account",
              CupertinoIcons.trash,
              Colors.red,
              () {
                Navigator.pop(context);
                _confirmDelete(user);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete User", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        content: Text("Are you sure you want to delete ${user['name']}? This action cannot be undone.", style: GoogleFonts.inter(color: AppTheme.subtleText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final errorMsg = await ref.read(apiServiceProvider).deleteUser(user['_id']);
              if (!mounted) return;
              if (errorMsg == null) {
                _fetchUsers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted permanently.")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSheetButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const Spacer(),
            Icon(CupertinoIcons.chevron_right, color: AppTheme.subtleText, size: 16),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAddUserScreen()),
    ).then((value) {
      if (value == true) _fetchUsers();
    });
  }
}
