import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class WeakTopicsScreen extends StatelessWidget {
  const WeakTopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Weak Topics", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInDown(child: Text("Areas that need improvement", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.subtleText, letterSpacing: 0.5))),
          const SizedBox(height: 16),
          _buildWeakTopic("Quadratic Equations", 0.35, "Mathematics"),
          _buildWeakTopic("Chemical Bonding", 0.42, "Science"),
          _buildWeakTopic("Trigonometric Identities", 0.28, "Mathematics"),
        ],
      ),
    );
  }

  Widget _buildWeakTopic(String topic, double score, String subject) {
    final color = score < 0.4 ? const Color(0xFFEF4444) : AppTheme.accentColor;
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(topic, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text("${(score * 100).toInt()}%", style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subject, style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: score, backgroundColor: AppTheme.borderColor, valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6),
            ),
          ],
        ),
      ),
    );
  }
}
