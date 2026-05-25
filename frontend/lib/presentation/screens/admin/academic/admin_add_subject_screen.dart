import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AdminAddSubjectScreen extends ConsumerStatefulWidget {
  const AdminAddSubjectScreen({super.key});

  @override
  ConsumerState<AdminAddSubjectScreen> createState() => _AdminAddSubjectScreenState();
}

class _AdminAddSubjectScreenState extends ConsumerState<AdminAddSubjectScreen> {
  String _selectedCategory = 'Mathematics';
  bool _isSubmitting = false;

  List<dynamic> _levels = [];
  List<dynamic> _sections = [];
  String? _selectedLevelId;
  String? _selectedSectionId;
  bool _isLoadingLevels = true;

  @override
  void initState() {
    super.initState();
    _fetchLevels();
  }

  Future<void> _fetchLevels() async {
    final apiService = ref.read(apiServiceProvider);
    final levels = await apiService.getLevels();
    if (mounted) {
      setState(() {
        _levels = levels;
        _isLoadingLevels = false;
      });
    }
  }

  Future<void> _fetchSections(String levelId) async {
    final apiService = ref.read(apiServiceProvider);
    final sections = await apiService.getSections(levelId);
    if (mounted) {
      setState(() {
        _sections = sections;
        _selectedSectionId = null;
      });
    }
  }

  Future<void> _handleCreate() async {
    if (_selectedLevelId == null || _selectedSectionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Level and Section.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final selectedLevel = _levels.firstWhere((l) => l['_id'] == _selectedLevelId);
      final selectedSection = _sections.firstWhere((s) => s['_id'] == _selectedSectionId);

      String levelName = selectedLevel['name']; // e.g. "Grade 7"
      String sectionName = selectedSection['name']; // e.g. "Section A" or "A"

      String gradeNumber = levelName.replaceAll(RegExp(r'[^0-9]'), '');
      if (gradeNumber.isEmpty) gradeNumber = "1";

      String sectionLetter = sectionName.replaceAll(RegExp(r'(Section|Grade|\s)'), '');
      if (sectionLetter.isEmpty) sectionLetter = "A";

      String generatedName = "$_selectedCategory $gradeNumber";
      String prefix = _selectedCategory == 'Mathematics' ? 'MATH' : 'SCI';
      String generatedCode = "$prefix$gradeNumber-$sectionLetter";

      final apiService = ref.read(apiServiceProvider);
      await apiService.createSubject(generatedName, generatedCode, _selectedCategory, sectionId: _selectedSectionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Subject '$generatedName' ($generatedCode) created!"), 
            backgroundColor: Colors.green
          ),
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
          "Auto-Create Subject",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingLevels
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Text(
                      "Subject Management",
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
                      "Select a Level, Section, and Role. The system will automatically generate the Subject Name and Code.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.subtleText,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  _buildSectionLabel("Target Assignment"),
                  const SizedBox(height: 16),
                  
                  _buildDropdown<String>(
                    value: _selectedLevelId,
                    hint: "Select Level",
                    icon: CupertinoIcons.layers,
                    items: _levels.map((level) {
                      return DropdownMenuItem<String>(
                        value: level['_id'],
                        child: Text(level['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLevelId = value;
                        _fetchSections(value!);
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  _buildDropdown<String>(
                    value: _selectedSectionId,
                    hint: "Select Section",
                    icon: CupertinoIcons.group,
                    items: _sections.map((section) {
                      return DropdownMenuItem<String>(
                        value: section['_id'],
                        child: Text(section['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSectionId = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildCategoryDropdown(),
                  
                  const SizedBox(height: 64),
                  _buildSubmitButton(),
                ],
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

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(hint, style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 14)),
                isExpanded: true,
                dropdownColor: AppTheme.surfaceColor,
                icon: const Icon(CupertinoIcons.chevron_down, color: AppTheme.primaryColor),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(CupertinoIcons.book, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceColor,
                icon: const Icon(CupertinoIcons.chevron_down, color: AppTheme.primaryColor),
                items: ['Mathematics', 'Science'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    if (newValue != null) _selectedCategory = newValue;
                  });
                },
              ),
            ),
          ),
        ],
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
                "Auto Create Subject",
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
