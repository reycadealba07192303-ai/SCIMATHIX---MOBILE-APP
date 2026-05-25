import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_academic_structure_screen.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_teacher_management_screen.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_subject_management_screen.dart';
import 'package:scimathix/presentation/screens/admin/notifications/admin_notifications_screen.dart';
import 'package:scimathix/presentation/screens/admin/dashboard/admin_announcements_screen.dart';
import 'package:scimathix/presentation/screens/admin/dashboard/admin_user_logs_screen.dart';
import 'package:scimathix/data/services/socket_service.dart';

class AdminHomeView extends ConsumerStatefulWidget {
  final String name;
  const AdminHomeView({super.key, required this.name});

  @override
  ConsumerState<AdminHomeView> createState() => _AdminHomeViewState();
}

class _AdminHomeViewState extends ConsumerState<AdminHomeView> {
  Map<String, dynamic> _stats = {
    "studentCount": 0,
    "teacherCount": 0,
    "lessonCount": 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _setupSocket();
  }

  void _setupSocket() {
    final socketService = ref.read(socketServiceProvider);
    socketService.initSocket();
    
    socketService.on('new_notification', (data) {
      if (mounted && data['target'] == 'OVERALL' || data['target'] == 'TEACHER ONLY' || data['target'] == 'STUDENT ONLY') { // Simplified check for demo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.bell_fill, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data['title'] ?? 'New Notification', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      Text(data['message'] ?? '', style: GoogleFonts.inter(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    socketService.off('new_notification');
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final stats = await apiService.getAdminStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fetch Stats Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildSystemStats(),
              const SizedBox(height: 32),
              _buildSectionHeader("System Alerts"),
              const SizedBox(height: 16),
              _buildSystemAlerts(),
              const SizedBox(height: 32),
              _buildSectionHeader("Admin Actions"),
              const SizedBox(height: 16),
              _buildAdminActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Admin Portal",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "System health: Optimal",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.bell, color: AppTheme.textColor),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminNotificationsScreen()));
                },
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor, width: 1),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(CupertinoIcons.shield_fill, color: AppTheme.primaryColor, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStats() {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          _buildStatCard(_stats['studentCount'].toString(), "Students", CupertinoIcons.person_2, AppTheme.primaryColor),
          const SizedBox(width: 16),
          _buildStatCard(_stats['teacherCount'].toString(), "Teachers", CupertinoIcons.briefcase, AppTheme.secondaryColor),
          const SizedBox(width: 16),
          _buildStatCard(_stats['lessonCount'].toString(), "Lessons", CupertinoIcons.book, AppTheme.accentColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                  ),
                ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.subtleText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeInUp(
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textColor,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSystemAlerts() {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Column(
        children: [
          _buildAlertTile("Teacher Verification", "3 teachers pending review", CupertinoIcons.checkmark_shield, Colors.orange),
          _buildAlertTile("Database Backup", "Weekly backup completed successfully", CupertinoIcons.cloud_upload, Colors.green),
          _buildAlertTile("High Traffic", "Increased student activity in Algebra", CupertinoIcons.chart_bar_square, AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildAlertTile(String title, String subtitle, IconData icon, Color color) {
    return Container(
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.subtleText,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 14),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 800),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: [
          _buildActionItem("Announcement", CupertinoIcons.speaker_2, AppTheme.primaryColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAnnouncementsScreen()));
          }),
          _buildActionItem("User Logs", CupertinoIcons.list_bullet, AppTheme.secondaryColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUserLogsScreen()));
          }),
          _buildActionItem("Subject List", CupertinoIcons.book, Colors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSubjectManagementScreen()));
          }),
          _buildActionItem("Academic Hub", CupertinoIcons.layers_alt, Colors.deepPurple, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAcademicStructureScreen()));
          }),
          _buildActionItem("Teacher Handles", CupertinoIcons.briefcase, Colors.indigo, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminTeacherManagementScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
