import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AdminAddSectionScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String levelName;

  const AdminAddSectionScreen({
    super.key,
    required this.levelId,
    required this.levelName,
  });

  @override
  ConsumerState<AdminAddSectionScreen> createState() => _AdminAddSectionScreenState();
}

class _AdminAddSectionScreenState extends ConsumerState<AdminAddSectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.createSection(_nameController.text.trim(), widget.levelId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Section created successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
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
          icon: const Icon(Icons.close, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Section",
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
                  "Section Management",
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
                  "Adding a new section to ${widget.levelName}. You can assign a teacher and enroll students after creation.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.subtleText,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              _buildSectionLabel("Section Details"),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: "Section Name",
                hint: "e.g. Section A",
                icon: CupertinoIcons.group,
              ),
              
              const SizedBox(height: 64),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TextFormField(
        controller: controller,
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
          if (value == null || value.isEmpty) return "Please enter $label";
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FadeInUp(
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _handleCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
          ),
          child: _isSubmitting 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "Create Section",
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
