import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/core/utils/app_logger.dart';

class TeacherWeakTopicsScreen extends StatefulWidget {
  const TeacherWeakTopicsScreen({super.key});

  @override
  State<TeacherWeakTopicsScreen> createState() =>
      _TeacherWeakTopicsScreenState();
}

class _TeacherWeakTopicsScreenState extends State<TeacherWeakTopicsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _topics = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getTeacherWeakTopics();
      if (mounted) {
        setState(() {
          _topics = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Fetch Weak Topics', e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _scoreColor(int score) {
    if (score >= 60) return AppTheme.accentColor;
    if (score >= 40) return Colors.orange;
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
          "Weak Topics",
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
          : _topics.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _topics.length,
                    itemBuilder: (context, index) {
                      final t = _topics[index] as Map<String, dynamic>;
                      final topic = t['topic'] ?? 'Topic';
                      final avg = (t['averageScore'] ?? 0) as int;
                      final attempts = (t['attempts'] ?? 0);
                      final struggling =
                          (t['strugglingStudents'] as List<dynamic>? ?? []);

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
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _scoreColor(avg)
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "${index + 1}",
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: _scoreColor(avg)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      topic,
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppTheme.textColor),
                                    ),
                                  ),
                                  const Icon(
                                      CupertinoIcons
                                          .exclamationmark_triangle_fill,
                                      color: Colors.redAccent,
                                      size: 18),
                                ],
                              ),
                              const SizedBox(height: 14),
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
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Class avg: $avg%",
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.subtleText,
                                          fontWeight: FontWeight.w600)),
                                  Text("$attempts attempts",
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.subtleText)),
                                ],
                              ),
                              if (struggling.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Divider(
                                    color: AppTheme.borderColor, height: 1),
                                const SizedBox(height: 12),
                                Text(
                                  "Students who struggled (${struggling.length})",
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.subtleText,
                                      letterSpacing: 0.3),
                                ),
                                const SizedBox(height: 10),
                                ...struggling.map((s) {
                                  final sm = s as Map<String, dynamic>;
                                  final name = (sm['name'] ?? 'Student').toString();
                                  final sAvg = (sm['averageScore'] ?? 0) as int;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 13,
                                          backgroundColor: Colors.redAccent
                                              .withValues(alpha: 0.1),
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.redAccent),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.textColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _scoreColor(sAvg)
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text("$sAvg%",
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: _scoreColor(sAvg))),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.checkmark_seal_fill,
              color: Colors.green, size: 48),
          const SizedBox(height: 12),
          Text("No weak topics — your students are doing great!",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.subtleText)),
        ],
      ),
    );
  }
}
