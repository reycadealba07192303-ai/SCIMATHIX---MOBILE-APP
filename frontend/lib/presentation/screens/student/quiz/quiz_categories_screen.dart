import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_instructions_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/logic/data_providers.dart';

class QuizCategoriesScreen extends ConsumerWidget {
  const QuizCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, 
        elevation: 0, 
        centerTitle: true,
        title: Text(
          "Available Quizzes", 
          style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          ref.invalidate(quizzesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FadeInDown(
              child: Text(
                "Quick Quiz Panel", 
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textColor, letterSpacing: -0.5)
              )
            ),
            const SizedBox(height: 8),
            FadeInDown(
              child: Text(
                "Jump straight into your quizzes.", 
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText)
              )
            ),
            const SizedBox(height: 24),
            
            quizzesAsync.when(
              data: (quizzes) {
                if (quizzes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text("No quizzes available.", style: GoogleFonts.inter(color: AppTheme.subtleText)),
                    ),
                  );
                }

                return Column(
                  children: quizzes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final quiz = entry.value;
                    
                    final title = quiz['title'] ?? 'Untitled Quiz';
                    final subjectObj = quiz['subject'];
                    final subjectName = subjectObj != null ? subjectObj['name'] : 'General';
                    final questionsCount = (quiz['questions'] as List?)?.length ?? 5;
                    final isPractice = quiz['isPractice'] == true;
                    
                    // Pick a rotating color for variety
                    final colors = [AppTheme.primaryColor, AppTheme.secondaryColor, AppTheme.accentColor];
                    final color = colors[index % colors.length];

                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (_) => QuizInstructionsScreen(
                              quizId: quiz['_id'] ?? '',
                              quizTitle: title,
                              timeLimit: quiz['timeLimit'] ?? 15,
                              questionsCount: quiz['questionsCount'] ?? questionsCount,
                              passingScore: quiz['passingScore'] ?? 60,
                              themeColor: color,
                              isPractice: isPractice,
                              scheduledDate: quiz['scheduledDate'],
                              scheduledTime: quiz['scheduledTime'],
                              endTime: quiz['endTime'],
                            )
                          )
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor, 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1), 
                                  borderRadius: BorderRadius.circular(14)
                                ),
                                child: Icon(CupertinoIcons.pencil_circle_fill, color: color, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            subjectName,
                                            style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPractice ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isPractice ? "Practice" : "Real Quiz",
                                            style: GoogleFonts.inter(
                                              color: isPractice ? AppTheme.primaryColor : AppTheme.accentColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      title,
                                      style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 16)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$questionsCount Questions",
                                      style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13)
                                    ),
                                  ]
                                )
                              ),
                              Icon(CupertinoIcons.chevron_right_circle_fill, color: color.withOpacity(0.5), size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ],
        ),
      ),
    );
  }
}
