import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/core/utils/app_logger.dart';
import 'package:scimathix/presentation/screens/teacher/analytics/teacher_section_performance_screen.dart';
import 'package:scimathix/presentation/screens/teacher/analytics/teacher_weak_topics_screen.dart';
import 'package:scimathix/presentation/screens/teacher/analytics/teacher_monitoring_screen.dart';
import 'package:scimathix/presentation/screens/teacher/analytics/teacher_leaderboard_screen.dart';

class TeacherAnalyticsScreen extends StatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  State<TeacherAnalyticsScreen> createState() => _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends State<TeacherAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reports;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final reports = await _api.getTeacherReports();
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Fetch Teacher Reports', e);
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
          "Analytics & Insights",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh, color: AppTheme.textColor),
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchReports,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewDashboard(),
                    const SizedBox(height: 32),
                    _buildSectionLabel("Quick Reports"),
                    const SizedBox(height: 16),
                    _buildQuickReportsGrid(),
                    const SizedBox(height: 32),
                    _buildSectionLabel("Top Performing Students"),
                    const SizedBox(height: 16),
                    _buildLeaderboardList(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewDashboard() {
    final overview = _reports?['overview'] ?? {};
    final students = overview['studentCount'] ?? 0;
    final avgScore = overview['averageScore'] ?? 0;
    final passRate = overview['passingRate'] ?? 0;

    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3498DB).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Overall Status", style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(passRate > 75 ? "Excellent" : "Needs Review", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.chart_pie_fill, color: Colors.white, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWhiteMiniStat("$students", "Students"),
                  Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                  _buildWhiteMiniStat("$avgScore%", "Avg Score"),
                  Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                  _buildWhiteMiniStat("$passRate%", "Pass Rate"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return FadeInUp(
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textColor,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildQuickReportsGrid() {
    return FadeInUp(
      child: Row(
        children: [
          Expanded(
            child: _buildSquareReportCard(
              "Section Perf.",
              CupertinoIcons.chart_bar_alt_fill,
              AppTheme.primaryColor,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const TeacherSectionPerformanceScreen()),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSquareReportCard(
              "Weak Topics",
              CupertinoIcons.exclamationmark_triangle_fill,
              AppTheme.accentColor,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TeacherWeakTopicsScreen()),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSquareReportCard(
              "Monitoring",
              CupertinoIcons.person_3_fill,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TeacherMonitoringScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareReportCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textColor),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList() {
    final List<dynamic> students = _reports?['topStudents'] ?? [];
    
    if (students.isEmpty) {
      return FadeInUp(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Center(
            child: Text("No student data available yet.", style: GoogleFonts.inter(color: AppTheme.subtleText)),
          ),
        ),
      );
    }

    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            ...List.generate(students.length, (index) {
              final student = students[index];
              final name = student['name'] ?? 'Unknown';
              final xp = student['xp'] ?? 0;
              return _buildLeaderItem(
                index + 1, 
                name, 
                "$xp XP", 
                index == 0 ? AppTheme.accentColor : (index == 1 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32))
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLeaderboardScreen())),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("View Full Leaderboard", style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderItem(int rank, String name, String xp, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: rank < 3 ? Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              "$rank",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: color),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0] : 'S', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor)),
          ),
          Text(xp, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
