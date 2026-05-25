import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Settings", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInUp(
            child: _buildSection("General", [
              _buildToggleTile(CupertinoIcons.bell, "Push Notifications", _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
              _buildToggleTile(CupertinoIcons.moon, "Dark Mode", _darkMode, (v) => setState(() => _darkMode = v)),
            ]),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _buildSection("Privacy", [
              _buildNavTile(CupertinoIcons.lock, "Change Password"),
              _buildNavTile(CupertinoIcons.shield, "Privacy Settings"),
              _buildNavTile(CupertinoIcons.doc_text, "Terms of Service"),
            ]),
          ),
          const SizedBox(height: 24),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildSection("About", [
              _buildNavTile(CupertinoIcons.info_circle, "App Version 1.0.0"),
              _buildNavTile(CupertinoIcons.question_circle, "Help & Support"),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.subtleText, letterSpacing: 0.5)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
        child: Column(children: children),
      ),
    ]);
  }

  Widget _buildToggleTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5))),
      child: Row(children: [
        Icon(icon, color: AppTheme.subtleText, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w500, fontSize: 15))),
        CupertinoSwitch(value: value, onChanged: onChanged, activeTrackColor: AppTheme.primaryColor),
      ]),
    );
  }

  Widget _buildNavTile(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5))),
      child: Row(children: [
        Icon(icon, color: AppTheme.subtleText, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w500, fontSize: 15))),
        const Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
      ]),
    );
  }
}
