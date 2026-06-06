import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/lessons/widgets/lesson_card.dart';

class DownloadedLessonsScreen extends StatelessWidget {
  const DownloadedLessonsScreen({super.key});

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
          "Downloaded",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: AppTheme.surfaceColor,
              child: Row(
                children: [
                  Icon(CupertinoIcons.info_circle, size: 16, color: AppTheme.subtleText),
                  const SizedBox(width: 8),
                  Text(
                    "Available offline. Taking up 145 MB.",
                    style: GoogleFonts.inter(
                      color: AppTheme.subtleText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: LessonCard(
                      title: "Geometry Fundamentals",
                      description: "Basic shapes and theorems.",
                      duration: "20 mins",
                      progress: 0.0,
                      themeColor: AppTheme.primaryColor,
                      isDownloaded: true,
                      onDownloadTap: () {
                        // Delete download action
                      },
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
