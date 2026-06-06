import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class TeacherQuizResultsScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String quizTitle;

  const TeacherQuizResultsScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  ConsumerState<TeacherQuizResultsScreen> createState() => _TeacherQuizResultsScreenState();
}

class _TeacherQuizResultsScreenState extends ConsumerState<TeacherQuizResultsScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _submissions = [];
  Map<String, dynamic>? _quizDetails;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.getQuizSubmissions(widget.quizId);
      
      if (mounted) {
        if (result != null) {
          setState(() {
            _quizDetails = result['quiz'];
            _submissions = result['submissions'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = "Failed to fetch submissions.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return "${m}m ${s}s";
    return "${s}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Submissions",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: GoogleFonts.inter(color: Colors.redAccent)),
      );
    }

    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Icon(CupertinoIcons.doc_text_search, size: 48, color: AppTheme.subtleText.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text("No Submissions Yet", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textColor)),
            const SizedBox(height: 8),
            Text("Students haven't taken this quiz.", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _submissions.length,
      itemBuilder: (context, index) {
        final sub = _submissions[index];
        final student = sub['student'] ?? {};
        final name = student['name'] ?? 'Unknown Student';
        final score = sub['score'] ?? 0;
        final total = sub['totalQuestions'] ?? 0;
        final timeTaken = sub['timeTaken'] ?? 0;
        final passingScoreThreshold = _quizDetails?['passingScore'] ?? 0;
        final isPassing = score >= passingScoreThreshold;

        return FadeInUp(
          delay: Duration(milliseconds: 50 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPassing ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textColor)),
                      const SizedBox(height: 4),
                      Text("Time: ${_formatTime(timeTaken)}", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$score / $total",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: isPassing ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPassing ? "PASSED" : "FAILED",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isPassing ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
