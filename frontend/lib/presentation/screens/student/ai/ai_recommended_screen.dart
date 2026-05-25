import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class AiRecommendedScreen extends StatelessWidget {
  const AiRecommendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Recommended", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInDown(child: Text("Based on your progress", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.subtleText, letterSpacing: 0.5))),
          const SizedBox(height: 16),
          _buildRecommendation("Practice Algebra Equations", "You scored 65% on the last quiz. Let's strengthen this area.", CupertinoIcons.function, AppTheme.primaryColor),
          _buildRecommendation("Review Cell Division", "This topic appears frequently in upcoming assessments.", CupertinoIcons.lab_flask, AppTheme.secondaryColor),
          _buildRecommendation("Try Geometry Challenges", "You're doing great! Push further with advanced problems.", CupertinoIcons.triangle, AppTheme.accentColor),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String title, String desc, IconData icon, Color color) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13, height: 1.4)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
