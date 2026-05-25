import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late String _selectedRole;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = 'student';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showAlert({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onDismiss,
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
                  onPressed: () {
                    Navigator.pop(context);
                    onDismiss?.call();
                  },
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

  @override
  Widget build(BuildContext context) {
    // Listen for auth errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        _showAlert(
          title: "Registration Failed",
          message: next.error!,
          icon: CupertinoIcons.xmark_circle,
          color: Colors.redAccent,
        );
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Back Button & Logo
              FadeInDown(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor, size: 24),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.sparkles,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Header
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    Text(
                      "Create an account",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your details to get started.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Role Dropdown
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "I am a",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRole,
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceColor,
                          icon: const Icon(CupertinoIcons.chevron_down, color: AppTheme.subtleText, size: 16),
                          style: GoogleFonts.inter(
                            color: AppTheme.textColor, 
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'student',
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.person, color: AppTheme.subtleText, size: 20),
                                  const SizedBox(width: 12),
                                  Text("Student", style: GoogleFonts.inter()),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'teacher',
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.book, color: AppTheme.subtleText, size: 20),
                                  const SizedBox(width: 12),
                                  Text("Teacher", style: GoogleFonts.inter()),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Row(
                                children: [
                                  const Icon(CupertinoIcons.shield, color: AppTheme.subtleText, size: 20),
                                  const SizedBox(width: 12),
                                  Text("Admin", style: GoogleFonts.inter()),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRole = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Name Field
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Full name",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: GoogleFonts.inter(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Enter your full name",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Email Field
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email address",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: GoogleFonts.inter(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Enter your email address",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Password Field
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.inter(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Create a password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                            color: AppTheme.subtleText,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Confirm Password Field
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Confirm password",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: GoogleFonts.inter(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: "Repeat your password",
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                            color: AppTheme.subtleText,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register Button
              FadeInUp(
                delay: const Duration(milliseconds: 800),
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleRegister,
                  child: authState.isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Create account"),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Login Navigation
              FadeInUp(
                delay: const Duration(milliseconds: 900),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.inter(
                        color: AppTheme.subtleText,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Sign in",
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showAlert(
        title: "Missing Information",
        message: "Please fill in all required fields to create your account.",
        icon: CupertinoIcons.exclamationmark_triangle,
        color: Colors.orange,
      );
      return;
    }
    
    if (password != confirmPassword) {
      _showAlert(
        title: "Passwords Don't Match",
        message: "Please make sure both passwords are the same.",
        icon: CupertinoIcons.lock_shield,
        color: Colors.orange,
      );
      return;
    }

    if (password.length < 6) {
      _showAlert(
        title: "Weak Password",
        message: "Your password must be at least 6 characters long.",
        icon: CupertinoIcons.lock_open,
        color: Colors.orange,
      );
      return;
    }

    await ref.read(authProvider.notifier).register(email, password, name, _selectedRole);
    
    // Check for errors after register completes
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.error != null) {
      _showAlert(
        title: "Registration Failed",
        message: authState.error!,
        icon: CupertinoIcons.xmark_circle,
        color: Colors.redAccent,
      );
    } else if (authState.user != null) {
      _showAlert(
        title: "Account Created!",
        message: "Your account was successfully created. Please check your email to verify your account.",
        icon: CupertinoIcons.checkmark_seal_fill,
        color: Colors.green,
        onDismiss: () {
          // Pop all the way back to the RootWrapper so it can display the VerifyEmailScreen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      );
    }
  }
}
