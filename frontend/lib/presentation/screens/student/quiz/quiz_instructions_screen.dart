import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_proper_screen.dart';

class QuizInstructionsScreen extends StatelessWidget {
  final String quizTitle;
  final Color themeColor;
  const QuizInstructionsScreen({super.key, required this.quizTitle, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context))),
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
                  _buildInfoRow(CupertinoIcons.question_circle, "15 Questions"),
                  _buildInfoRow(CupertinoIcons.timer, "30 Minutes"),
                  _buildInfoRow(CupertinoIcons.star, "50 XP Reward"),
                ]),
              ),
              const Spacer(),
              FadeInUp(
                child: SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizProperScreen(quizTitle: quizTitle, themeColor: themeColor))),
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text("Start Quiz", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppTheme.subtleText, size: 18),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
