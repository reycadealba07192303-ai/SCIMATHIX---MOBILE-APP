import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/theme_provider.dart';
import 'package:scimathix/presentation/screens/student/profile/change_password_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final textColor = theme.textTheme.bodyLarge?.color ?? AppTheme.textColor;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.borderColor;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: Icon(CupertinoIcons.arrow_left, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text("Settings",
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInUp(
            child: _buildSection("General", surface, textColor, borderColor, [
              _buildToggleTile(CupertinoIcons.bell, "Push Notifications",
                  _notificationsEnabled, textColor, borderColor,
                  (v) {
                setState(() => _notificationsEnabled = v);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(v
                      ? "Push notifications enabled"
                      : "Push notifications disabled"),
                  duration: const Duration(seconds: 1),
                ));
              }),
              _buildToggleTile(CupertinoIcons.moon, "Dark Mode", isDark,
                  textColor, borderColor, (v) {
                ref.read(themeModeProvider.notifier).toggle(v);
              }),
            ]),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _buildSection("Privacy", surface, textColor, borderColor, [
              _buildNavTile(CupertinoIcons.lock, "Change Password", textColor,
                  borderColor, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                );
              }),
              _buildNavTile(CupertinoIcons.shield, "Privacy Settings",
                  textColor, borderColor, () => _showPrivacyDialog()),
              _buildNavTile(CupertinoIcons.doc_text, "Terms of Service",
                  textColor, borderColor, () => _showTermsDialog()),
            ]),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildSection("About", surface, textColor, borderColor, [
              _buildNavTile(CupertinoIcons.info_circle, "App Version 1.0.0",
                  textColor, borderColor, () => _showAboutDialog()),
              _buildNavTile(CupertinoIcons.question_circle, "Help & Support",
                  textColor, borderColor, () => _showHelpDialog()),
            ]),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Text(body,
              style: GoogleFonts.inter(height: 1.5, color: AppTheme.subtleText)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() => _showInfoDialog(
        "Privacy Settings",
        "SCIMATHIX stores your learning data (quiz attempts, XP, messages) to power your dashboard and leaderboard. Your data is visible only to you, your teachers, and administrators. We never share your information with third parties.",
      );

  void _showTermsDialog() => _showInfoDialog(
        "Terms of Service",
        "By using SCIMATHIX you agree to use the platform for educational purposes, keep your account credentials secure, and respect other users. Misuse of the chat or quiz systems may result in account suspension by an administrator.",
      );

  void _showAboutDialog() => _showInfoDialog(
        "About SCIMATHIX",
        "SCIMATHIX v1.0.0\n\nA Science and Mathematics learning platform with lessons, quizzes, gamification, AI tutoring, and real-time classroom features for students, teachers, and admins.",
      );

  void _showHelpDialog() => _showInfoDialog(
        "Help & Support",
        "Need help? Reach out to your section adviser through the Chat tab, or contact support@scimathix.com. For account issues, ask your school administrator.",
      );

  Widget _buildSection(String title, Color surface, Color textColor,
      Color borderColor, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.subtleText,
              letterSpacing: 0.5)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor)),
        child: Column(children: children),
      ),
    ]);
  }

  Widget _buildToggleTile(IconData icon, String title, bool value,
      Color textColor, Color borderColor, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5))),
      child: Row(children: [
        Icon(icon, color: AppTheme.subtleText, size: 20),
        const SizedBox(width: 14),
        Expanded(
            child: Text(title,
                style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 15))),
        CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryColor),
      ]),
    );
  }

  Widget _buildNavTile(IconData icon, String title, Color textColor,
      Color borderColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 0.5))),
        child: Row(children: [
          Icon(icon, color: AppTheme.subtleText, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 15))),
          Icon(CupertinoIcons.chevron_right,
              color: AppTheme.subtleText, size: 16),
        ]),
      ),
    );
  }
}
