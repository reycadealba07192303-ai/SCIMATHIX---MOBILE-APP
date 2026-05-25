import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_review_screen.dart';
import 'package:scimathix/data/services/api_service.dart';

class QuizResultsScreen extends StatefulWidget {
  final String quizTitle;
  final Color themeColor;
  final int? score;
  final int? totalQuestions;
  final int? xpEarned;
  final List<dynamic>? results;

  const QuizResultsScreen({
    super.key,
    required this.quizTitle,
    required this.themeColor,
    this.score,
    this.totalQuestions,
    this.xpEarned,
    this.results,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  List<dynamic> _weakTopics = [];
  bool _loadingRecommendations = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    try {
      final api = ApiService();
      final topics = await api.getWeakTopics();
      if (mounted) {
        setState(() {
          _weakTopics = topics;
          _loadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRecommendations = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreVal = widget.score ?? 0;
    final totalVal = widget.totalQuestions ?? 1;
    final percentage = totalVal > 0 ? ((scoreVal / totalVal) * 100).round() : 0;
    final xp = widget.xpEarned ?? 0;

    // Determine performance tier
    String message;
    IconData icon;
    Color iconColor;
    if (percentage >= 90) {
      message = "Outstanding! 🏆";
      icon = CupertinoIcons.star_fill;
      iconColor = AppTheme.accentColor;
    } else if (percentage >= 75) {
      message = "Great Job! 🎉";
      icon = CupertinoIcons.checkmark_seal_fill;
      iconColor = AppTheme.primaryColor;
    } else if (percentage >= 50) {
      message = "Good Effort! 💪";
      icon = CupertinoIcons.hand_thumbsup_fill;
      iconColor = AppTheme.secondaryColor;
    } else {
      message = "Keep Trying! 📚";
      icon = CupertinoIcons.arrow_counterclockwise;
      iconColor = AppTheme.subtleText;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Score Header
              FadeInDown(
                child: Column(children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(message, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                  const SizedBox(height: 8),
                  Text(widget.quizTitle, style: GoogleFonts.inter(fontSize: 16, color: AppTheme.subtleText)),
                  const SizedBox(height: 32),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _buildStatCard("Score", "$percentage%", widget.themeColor),
                    const SizedBox(width: 16),
                    _buildStatCard("XP Earned", "+$xp", AppTheme.accentColor),
                    const SizedBox(width: 16),
                    _buildStatCard("Correct", "$scoreVal/$totalVal", AppTheme.secondaryColor),
                  ]),
                ]),
              ),
              const SizedBox(height: 32),

              // Mistakes Summary
              if (widget.results != null && widget.results!.isNotEmpty) ...[
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: _buildMistakesSummary(),
                ),
                const SizedBox(height: 24),
              ],

              // AI Recommendations Section
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildAiRecommendations(),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(children: [
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizReviewScreen(quizTitle: widget.quizTitle, themeColor: widget.themeColor))),
                      style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: Text("Review Answers", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textColor, side: const BorderSide(color: AppTheme.borderColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text("Back to Home", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMistakesSummary() {
    final wrongAnswers = widget.results!.where((r) => r['isCorrect'] == false).toList();
    if (wrongAnswers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            Text("Perfect score! No mistakes! 🎯", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppTheme.accentColor, size: 20),
              const SizedBox(width: 8),
              Text("${wrongAnswers.length} Mistake${wrongAnswers.length > 1 ? 's' : ''}", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Review your incorrect answers to understand where you went wrong.",
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRecommendations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
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
                child: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "AI Recommendations",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingRecommendations)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_weakTopics.isEmpty)
            _buildRecommendationTile(
              icon: CupertinoIcons.checkmark_seal_fill,
              color: AppTheme.primaryColor,
              title: "You're doing great!",
              subtitle: "No weak spots detected. Keep up the excellent work!",
            )
          else ...[
            Text(
              "Based on your quiz history, here are topics you should focus on:",
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, height: 1.5),
            ),
            const SizedBox(height: 12),
            ..._weakTopics.take(3).map((topic) {
              final topicName = topic['topic'] ?? 'Unknown';
              final topicScore = topic['score'] ?? 0;
              return _buildRecommendationTile(
                icon: CupertinoIcons.exclamationmark_triangle,
                color: topicScore < 50 ? Colors.redAccent : AppTheme.accentColor,
                title: topicName,
                subtitle: "Your score: $topicScore% — Review this topic to improve.",
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
