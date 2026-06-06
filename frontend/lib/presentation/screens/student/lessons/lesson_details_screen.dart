import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:scimathix/presentation/screens/student/lessons/lesson_viewer_screen.dart';

class LessonDetailsScreen extends StatelessWidget {
  final String lessonTitle;
  final Color themeColor;
  final String? lessonId;
  final String? content;
  final String? summary;
  final List<dynamic>? objectives;
  final String? fileUrl;

  const LessonDetailsScreen({
    super.key,
    required this.lessonTitle,
    required this.themeColor,
    this.lessonId,
    this.content,
    this.summary,
    this.objectives,
    this.fileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // Space for bottom button
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: Icon(CupertinoIcons.bookmark, color: AppTheme.textColor),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  
                  // Hero Icon
                  FadeInDown(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(CupertinoIcons.book, size: 48, color: themeColor),
                      ),
                    ),
                  ),
                  
                  // Title & Meta
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            lessonTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMetaTag(CupertinoIcons.clock, "25 mins"),
                              const SizedBox(width: 16),
                              _buildMetaTag(CupertinoIcons.doc_text, "12 Pages"),
                              const SizedBox(width: 16),
                              _buildMetaTag(CupertinoIcons.star_fill, "4.8", color: AppTheme.accentColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    child: Divider(color: AppTheme.borderColor),
                  ),
                  
                  // Description
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "About this lesson",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            summary ?? "In this comprehensive lesson, you will learn the fundamental principles required to master this topic. We will cover theoretical concepts, practical applications, and common problem-solving techniques.\n\nMake sure to take notes as there will be a short quiz at the end of the module to test your understanding.",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppTheme.subtleText,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            "Learning Objectives",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (objectives != null && objectives!.isNotEmpty)
                            ...objectives!.map((obj) => _buildObjectiveTile(obj.toString()))
                          else ...[                          
                            _buildObjectiveTile("Understand the core definitions and formulas."),
                            _buildObjectiveTile("Apply concepts to real-world scenarios."),
                            _buildObjectiveTile("Solve complex multi-step problems."),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  border: Border(top: BorderSide(color: AppTheme.borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Download PDF button (only if fileUrl exists)
                    if (fileUrl != null && fileUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: () async {
                              final fullUrl = '${ApiConfig.serverBaseUrl}$fileUrl';
                              final uri = Uri.parse(fullUrl);
                              final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                              if (!launched && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open file'), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: themeColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Icon(CupertinoIcons.arrow_down_doc, color: themeColor, size: 22),
                          ),
                        ),
                      ),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LessonViewerScreen(
                                  lessonTitle: lessonTitle,
                                  lessonId: lessonId,
                                  content: content,
                                  summary: summary,
                                  objectives: objectives,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Start Learning",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text, {Color? color}) {
    final tagColor = color ?? AppTheme.subtleText;
    return Row(
      children: [
        Icon(icon, size: 14, color: tagColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            color: AppTheme.subtleText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectiveTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppTheme.textColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
