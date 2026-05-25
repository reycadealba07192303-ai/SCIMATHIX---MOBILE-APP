import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/lessons/lesson_details_screen.dart';
import 'package:scimathix/presentation/screens/student/lessons/widgets/lesson_card.dart';

class LessonListScreen extends StatelessWidget {
  final String moduleTitle;
  final Color themeColor;

  const LessonListScreen({
    super.key,
    required this.moduleTitle,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    // Mock lessons
    final lessons = [
      {"title": "Introduction to $moduleTitle", "desc": "Learn the basics and foundational concepts.", "dur": "15 mins"},
      {"title": "Core Principles", "desc": "Deep dive into the main rules and formulas.", "dur": "25 mins"},
      {"title": "Practical Applications", "desc": "See how this applies in real-world scenarios.", "dur": "20 mins"},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Lessons",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeInDown(
                child: Text(
                  moduleTitle,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    child: LessonCard(
                      title: lesson["title"]!,
                      description: lesson["desc"]!,
                      duration: lesson["dur"]!,
                      progress: index == 0 ? 1.0 : (index == 1 ? 0.3 : 0.0),
                      themeColor: themeColor,
                      isSaved: index == 0,
                      onSaveTap: () {},
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonDetailsScreen(
                              lessonTitle: lesson["title"]!,
                              themeColor: themeColor,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
