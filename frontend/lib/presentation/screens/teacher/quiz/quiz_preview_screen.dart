import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class QuizPreviewScreen extends StatelessWidget {
  const QuizPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Preview Quiz",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              "Regenerate",
              style: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildQuestionCard(
                  1,
                  "What is the value of x in the equation 2x + 5 = 15?",
                  ["x = 5", "x = 10", "x = 7.5", "x = 2"],
                  0,
                ),
                _buildQuestionCard(
                  2,
                  "Which of the following is a quadratic equation?",
                  ["y = mx + b", "x² + 5x + 6 = 0", "2x + 3 = 7", "√x = 4"],
                  1,
                ),
                _buildQuestionCard(
                  3,
                  "What is the discriminant formula?",
                  ["b² - 4ac", "-b / 2a", "√(x² + y²)", "πr²"],
                  0,
                ),
              ],
            ),
          ),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, String question, List<String> options, int correctIndex) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Q$index",
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(CupertinoIcons.pencil, color: AppTheme.subtleText, size: 16),
                const SizedBox(width: 12),
                const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(options.length, (i) {
              bool isCorrect = i == correctIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withOpacity(0.05) : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCorrect ? Colors.green.withOpacity(0.2) : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + i),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isCorrect ? Colors.green : AppTheme.subtleText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 16),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: const Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text("Save as Draft"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              child: const Text("Assign to Section"),
            ),
          ),
        ],
      ),
    );
  }
}
