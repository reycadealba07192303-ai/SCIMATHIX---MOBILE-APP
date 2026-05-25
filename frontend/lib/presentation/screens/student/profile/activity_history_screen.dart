import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text("Activity History", style: GoogleFonts.inter(color: AppTheme.textColor)),
        iconTheme: const IconThemeData(color: AppTheme.textColor),
      ),
      body: Center(
        child: Text("Activity History coming soon!", style: GoogleFonts.inter(color: AppTheme.subtleText)),
      ),
    );
  }
}
