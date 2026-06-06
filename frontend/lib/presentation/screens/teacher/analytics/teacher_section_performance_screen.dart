import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/core/utils/app_logger.dart';

class TeacherSectionPerformanceScreen extends StatefulWidget {
  const TeacherSectionPerformanceScreen({super.key});

  @override
  State<TeacherSectionPerformanceScreen> createState() =>
      _TeacherSectionPerformanceScreenState();
}

class _TeacherSectionPerformanceScreenState
    extends State<TeacherSectionPerformanceScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _sections = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getTeacherSectionPerformance();
      if (mounted) {
        setState(() {
          _sections = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Fetch Section Performance', e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return AppTheme.accentColor;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textColor),
        title: Text(
          "Section Performance",
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
          : _sections.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final s = _sections[index] as Map<String, dynamic>;
                      final name = s['name'] ?? 'Section';
                      final avg = (s['averageScore'] ?? 0) as int;
                      final pass = (s['passRate'] ?? 0) as int;
                      final quizzes = (s['quizCount'] ?? 0);
                      final attempts = (s['attempts'] ?? 0);

                      return FadeInUp(
                        delay: Duration(milliseconds: index * 80),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        CupertinoIcons.group_solid,
                                        color: AppTheme.primaryColor,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppTheme.textColor),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _scoreColor(avg)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "$avg% avg",
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: _scoreColor(avg)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (avg / 100).clamp(0.0, 1.0),
                                  backgroundColor: AppTheme.borderColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _scoreColor(avg)),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _miniStat("Pass Rate", "$pass%"),
                                  _miniStat("Quizzes", "$quizzes"),
                                  _miniStat("Attempts", "$attempts"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textColor)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppTheme.subtleText)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.chart_bar_alt_fill,
              color: AppTheme.subtleText, size: 48),
          const SizedBox(height: 12),
          Text("No section performance data yet.",
              style: GoogleFonts.inter(color: AppTheme.subtleText)),
        ],
      ),
    );
  }
}
