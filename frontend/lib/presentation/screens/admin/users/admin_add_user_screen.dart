import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAddUserScreen extends ConsumerStatefulWidget {
  const AdminAddUserScreen({super.key});

  @override
  ConsumerState<AdminAddUserScreen> createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends ConsumerState<AdminAddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = "student";
  bool _isSubmitting = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    FirebaseApp? tempApp;
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.isEmpty ? "scimathix123" : _passwordController.text;
      
      tempApp = await Firebase.initializeApp(
        name: 'AdminUserCreator',
        options: Firebase.app().options,
      );
      
      final auth = FirebaseAuth.instanceFor(app: tempApp);
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final apiService = ref.read(apiServiceProvider);
      final result = await apiService.register(
        firebaseUid: userCredential.user!.uid,
        email: email,
        name: _nameController.text.trim(),
        role: _selectedRole,
        password: password,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User registered successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Registration failed on server");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.xmark, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add New User",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: Text(
                  "Create Account",
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  "Fill in the details to register a new teacher or student into the SCIMATHIX system.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.subtleText,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              _buildSectionLabel("Select User Role"),
              const SizedBox(height: 12),
              _buildRoleSelector(),
              
              const SizedBox(height: 32),
              _buildSectionLabel("User Information"),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: "Full Name",
                hint: "e.g. Juan Luna",
                icon: CupertinoIcons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: "Email Address",
                hint: "user@scimathix.com",
                icon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: "Initial Password",
                hint: "At least 6 characters",
                icon: CupertinoIcons.lock,
                obscureText: true,
                helperText: "Leave blank for default: scimathix123",
              ),
              
              const SizedBox(height: 48),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return FadeInLeft(
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Row(
      children: [
        _buildRoleCard("student", "Student", CupertinoIcons.person_2, AppTheme.primaryColor),
        const SizedBox(width: 16),
        _buildRoleCard("teacher", "Teacher", CupertinoIcons.briefcase, AppTheme.secondaryColor),
      ],
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon, Color color) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
            ] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppTheme.subtleText, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? color : AppTheme.subtleText,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13),
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.subtleText.withOpacity(0.5), fontSize: 14),
              prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (label.contains("Password")) return null; // Optional
              if (value == null || value.isEmpty) return "Please enter $label";
              return null;
            },
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Text(
              helperText,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return FadeInUp(
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          ),
          child: _isSubmitting 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "Register Account",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
        ),
      ),
    );
  }
}
