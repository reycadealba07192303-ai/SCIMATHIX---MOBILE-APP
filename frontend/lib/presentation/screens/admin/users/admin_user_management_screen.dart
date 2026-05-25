import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/admin/users/admin_add_user_screen.dart';

class AdminUserManagementScreen extends ConsumerStatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  ConsumerState<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends ConsumerState<AdminUserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _selectedFilter = 'All Users';

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
      print('Fetch Users Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "User Management",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildRoleTabs(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: _users.isEmpty 
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildDataTable(),
                        ),
                      ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(CupertinoIcons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.person_2, size: 64, color: AppTheme.subtleText.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No users found in this category",
            style: GoogleFonts.inter(color: AppTheme.subtleText),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildTab("All Users"),
          _buildTab("Teachers"),
          _buildTab("Students"),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    bool isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        _fetchUsers();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.subtleText,
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.05)),
          dataRowHeight: 65,
          headingTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
            fontSize: 13,
          ),
          columns: const [
            DataColumn(label: Text("Name")),
            DataColumn(label: Text("Email")),
            DataColumn(label: Text("Role")),
            DataColumn(label: Text("Actions")),
          ],
          rows: List.generate(_users.length, (index) {
            final user = _users[index];
            String role = user['role'] ?? 'student';
            bool isTeacher = role.toLowerCase() == "teacher";
            String name = user['name'] ?? "Unknown";
            String email = user['email'] ?? "No email";
            
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isTeacher ? AppTheme.secondaryColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : "?",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: isTeacher ? AppTheme.secondaryColor : AppTheme.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(email, style: GoogleFonts.inter(color: AppTheme.subtleText))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isTeacher ? AppTheme.secondaryColor.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role[0].toUpperCase() + role.substring(1),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTeacher ? AppTheme.secondaryColor : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(CupertinoIcons.ellipsis_vertical, color: AppTheme.subtleText, size: 18),
                    onPressed: () => _showUserOptions(user),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showUserOptions(Map<String, dynamic> user) {
    bool isSuspended = !(user['isActive'] ?? true);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
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
            Text(
              user['name'] ?? "User",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              user['email'] ?? "",
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
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
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete User", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        content: Text("Are you sure you want to delete ${user['name']}? This action cannot be undone.", style: GoogleFonts.inter(color: AppTheme.subtleText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(apiServiceProvider).deleteUser(user['_id']);
              if (success) {
                _fetchUsers();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted permanently.")));
              } else {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete user.")));
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
            const Icon(CupertinoIcons.chevron_right, color: AppTheme.subtleText, size: 16),
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
