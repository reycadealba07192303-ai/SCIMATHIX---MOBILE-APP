import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          "Notifications",
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
            _buildSectionHeader("Today"),
            const SizedBox(height: 16),
            _buildNotificationTile(
              icon: CupertinoIcons.timer,
              iconColor: AppTheme.accentColor,
              title: "Quiz Reminder",
              message: "Your Physics: Motion quiz starts in 30 minutes.",
              time: "2:30 PM",
              isUnread: true,
            ),
            _buildNotificationTile(
              icon: CupertinoIcons.doc_text,
              iconColor: AppTheme.primaryColor,
              title: "New Material Added",
              message: "Mr. Davis uploaded 'Advanced Algebra Pt 2'.",
              time: "10:15 AM",
              isUnread: true,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader("Yesterday"),
            const SizedBox(height: 16),
            _buildNotificationTile(
              icon: CupertinoIcons.sparkles,
              iconColor: AppTheme.secondaryColor,
              title: "AI Analysis Complete",
              message: "Your recent quiz mistakes have been analyzed.",
              time: "4:00 PM",
              isUnread: false,
            ),
            _buildNotificationTile(
              icon: CupertinoIcons.check_mark_circled,
              iconColor: AppTheme.primaryColor,
              title: "Assignment Graded",
              message: "You scored 95/100 on Cell Structure assignment.",
              time: "1:20 PM",
              isUnread: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 400),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.subtleText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? iconColor.withOpacity(0.05) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? iconColor.withOpacity(0.3) : AppTheme.borderColor,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.inter(
                          color: AppTheme.subtleText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      color: AppTheme.subtleText,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
