import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isResending = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      
      if (refreshedUser?.emailVerified ?? false) {
        timer.cancel();
        if (mounted) {
          _showAlert(
            title: "Email Verified!",
            message: "Your account has been verified successfully. Welcome to SCIMATHIX!",
            icon: CupertinoIcons.checkmark_circle,
            color: Colors.green,
          );
          await Future.delayed(const Duration(seconds: 1));
          ref.invalidate(authProvider);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showAlert({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.subtleText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    "OK",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) {
        _showAlert(
          title: "Email Resent!",
          message: "A new verification link has been sent to your email address.",
          icon: CupertinoIcons.mail,
          color: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showAlert(
          title: "Error",
          message: "Could not resend verification email. Please wait a moment and try again.",
          icon: CupertinoIcons.xmark_circle,
          color: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "your email";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Mail Icon with simple animation
              ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Pulse(
                  infinite: true,
                  duration: const Duration(seconds: 2),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.mail_solid,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              // Title
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  "Check your email",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.subtleText,
                      height: 1.6,
                    ),
                    children: [
                      const TextSpan(text: "We've sent a verification link to\n"),
                      TextSpan(
                        text: email,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const TextSpan(text: "\nPlease click the link to activate your account."),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Background checking indicator
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Waiting for verification...",
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Resend Button
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: TextButton(
                  onPressed: _isResending ? null : _resendEmail,
                  child: Text(
                    _isResending ? "Sending..." : "Resend verification email",
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Cancel Button
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: TextButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: Icon(CupertinoIcons.arrow_left, size: 16, color: AppTheme.subtleText),
                  label: Text(
                    "Use a different account",
                    style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
