import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class QuizReviewScreen extends StatelessWidget {
  final String quizTitle;
  final Color themeColor;
  const QuizReviewScreen({super.key, required this.quizTitle, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {"q": "What is the value of x if 2x + 5 = 15?", "your": "x = 5", "correct": "x = 5", "isCorrect": true},
      {"q": "What is the square root of 144?", "your": "10", "correct": "12", "isCorrect": false},
      {"q": "Which is the powerhouse of the cell?", "your": "Mitochondria", "correct": "Mitochondria", "isCorrect": true},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Review", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final r = reviews[index];
          final isCorrect = r["isCorrect"] as bool;
          final statusColor = isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
          return FadeInUp(
            delay: Duration(milliseconds: 100 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(isCorrect ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text("Question ${index + 1}", style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
                const SizedBox(height: 12),
                Text(r["q"] as String, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 15, height: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  Text("Your answer: ", style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13)),
                  Text(r["your"] as String, style: GoogleFonts.inter(color: isCorrect ? statusColor : statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
                if (!isCorrect) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Text("Correct answer: ", style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13)),
                    Text(r["correct"] as String, style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }
}
