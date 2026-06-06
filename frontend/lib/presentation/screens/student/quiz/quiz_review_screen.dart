import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class QuizReviewScreen extends StatelessWidget {
  final String quizTitle;
  final Color themeColor;
  final List<dynamic> results;
  const QuizReviewScreen({
    super.key,
    required this.quizTitle,
    required this.themeColor,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final reviews = results;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Review", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final r = reviews[index];
          final isCorrect = r["isCorrect"] == true;
          final statusColor = isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
          final steps = r['solutionSteps'] as List<dynamic>? ?? [];
          final imageUrl = (r['imageUrl'] ?? '').toString();
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
                if (imageUrl.isNotEmpty && !imageUrl.startsWith('data:')) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(imageUrl, height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                ],
                Text((r["questionText"] ?? 'Question').toString(), style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 15, height: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  Text("Your answer: ", style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13)),
                  Expanded(child: Text((r["chosenAnswer"] ?? 'No answer').toString(), style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13))),
                ]),
                if (!isCorrect) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Text("Correct answer: ", style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13)),
                    Expanded(child: Text((r["correctAnswer"] ?? '').toString(), style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 13))),
                  ]),
                ],
                if ((r['explanation'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text("Explanation", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text((r['explanation'] ?? '').toString(), style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13, height: 1.4)),
                ],
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text("Solution steps", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...steps.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text("${entry.key + 1}. ${entry.value}", style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13, height: 1.4)),
                  )),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }
}
