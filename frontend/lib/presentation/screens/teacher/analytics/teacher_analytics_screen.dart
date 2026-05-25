import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
// import 'package:scimathix/presentation/screens/teacher/analytics/section_performance_screen.dart';
// import 'package:scimathix/presentation/screens/teacher/analytics/student_monitoring_screen.dart';

class TeacherAnalyticsScreen extends StatelessWidget {
  const TeacherAnalyticsScreen({super.key});

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(),
            const SizedBox(height: 32),
            _buildSectionLabel("Performance Reports"),
            const SizedBox(height: 16),
            _buildReportCard(
              "Section Performance",
              "Comparative analysis of your classes.",
              CupertinoIcons.group,
              AppTheme.primaryColor,
              onTap: () {},
            ),
            _buildReportCard(
              "Student Monitoring",
              "Track individual progress and engagement.",
              CupertinoIcons.person_2,
              AppTheme.secondaryColor,
              onTap: () {},
            ),
            _buildReportCard(
              "Weak Topic Analysis",
              "Identify areas where students struggle most.",
              CupertinoIcons.exclamationmark_triangle,
              AppTheme.accentColor,
              onTap: () {},
            ),
            const SizedBox(height: 32),
            _buildSectionLabel("Leaderboard Status"),
            const SizedBox(height: 16),
            _buildLeaderboardPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                    Text("Overall Performance", style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text("Highly Active", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.chart_bar_square, color: Colors.green, size: 12),
                      const SizedBox(width: 4),
                      Text("+12%", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat("82", "Students"),
                _buildMiniStat("94%", "Pass Rate"),
                _buildMiniStat("1.2h", "Avg. Study"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
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

  Widget _buildReportCard(String title, String subtitle, IconData icon, Color color, {required VoidCallback onTap}) {
    return FadeInUp(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            _buildLeaderItem(1, "Ana Garcia", "2,450 XP", AppTheme.accentColor),
            const Divider(color: AppTheme.borderColor, height: 24),
            _buildLeaderItem(2, "Mark Santos", "2,380 XP", const Color(0xFFC0C0C0)),
            const Divider(color: AppTheme.borderColor, height: 24),
            _buildLeaderItem(3, "Luis Reyes", "1,980 XP", const Color(0xFFCD7F32)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderItem(int rank, String name, String xp, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            "#$rank",
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: color),
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(name[0], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor)),
        ),
        Text(xp, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textColor)),
      ],
    );
  }
}
