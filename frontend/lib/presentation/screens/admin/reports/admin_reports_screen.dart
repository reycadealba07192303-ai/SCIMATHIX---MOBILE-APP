import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/logic/admin_navigation_provider.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_academic_structure_screen.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_subject_management_screen.dart';
import 'package:scimathix/presentation/screens/admin/reports/admin_generate_report_screen.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_teacher_management_screen.dart';
import 'package:scimathix/presentation/screens/admin/dashboard/admin_announcements_screen.dart';
import 'package:scimathix/presentation/screens/admin/dashboard/admin_user_logs_screen.dart';
import 'package:scimathix/presentation/screens/admin/notifications/admin_notifications_screen.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _reportData = {};
  final List<Map<String, dynamic>> _recentDownloads = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final api = ref.read(apiServiceProvider);
    try {
      final data = await api.getAdminReports();
      
      if (!mounted) return;
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
      return;
    } catch (e) {
      // Fallback: still show overview from public stats endpoint
      try {
        final stats = await api.getAdminStats();
        if (!mounted) return;
        setState(() {
          _reportData = {
            'overview': {
              'studentCount': stats['studentCount'] ?? 0,
              'teacherCount': stats['teacherCount'] ?? 0,
              'lessonCount': stats['lessonCount'] ?? 0,
              'quizCount': 0,
              'sectionCount': 0,
              'subjectCount': 0,
              'pendingTeachers': 0,
            },
            'academicPerformance': {
              'averageScore': 0,
              'passingRate': 0,
              'totalAttempts': 0,
            },
            'userActivity': {
              'labels': <String>[],
              'data': <int>[],
              'totalActions': 0,
            },
            'topSections': <dynamic>[],
            'recentActivity': <dynamic>[],
          };
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> get _overview =>
      (_reportData['overview'] as Map<String, dynamic>?) ?? {};

  void _switchTab(int index) {
    ref.read(adminDashboardTabProvider.notifier).setTab(index);
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return ColoredBox(
      color: AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            if (_isLoading)
              LinearProgressIndicator(
                minHeight: 3,
                color: AppTheme.primaryColor,
                backgroundColor: AppTheme.borderColor,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchReports,
                color: AppTheme.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        _buildErrorCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildYearCard(),
                      const SizedBox(height: 20),
                      _sectionTitle('Platform Overview'),
                      const SizedBox(height: 12),
                      _buildOverviewGrid(width),
                      const SizedBox(height: 24),
                      _sectionTitle('Admin Modules'),
                      const SizedBox(height: 12),
                      _buildModuleChips(),
                      const SizedBox(height: 24),
                      _sectionTitle('Academic Performance'),
                      const SizedBox(height: 12),
                      _buildPerformanceRow(),
                      const SizedBox(height: 24),
                      _sectionTitle('User Activity (Last 7 Days)'),
                      const SizedBox(height: 12),
                      _buildActivityCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Quiz & Assessment — Top Sections'),
                      const SizedBox(height: 12),
                      _buildTopSectionsCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Recent System Activity'),
                      const SizedBox(height: 12),
                      _buildActivityListCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('Recent Downloads'),
                      const SizedBox(height: 12),
                      _buildDownloadsCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              'Reports & Analytics',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _fetchReports,
            icon: Icon(CupertinoIcons.arrow_clockwise, color: AppTheme.textColor),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textColor,
      ),
    );
  }

  Widget _buildErrorCard() {
    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(CupertinoIcons.wifi_exclamationmark, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade900),
              ),
            ),
            TextButton(onPressed: _fetchReports, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildYearCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'System Activity Report',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Generate a detailed PDF report of all user activities in the system, filterable by academic year, grade level, and section.',
            style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                final logs = (_reportData['recentActivity'] as List?) ?? [];
                _push(AdminGenerateReportScreen(logs: logs));
              },
              icon: const Icon(CupertinoIcons.arrow_right_circle_fill, size: 20),
              label: Text('Generate Report', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(double screenWidth) {
    final tileWidth = (screenWidth - 40 - 20) / 3;
    final items = <_TileData>[
      _TileData('Students', '${_overview['studentCount'] ?? 0}', CupertinoIcons.person_2_fill, AppTheme.primaryColor, () => _switchTab(1)),
      _TileData('Teachers', '${_overview['teacherCount'] ?? 0}', CupertinoIcons.briefcase_fill, AppTheme.secondaryColor, () => _switchTab(1)),
      _TileData('Lessons', '${_overview['lessonCount'] ?? 0}', CupertinoIcons.book_fill, const Color(0xFFD3AF37), () => _push(const AdminSubjectManagementScreen())),
      _TileData('Quizzes', '${_overview['quizCount'] ?? 0}', CupertinoIcons.question_circle_fill, const Color(0xFFFF6B6B), null),
      _TileData('Sections', '${_overview['sectionCount'] ?? 0}', CupertinoIcons.square_stack_3d_up_fill, Colors.deepPurple, () => _push(const AdminAcademicStructureScreen())),
      _TileData('Subjects', '${_overview['subjectCount'] ?? 0}', CupertinoIcons.book_fill, Colors.orange, () => _push(const AdminSubjectManagementScreen())),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return SizedBox(
          width: tileWidth,
          child: Material(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(item.icon, color: item.color, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      item.value,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor),
                    ),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(fontSize: 10, color: AppTheme.subtleText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModuleChips() {
    final modules = [
      ('Overview', CupertinoIcons.chart_pie_fill, () => _switchTab(0)),
      ('Users', CupertinoIcons.person_2_fill, () => _switchTab(1)),
      ('Academic', CupertinoIcons.layers_alt_fill, () => _push(const AdminAcademicStructureScreen())),
      ('Teachers', CupertinoIcons.briefcase_fill, () => _push(const AdminTeacherManagementScreen())),
      ('Subjects', CupertinoIcons.book_fill, () => _push(const AdminSubjectManagementScreen())),
      ('Announce', CupertinoIcons.speaker_2_fill, () => _push(const AdminAnnouncementsScreen())),
      ('Notify', CupertinoIcons.bell_fill, () => _push(const AdminNotificationsScreen())),
      ('Logs', CupertinoIcons.list_bullet, () => _push(const AdminUserLogsScreen())),
      ('Profile', CupertinoIcons.person_fill, () => _switchTab(3)),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final m = modules[i];
          return ActionChip(
            label: Text(m.$1, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            avatar: Icon(m.$2, size: 16, color: AppTheme.primaryColor),
            onPressed: m.$3,
            backgroundColor: AppTheme.surfaceColor,
            side: BorderSide(color: AppTheme.borderColor),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceRow() {
    final perf = _reportData['academicPerformance'] as Map<String, dynamic>? ?? {};
    return Row(
      children: [
        Expanded(child: _metricCard('Avg Score', '${perf['averageScore'] ?? 0}%', const Color(0xFF6C63FF))),
        const SizedBox(width: 10),
        Expanded(child: _metricCard('Pass Rate', '${perf['passingRate'] ?? 0}%', const Color(0xFF00C896))),
        const SizedBox(width: 10),
        Expanded(child: _metricCard('Attempts', '${perf['totalAttempts'] ?? 0}', const Color(0xFFFF6B6B))),
      ],
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.chart_bar_fill, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.subtleText)),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    final activity = _reportData['userActivity'] as Map<String, dynamic>? ?? {};
    final labels = (activity['labels'] as List?)?.cast<String>() ?? [];
    final data = (activity['data'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final total = activity['totalActions'] ?? 0;
    final maxVal = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity trend', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              Text('$total actions', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryColor)),
            ],
          ),
          TextButton(
            onPressed: () => _push(const AdminUserLogsScreen()),
            child: const Text('View all logs'),
          ),
          SizedBox(
            height: 130,
            child: labels.isEmpty
                ? Center(child: Text('No activity yet', style: GoogleFonts.inter(color: AppTheme.subtleText)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(labels.length, (i) {
                      final h = maxVal > 0 ? (data[i] / maxVal) * 80 : 0.0;
                      return Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${data[i].toInt()}', style: const TextStyle(fontSize: 9)),
                            const SizedBox(height: 2),
                            Container(
                              height: h < 4 && data[i] > 0 ? 4 : h,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              labels[i],
                              style: const TextStyle(fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSectionsCard() {
    final sections = (_reportData['topSections'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: sections.isEmpty
          ? Text(
              'No quiz data yet. Results appear when students take quizzes.',
              style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13),
            )
          : Column(
              children: List.generate(sections.length, (i) {
                final s = sections[i] as Map<String, dynamic>;
                final avg = (s['average'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Text('#${i + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s['name']?.toString() ?? 'Section')),
                      Text('$avg%', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _buildActivityListCard() {
    final logs = (_reportData['recentActivity'] as List?) ?? [];
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          'No system activity yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppTheme.subtleText),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: logs.take(8).map((raw) {
          final log = raw as Map<String, dynamic>;
          return ListTile(
            dense: true,
            title: Text(log['action']?.toString() ?? 'Activity', style: GoogleFonts.inter(fontSize: 13)),
            subtitle: Text('${log['user']} · ${log['role']}', style: GoogleFonts.inter(fontSize: 11)),
            onTap: () => _push(const AdminUserLogsScreen()),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDownloadsCard() {
    if (_recentDownloads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          'No PDF downloads yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppTheme.subtleText),
        ),
      );
    }

    return Column(
      children: _recentDownloads.map((d) {
        return ListTile(
          leading: const Icon(CupertinoIcons.doc_fill, color: Colors.red),
          title: Text(d['name']?.toString() ?? 'Report'),
          subtitle: Text(d['date']?.toString() ?? ''),
        );
      }).toList(),
    );
  }


}

class _TileData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  _TileData(this.label, this.value, this.icon, this.color, this.onTap);
}
