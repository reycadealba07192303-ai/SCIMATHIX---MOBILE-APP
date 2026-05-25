import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class AppLoadingScreen extends StatelessWidget {
  final String message;
  const AppLoadingScreen({super.key, this.message = 'Initializing SCIMATHNIX...'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitPulse(
              color: AppTheme.primaryColor,
              size: 100.0,
            ),
            const SizedBox(height: 40),
            Text(
              message,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Please wait a moment",
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
