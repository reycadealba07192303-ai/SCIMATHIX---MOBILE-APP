import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class QuizPreviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> quizData;
  final String? lessonId; // For backward compatibility
  final List<String>? lessonIds; // New: multiple lesson IDs
  final int count;
  final List<String> quizTypes;
  final bool isPractice;
  final int timeLimit;
  final int? passingScore;
  final String? scheduledDate;
  final String? scheduledTime;
  final String? endTime;

  const QuizPreviewScreen({
    super.key,
    required this.quizData,
    this.lessonId,
    this.lessonIds,
    required this.count,
    this.quizTypes = const ["Multiple Choice"],
    this.isPractice = false,
    this.timeLimit = 0,
    this.passingScore,
    this.scheduledDate,
    this.scheduledTime,
    this.endTime,
  });

  @override
  ConsumerState<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends ConsumerState<QuizPreviewScreen> {
  late Map<String, dynamic> _currentQuizData;
  bool _isRegenerating = false;
  bool _isSaving = false;

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void initState() {
    super.initState();
    _currentQuizData = widget.quizData;
  }

  Future<void> _handleRegenerate() async {
    setState(() => _isRegenerating = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final oldQuizId = _currentQuizData['quiz']['_id'];

      // Generate new quiz - support both single and multiple lesson IDs for backward compatibility
      final result = await api.generateQuiz(
        lessonId: widget.lessonId,
        lessonIds: widget.lessonIds,
        count: widget.count,
        types: widget.quizTypes,
        isPractice: widget.isPractice,
        timeLimit: widget.timeLimit,
        passingScore: widget.passingScore,
        scheduledDate: widget.scheduledDate,
        scheduledTime: widget.scheduledTime,
        endTime: widget.endTime,
      );

      if (mounted) {
        if (result != null) {
          await api.deleteQuiz(oldQuizId);
          if (!mounted) return;
          setState(() {
            _currentQuizData = result;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Quiz regenerated successfully!"),
            backgroundColor: AppTheme.primaryColor,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to regenerate quiz."),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    // Since it's already saved in the DB by createAIQuiz, "Save" just means we keep it and go back!
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Quiz saved successfully!"),
        backgroundColor: AppTheme.primaryColor,
      ));
      // Pop twice to go back to classroom screen
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  Future<void> _handleDiscard() async {
    // Delete the quiz and go back
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.deleteQuiz(_currentQuizData['quiz']['_id']);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context); // Go back to generation screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = _currentQuizData['questions'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
          onPressed: _isSaving || _isRegenerating ? null : _handleDiscard,
        ),
        title: Text(
          "Preview Quiz",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          _isRegenerating
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : TextButton(
                onPressed: _handleRegenerate,
                child: Text(
                  "Regenerate",
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                return _buildQuestionCard(index + 1, q);
              },
            ),
          ),
          _buildActionFooter(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, dynamic q) {
    final questionText = q['baseQuestion'] ?? 'Unknown Question';
    final optionsTemplate = q['optionsTemplate'] as List<dynamic>? ?? [];
    final correctTemplate = q['correctAnswerTemplate'] ?? '';
    final imageUrl = (q['imageUrl'] ?? '').toString();
    final steps = q['solutionSteps'] as List<dynamic>? ?? [];

    return FadeInUp(
      key: ValueKey('${_currentQuizData['quiz']['_id']}_$index'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Q$index",
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              questionText,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
                height: 1.4,
              ),
            ),
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('data:')) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (optionsTemplate.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Text(
                  "Answer: $correctTemplate",
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w700),
                ),
              )
            else
              ...List.generate(optionsTemplate.length, (i) {
              final optionText = optionsTemplate[i].toString();
              bool isCorrect = optionText == correctTemplate;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.withValues(alpha: 0.05) : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCorrect ? Colors.green.withValues(alpha: 0.2) : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + i),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isCorrect ? Colors.green : AppTheme.subtleText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 16),
                  ],
                ),
              );
            }),
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text("Solving steps", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
              const SizedBox(height: 6),
              ...steps.asMap().entries.map((entry) => Text(
                "${entry.key + 1}. ${entry.value}",
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, height: 1.4),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving || _isRegenerating ? null : _handleDiscard,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Discard", style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving || _isRegenerating ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Save & Assign to Section", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
