import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class UploadLessonScreen extends ConsumerStatefulWidget {
  const UploadLessonScreen({super.key});

  @override
  ConsumerState<UploadLessonScreen> createState() => _UploadLessonScreenState();
}

class _UploadLessonScreenState extends ConsumerState<UploadLessonScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _aiAnalysis = true;
  bool _isUploading = false;
  String? _selectedSubjectId;
  String? _selectedSectionId;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  String? _selectedFilePath;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getHandledClasses() {
    final user = ref.read(authProvider).user;
    if (user?.handledClasses == null) return [];
    return user!.handledClasses!.map((hc) => {
      'subjectId': hc.subjectId,
      'subjectName': hc.subjectName,
      'sectionId': hc.sectionId,
      'sectionName': hc.sectionName,
      'levelName': hc.levelName,
    }).toList();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx', 'doc', 'ppt'],
      withData: true, // Required for Web
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.first.name;
        _selectedFileBytes = result.files.first.bytes;
        _selectedFilePath = result.files.first.path;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar("Please enter a lesson title.", isError: true);
      return;
    }
    if (_selectedSubjectId == null || _selectedSectionId == null) {
      _showSnackBar("Please select a subject and section.", isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.uploadLesson(
        title: _titleController.text.trim(),
        subjectId: _selectedSubjectId!,
        content: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : "Please refer to the attached document for the lesson content.",
        sectionIds: [_selectedSectionId!],
        filePath: _selectedFilePath,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );
      if (result != null && mounted) {
        _showSnackBar("Lesson uploaded successfully!");
        Navigator.pop(context);
      } else {
        _showSnackBar("Upload failed. Please try again.", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.redAccent : AppTheme.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final classes = _getHandledClasses();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Upload Lesson",
          style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Lesson Details ────────────────────────────
            FadeInDown(
              child: _buildSectionHeader("Lesson Details", CupertinoIcons.doc_text_fill),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              delay: const Duration(milliseconds: 50),
              child: _buildModernTextField(
                controller: _titleController,
                label: "Lesson Title",
                hint: "e.g. Introduction to Algebra",
                icon: CupertinoIcons.textformat,
              ),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: _buildModernTextField(
                controller: _descriptionController,
                label: "Description (Optional)",
                hint: "Short summary of the lesson content...",
                icon: CupertinoIcons.text_alignleft,
                maxLines: 4,
              ),
            ),

            const SizedBox(height: 32),

            // ─── Classification ────────────────────────────
            FadeInDown(
              delay: const Duration(milliseconds: 150),
              child: _buildSectionHeader("Classification", CupertinoIcons.tag_fill),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              child: _buildClassSelectionCards(classes),
            ),

            const SizedBox(height: 32),

            // ─── Media Upload ──────────────────────────────
            FadeInDown(
              delay: const Duration(milliseconds: 250),
              child: _buildSectionHeader("Media", CupertinoIcons.cloud_upload_fill),
            ),
            const SizedBox(height: 16),
            FadeInDown(
              delay: const Duration(milliseconds: 300),
              child: _buildFileUploadArea(),
            ),

            const SizedBox(height: 32),

            // ─── AI Toggle ────────────────────────────────
            FadeInDown(
              delay: const Duration(milliseconds: 350),
              child: _buildAIAnalysisToggle(),
            ),

            const SizedBox(height: 48),

            // ─── Submit Button ─────────────────────────────
            FadeInUp(child: _buildSubmitButton()),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textColor, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, right: 20),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.subtleText, size: 16),
                const SizedBox(width: 8),
                Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.subtleText, letterSpacing: 0.5)),
              ],
            ),
          ),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: AppTheme.subtleText.withOpacity(0.5), fontWeight: FontWeight.w500),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelectionCards(List<Map<String, String>> classes) {
    if (classes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Center(
          child: Text("No handled classes found.", style: GoogleFonts.inter(color: AppTheme.subtleText)),
        ),
      );
    }

    // Deduplicate by subjectId
    final seen = <String>{};
    final unique = classes.where((c) => seen.add(c['subjectId']!)).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: unique.map((cls) {
        final isSelected = _selectedSubjectId == cls['subjectId'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubjectId = cls['subjectId'];
              _selectedSectionId = cls['sectionId'];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls['subjectName'] ?? '',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isSelected ? Colors.white : AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${cls['levelName']} • ${cls['sectionName']}",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.subtleText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _selectedFileName != null ? AppTheme.primaryColor : AppTheme.borderColor,
            width: _selectedFileName != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedFileName != null
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedFileName != null ? CupertinoIcons.doc_checkmark_fill : CupertinoIcons.cloud_upload_fill,
                color: AppTheme.primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedFileName != null) ...[
              Text(
                _selectedFileName!,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Tap to change file",
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
              ),
            ] else ...[
              Text(
                "Tap to select a file",
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor),
              ),
              const SizedBox(height: 6),
              Text(
                "PDF, DOCX, or PPT up to 10MB",
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAIAnalysisToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.06), AppTheme.primaryColor.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Analyze with AI", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                const SizedBox(height: 2),
                Text("Auto-generate summaries & objectives", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
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
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _handleUpload,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text("Uploading...", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              )
            : Text("Upload & Publish", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
      ),
    );
  }
}
