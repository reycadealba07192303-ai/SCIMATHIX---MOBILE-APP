import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_proper_screen.dart';

class QuizInstructionsScreen extends StatelessWidget {
  final String quizId;
  final String quizTitle;
  final int timeLimit;
  final int questionsCount;
  final int passingScore;
  final Color themeColor;
  final bool isPractice;
  final String? scheduledDate;
  final String? scheduledTime;
  final String? endTime;

  const QuizInstructionsScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.timeLimit,
    required this.questionsCount,
    required this.passingScore,
    required this.themeColor,
    this.isPractice = false,
    this.scheduledDate,
    this.scheduledTime,
    this.endTime,
  });

  (bool, String) _isAvailable() {
    if (scheduledDate == null || scheduledTime == null || endTime == null) {
      return (true, "Available Now");
    }
    
    try {
      final dateStr = DateTime.parse(scheduledDate!).toIso8601String().split('T')[0];
      final now = DateTime.now();
      
      final startTimeStr = "$dateStr $scheduledTime:00"; // "YYYY-MM-DD HH:mm:00"
      final endTimeStr = "$dateStr $endTime:00";
      
      final start = DateTime.parse(startTimeStr.replaceAll(' ', 'T'));
      final end = DateTime.parse(endTimeStr.replaceAll(' ', 'T'));
      
      if (now.isBefore(start)) {
        return (false, "Available at $scheduledTime");
      } else if (now.isAfter(end)) {
        return (false, "Quiz Expired");
      }
      
      return (true, "Ends at $endTime");
    } catch (e) {
      return (true, "Available Now");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: IconButton(icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context))),
              const Spacer(),
              FadeInDown(
                child: Column(children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(CupertinoIcons.pencil_circle, color: themeColor, size: 48),
                  ),
                  const SizedBox(height: 24),
                  Text(quizTitle, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textColor, letterSpacing: -0.5)),
                  const SizedBox(height: 24),
                  _buildInfoRow(CupertinoIcons.question_circle, "$questionsCount Questions"),
                  _buildInfoRow(CupertinoIcons.timer, timeLimit <= 0 ? "Untimed" : "$timeLimit Minutes"),
                  _buildInfoRow(
                    isPractice ? CupertinoIcons.lightbulb : CupertinoIcons.star,
                    isPractice ? "Practice Mode" : "${questionsCount * 10} XP Reward",
                  ),
                  Builder(builder: (context) {
                    final avail = _isAvailable();
                    final isAvail = avail.$1;
                    final statusMessage = avail.$2;
                    return _buildInfoRow(
                      isAvail ? CupertinoIcons.calendar_today : CupertinoIcons.lock_fill,
                      statusMessage,
                      color: isAvail ? AppTheme.accentColor : Colors.redAccent,
                    );
                  }),
                ]),
              ),
              const Spacer(),
              FadeInUp(
                child: Builder(builder: (context) {
                  final avail = _isAvailable();
                  final isAvail = avail.$1;
                  final statusMessage = avail.$2;
                  
                  return SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: isAvail ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizProperScreen(
                        quizId: quizId,
                        quizTitle: quizTitle,
                        timeLimit: timeLimit,
                        questionsCount: questionsCount,
                        themeColor: themeColor,
                        scheduledDate: scheduledDate,
                        endTime: endTime,
                      ))) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAvail ? themeColor : AppTheme.borderColor, 
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                        elevation: 0
                      ),
                      child: Text(
                        isAvail ? "Start Quiz" : statusMessage, 
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color ?? AppTheme.subtleText, size: 18),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(color: color ?? AppTheme.subtleText, fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
