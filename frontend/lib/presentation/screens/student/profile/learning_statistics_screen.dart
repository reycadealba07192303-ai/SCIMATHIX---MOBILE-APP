import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class LearningStatisticsScreen extends StatelessWidget {
  const LearningStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text("Learning Statistics", style: GoogleFonts.inter(color: AppTheme.textColor)),
        iconTheme: IconThemeData(color: AppTheme.textColor),
      ),
      body: Center(
        child: Text("Learning Statistics coming soon!", style: GoogleFonts.inter(color: AppTheme.subtleText)),
      ),
    );
  }
}
