import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/teacher/quiz/quiz_preview_screen.dart';

class TeacherQuizGenerationScreen extends StatefulWidget {
  const TeacherQuizGenerationScreen({super.key});

  @override
  State<TeacherQuizGenerationScreen> createState() => _TeacherQuizGenerationScreenState();
}

class _TeacherQuizGenerationScreenState extends State<TeacherQuizGenerationScreen> {
  String _selectedLesson = "Algebra Fundamentals";
  String _quizType = "Multiple Choice";
  int _questionCount = 10;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "AI Quiz Generator",
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
            _buildInfoCard(),
            const SizedBox(height: 32),
            _buildSectionLabel("Source Lesson"),
            const SizedBox(height: 12),
            _buildLessonSelector(),
            const SizedBox(height: 32),
            _buildSectionLabel("Configuration"),
            const SizedBox(height: 16),
            _buildQuizTypeSelector(),
            const SizedBox(height: 24),
            _buildQuestionCountSelector(),
            const SizedBox(height: 48),
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFF6366F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 32),
            const SizedBox(height: 16),
            Text(
              "Generate Quizzes in Seconds",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Our AI will analyze your lesson content and create accurate assessment questions automatically.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.5,
              ),
            ),
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

  Widget _buildLessonSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Selected Lesson", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                Text(_selectedLesson, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_down, color: AppTheme.subtleText, size: 16),
        ],
      ),
    );
  }

  Widget _buildQuizTypeSelector() {
    return Row(
      children: [
        _buildTypeOption("Multiple Choice", CupertinoIcons.list_bullet),
        const SizedBox(width: 12),
        _buildTypeOption("True/False", CupertinoIcons.check_mark_circled),
      ],
    );
  }

  Widget _buildTypeOption(String label, IconData icon) {
    bool isSelected = _quizType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _quizType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.subtleText, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.subtleText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Number of Questions", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.subtleText)),
            Text("$_questionCount", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
          ],
        ),
        Slider(
          value: _questionCount.toDouble(),
          min: 5,
          max: 20,
          divisions: 3,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.borderColor,
          onChanged: (val) => setState(() => _questionCount = val.toInt()),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return FadeInUp(
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isGenerating ? null : _handleGenerate,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          ),
          child: _isGenerating
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text("AI is generating questions..."),
                  ],
                )
              : const Text("Generate Quiz with AI"),
        ),
      ),
    );
  }

  void _handleGenerate() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isGenerating = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QuizPreviewScreen()),
      );
    }
  }
}
