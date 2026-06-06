import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/lessons/widgets/lesson_card.dart';

class SavedLessonsScreen extends StatelessWidget {
  const SavedLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Saved Lessons",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: LessonCard(
                title: "Introduction to Algebra",
                description: "Foundational concepts of Algebra.",
                duration: "15 mins",
                progress: 1.0,
                themeColor: AppTheme.primaryColor,
                isSaved: true,
                onSaveTap: () {},
                onTap: () {},
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: LessonCard(
                title: "Newton's Laws",
                description: "Deep dive into the laws of motion.",
                duration: "30 mins",
                progress: 0.5,
                themeColor: AppTheme.secondaryColor,
                isSaved: true,
                onSaveTap: () {},
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
