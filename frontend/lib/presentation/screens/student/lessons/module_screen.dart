import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/lessons/lesson_list_screen.dart';

class ModuleScreen extends StatelessWidget {
  final String subject;
  final Color themeColor;

  const ModuleScreen({
    super.key,
    required this.subject,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    // Mock modules data based on subject
    final isMath = subject == "Mathematics";
    final modules = isMath
        ? ["Algebra Basics", "Geometry Fundamentals", "Trigonometry", "Calculus I"]
        : ["Cell Structure", "Newton's Laws of Motion", "Chemical Reactions", "Genetics"];

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
          "$subject Modules",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: modules.length,
          itemBuilder: (context, index) {
            return FadeInUp(
              delay: Duration(milliseconds: 100 * index),
              child: _buildModuleTile(context, title: modules[index], index: index + 1),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, {required String title, required int index}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LessonListScreen(
              moduleTitle: title,
              themeColor: themeColor,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "0$index",
                  style: GoogleFonts.inter(
                    color: themeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: AppTheme.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "5 Lessons • 2 Quizzes",
                    style: GoogleFonts.inter(
                      color: AppTheme.subtleText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 20),
          ],
        ),
      ),
    );
  }
}
