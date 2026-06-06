import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/core/utils/app_logger.dart';

class TeacherMonitoringScreen extends StatefulWidget {
  const TeacherMonitoringScreen({super.key});

  @override
  State<TeacherMonitoringScreen> createState() =>
      _TeacherMonitoringScreenState();
}

class _TeacherMonitoringScreenState extends State<TeacherMonitoringScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getTeacherMonitoring();
      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Fetch Monitoring', e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'Never';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return "${d.month}/${d.day}/${d.year}";
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completion =
        (_data['completion'] ?? const {}) as Map<String, dynamic>;
    final recent = (_data['recentActivity'] ?? const []) as List<dynamic>;
    final inactive =
        (_data['inactiveStudents'] ?? const []) as List<dynamic>;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textColor),
        title: Text(
          "Monitoring",
          style: GoogleFonts.inter(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildCompletionCard(completion),
                  const SizedBox(height: 28),
                  _sectionLabel("Recent Activity"),
                  const SizedBox(height: 12),
                  if (recent.isEmpty)
                    _emptyTile("No recent activity in the last 7 days.")
                  else
                    ...recent.map((r) => _buildActivityTile(
                        r as Map<String, dynamic>)),
                  const SizedBox(height: 28),
                  _sectionLabel("Inactive Students"),
                  const SizedBox(height: 12),
                  if (inactive.isEmpty)
                    _emptyTile("All students are active. ")
                  else
                    ...inactive.map((s) => _buildInactiveTile(
                        s as Map<String, dynamic>)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildCompletionCard(Map<String, dynamic> c) {
    final total = c['totalStudents'] ?? 0;
    final active = c['activeStudents'] ?? 0;
    final inactiveCount = c['inactiveCount'] ?? 0;
    final rate = (c['completionRate'] ?? 0) as int;

    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF16A085)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Active Rate",
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text("$rate%",
                        style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.person_3_fill,
                      color: Colors.white, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _whiteStat("$total", "Total"),
                  Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.2)),
                  _whiteStat("$active", "Active"),
                  Container(
                      width: 1,
                      height: 28,
                      color: Colors.white.withValues(alpha: 0.2)),
                  _whiteStat("$inactiveCount", "Inactive"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whiteStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
            letterSpacing: -0.5));
  }

  Widget _buildActivityTile(Map<String, dynamic> r) {
    final name = r['studentName'] ?? 'Student';
    final quiz = r['quizTitle'] ?? 'Quiz';
    final score = r['score'] ?? 0;
    final total = r['totalQuestions'] ?? 0;
    final date = _formatDate(r['date']);

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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(name.toString().isNotEmpty ? name[0] : 'S',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textColor)),
                const SizedBox(height: 2),
                Text("$quiz • $date",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.subtleText)),
              ],
            ),
          ),
          Text("$score/$total",
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildInactiveTile(Map<String, dynamic> s) {
    final name = s['studentName'] ?? 'Student';
    final section = s['section'] ?? '';
    final last = _formatDate(s['lastActive']);

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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.person_badge_minus,
                color: Colors.redAccent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textColor)),
                const SizedBox(height: 2),
                Text(
                    section.toString().isNotEmpty
                        ? "$section • Last active: $last"
                        : "Last active: $last",
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.subtleText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyTile(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Text(message,
            style: GoogleFonts.inter(color: AppTheme.subtleText)),
      ),
    );
  }
}
