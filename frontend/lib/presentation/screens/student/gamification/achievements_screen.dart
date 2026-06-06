import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Achievements", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInDown(child: _buildXpCard()),
          const SizedBox(height: 24),
          Text("Badges Earned", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor, letterSpacing: -0.5)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            children: [
              _buildBadge("Quiz Master", CupertinoIcons.star_fill, AppTheme.accentColor, true),
              _buildBadge("Fast Learner", CupertinoIcons.bolt_fill, AppTheme.secondaryColor, true),
              _buildBadge("7-Day Streak", CupertinoIcons.flame_fill, AppTheme.primaryColor, true),
              _buildBadge("Top 10", CupertinoIcons.chart_bar_fill, AppTheme.primaryColor, false),
              _buildBadge("Perfect Score", CupertinoIcons.checkmark_seal_fill, AppTheme.accentColor, false),
              _buildBadge("Helper", CupertinoIcons.hand_thumbsup_fill, AppTheme.secondaryColor, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(CupertinoIcons.star_circle_fill, color: AppTheme.accentColor, size: 24),
          const SizedBox(width: 8),
          Text("2,210 XP", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: 0.7, backgroundColor: AppTheme.borderColor, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor), minHeight: 8)),
        const SizedBox(height: 8),
        Text("790 XP to Level 6", style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color, bool earned) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned ? color.withValues(alpha: 0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: earned ? color.withValues(alpha: 0.3) : AppTheme.borderColor),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: earned ? color : AppTheme.borderColor, size: 28),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.inter(color: earned ? AppTheme.textColor : AppTheme.subtleText, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
