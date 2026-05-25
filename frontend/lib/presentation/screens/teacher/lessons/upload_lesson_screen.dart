import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class UploadLessonScreen extends StatefulWidget {
  const UploadLessonScreen({super.key});

  @override
  State<UploadLessonScreen> createState() => _UploadLessonScreenState();
}

class _UploadLessonScreenState extends State<UploadLessonScreen> {
  String _selectedSubject = "Mathematics";
  String _selectedGrade = "Grade 10";
  bool _aiAnalysis = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Upload Lesson",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("Lesson Details"),
            const SizedBox(height: 16),
            _buildTextField("Lesson Title", "Enter lesson title"),
            const SizedBox(height: 20),
            _buildTextField("Description", "Enter short description", maxLines: 3),
            const SizedBox(height: 32),
            _buildSectionLabel("Classification"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdown("Subject", ["Mathematics", "Science"], _selectedSubject, (val) => setState(() => _selectedSubject = val!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown("Grade Level", ["Grade 7", "Grade 8", "Grade 9", "Grade 10"], _selectedGrade, (val) => setState(() => _selectedGrade = val!))),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionLabel("Media"),
            const SizedBox(height: 16),
            _buildFileUploadArea(),
            const SizedBox(height: 32),
            _buildAIAnalysisToggle(),
            const SizedBox(height: 48),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textColor,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.subtleText),
        ),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.surfaceColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.subtleText),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textColor)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.cloud_upload, color: AppTheme.primaryColor, size: 40),
          const SizedBox(height: 16),
          Text(
            "Select files or drag and drop",
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            "PDF, DOCX, or PPT up to 10MB",
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Analyze with AI", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                Text("Auto-generate summaries and objectives", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _aiAnalysis,
            onChanged: (val) => setState(() => _aiAnalysis = val),
            activeTrackColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FadeInUp(
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {},
          child: const Text("Upload and Publish"),
        ),
      ),
    );
  }
}
