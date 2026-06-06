import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/ai/ai_chat_screen.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_instructions_screen.dart';

class LessonViewerScreen extends ConsumerStatefulWidget {
  final String lessonTitle;
  final String? lessonId;
  final String? content;
  final String? summary;
  final List<dynamic>? objectives;

  const LessonViewerScreen({
    super.key,
    required this.lessonTitle,
    this.lessonId,
    this.content,
    this.summary,
    this.objectives,
  });

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;
  bool _showSummary = true;

  bool get _hasFailedAiSummary {
    final summary = widget.summary?.trim().toLowerCase() ?? '';
    return summary.isEmpty || summary.contains('analysis failed');
  }

  String get _displaySummary {
    if (!_hasFailedAiSummary) return widget.summary!.trim();

    final content = widget.content?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (content.isEmpty) return '';
    return content.length > 450 ? '${content.substring(0, 450)}...' : content;
  }

  List<dynamic> get _displayObjectives {
    final objectives = widget.objectives ?? [];
    final hasFallbackObjective = objectives.length == 1 &&
        objectives.first.toString().toLowerCase().contains('review the uploaded content');

    if (objectives.isNotEmpty && !hasFallbackObjective) return objectives;

    return [
      'Identify the main ideas in this lesson.',
      'Explain the key Science concepts in your own words.',
      'Use the lesson content to answer practice questions.',
    ];
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  void _updateProgress() {
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _readingProgress = _scrollController.offset / _scrollController.position.maxScrollExtent;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateProgress);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.clear, color: AppTheme.textColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lessonTitle,
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSummary ? CupertinoIcons.sparkles : CupertinoIcons.doc_plaintext,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            tooltip: _showSummary ? 'Show Full Text' : 'Show AI Summary',
            onPressed: () {
              setState(() {
                _showSummary = !_showSummary;
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: _readingProgress,
            backgroundColor: AppTheme.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson Title
            Text(
              widget.lessonTitle,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor,
                letterSpacing: -1,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // AI Summary Section (shown by default)
            if (_showSummary && _displaySummary.isNotEmpty) ...[
              _buildAiSection(
                icon: CupertinoIcons.sparkles,
                title: "AI Summary",
                color: AppTheme.primaryColor,
                child: Text(
                  _displaySummary,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textColor.withValues(alpha: 0.85),
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Learning Objectives Section
            if (_showSummary && _displayObjectives.isNotEmpty) ...[
              _buildAiSection(
                icon: CupertinoIcons.checkmark_seal,
                title: "Learning Objectives",
                color: AppTheme.secondaryColor,
                child: Column(
                  children: _displayObjectives.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                "${entry.key + 1}",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.secondaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: AppTheme.borderColor),
              const SizedBox(height: 20),
            ],

            // Full Lesson Content
            Text(
              widget.content ?? "No content available for this lesson.",
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppTheme.textColor.withValues(alpha: 0.9),
                height: 1.8,
              ),
            ),
            const SizedBox(height: 40),
            
            // Take Practice Quiz Button
            if (widget.lessonId != null)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                    );
                    
                    final api = ref.read(apiServiceProvider);
                    final quizData = await api.getQuizByLesson(widget.lessonId!);
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading dialog
                      
                      if (quizData != null && quizData['_id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizInstructionsScreen(
                              quizId: quizData['_id'],
                              quizTitle: quizData['title'] ?? 'Practice Quiz',
                              timeLimit: quizData['timeLimit'] ?? 15,
                              questionsCount: quizData['questionsCount'] ?? 10,
                              passingScore: quizData['passingScore'] ?? 60,
                              themeColor: AppTheme.secondaryColor,
                              isPractice: quizData['isPractice'] == true,
                              scheduledDate: quizData['scheduledDate'],
                              scheduledTime: quizData['scheduledTime'],
                              endTime: quizData['endTime'],
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No practice quiz found for this lesson yet."),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(CupertinoIcons.doc_text, color: Colors.white, size: 20),
                  label: Text(
                    "Take Practice Quiz",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      // Floating AI Chat Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AiChatScreen(lessonId: widget.lessonId),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 20),
        label: Text(
          "Ask AI",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAiSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
