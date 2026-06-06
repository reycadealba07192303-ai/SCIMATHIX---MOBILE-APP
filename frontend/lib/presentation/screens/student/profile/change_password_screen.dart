import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

/// Password change is handled via a Firebase password-reset email,
/// matching the app's Firebase-first auth model.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  bool _isSending = false;
  bool _sent = false;
  String? _error;

  Future<void> _sendResetEmail() async {
    final email = ref.read(authProvider).user?.email ??
        FirebaseAuth.instance.currentUser?.email;

    if (email == null || email.isEmpty) {
      setState(() => _error = "No email associated with this account.");
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _isSending = false;
          _sent = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _error = e.message ?? "Could not send reset email.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _error = "Something went wrong. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? AppTheme.textColor;
    final email = ref.watch(authProvider).user?.email ??
        FirebaseAuth.instance.currentUser?.email ??
        'your email';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: Icon(CupertinoIcons.arrow_left, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text("Change Password",
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: FadeInUp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _sent
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.lock_rotation,
                  color: _sent ? AppTheme.secondaryColor : AppTheme.primaryColor,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _sent ? "Check your email" : "Reset your password",
                style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor),
              ),
              const SizedBox(height: 12),
              Text(
                _sent
                    ? "We sent a password reset link to $email. Open it to create a new password."
                    : "For your security, we'll send a password reset link to your email address:\n\n$email",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.subtleText,
                    height: 1.5),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 32),
              if (!_sent)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text("Send Reset Email",
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text("Done",
                        style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
