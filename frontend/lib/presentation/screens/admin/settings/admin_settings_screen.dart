import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Admin Settings",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader("System Configuration"),
          _buildSettingItem("Maintenance Mode", "Temporarily disable system access", CupertinoIcons.settings, Colors.orange, isSwitch: true),
          _buildSettingItem("Announcement Management", "Edit global notifications", CupertinoIcons.speaker_2, AppTheme.primaryColor),
          _buildSettingItem("API Configuration", "Manage AI model endpoints", CupertinoIcons.link, AppTheme.secondaryColor),
          const SizedBox(height: 32),
          _buildSectionHeader("Security & Data"),
          _buildSettingItem("Backup & Restore", "Manage system backups", CupertinoIcons.cloud_upload, Colors.blue),
          _buildSettingItem("Security Logs", "Review login attempts and changes", CupertinoIcons.lock_shield, AppTheme.accentColor),
          _buildSettingItem("Data Privacy", "Manage user data policies", CupertinoIcons.doc_text, Colors.teal),
          const SizedBox(height: 48),
          _buildLogoutButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 16),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.subtleText,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, String subtitle, IconData icon, Color color, {bool isSwitch = false}) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                ],
              ),
            ),
            if (isSwitch)
              CupertinoSwitch(value: false, onChanged: (val) {}, activeTrackColor: AppTheme.primaryColor)
            else
              const Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      child: TextButton(
        onPressed: () {
          ref.read(authProvider.notifier).logout();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
        ),
        child: Text(
          "Admin Log Out",
          style: GoogleFonts.inter(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
