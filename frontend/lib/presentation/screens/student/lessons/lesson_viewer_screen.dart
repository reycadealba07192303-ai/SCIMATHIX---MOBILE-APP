import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/ai/ai_chat_screen.dart';

class LessonViewerScreen extends StatefulWidget {
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
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  double _readingProgress = 0.0;
  bool _showSummary = true;

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.clear, color: AppTheme.textColor, size: 24),
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
            if (_showSummary && widget.summary != null && widget.summary!.isNotEmpty) ...[
              _buildAiSection(
                icon: CupertinoIcons.sparkles,
                title: "AI Summary",
                color: AppTheme.primaryColor,
                child: Text(
                  widget.summary!,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppTheme.textColor.withOpacity(0.85),
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Learning Objectives Section
            if (_showSummary && widget.objectives != null && widget.objectives!.isNotEmpty) ...[
              _buildAiSection(
                icon: CupertinoIcons.checkmark_seal,
                title: "Learning Objectives",
                color: AppTheme.secondaryColor,
                child: Column(
                  children: widget.objectives!.asMap().entries.map((entry) {
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
                              color: AppTheme.secondaryColor.withOpacity(0.1),
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
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 20),
            ],

            // Full Lesson Content
            Text(
              widget.content ?? "No content available for this lesson.",
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppTheme.textColor.withOpacity(0.9),
                height: 1.8,
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
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
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
