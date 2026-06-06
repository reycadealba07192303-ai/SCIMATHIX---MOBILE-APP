import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text("Notifications", style: GoogleFonts.inter(color: AppTheme.textColor)),
        iconTheme: IconThemeData(color: AppTheme.textColor),
      ),
      body: Center(
        child: Text("No new notifications.", style: GoogleFonts.inter(color: AppTheme.subtleText)),
      ),
    );
  }
}
