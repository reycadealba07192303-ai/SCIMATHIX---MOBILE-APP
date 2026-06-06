import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_results_screen.dart';

class QuizProperScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String quizTitle;
  final int timeLimit;
  final int questionsCount;
  final Color themeColor;
  final String? scheduledDate;
  final String? endTime;

  const QuizProperScreen({
    super.key, 
    required this.quizId, 
    required this.quizTitle, 
    required this.timeLimit,
    required this.questionsCount,
    required this.themeColor,
    this.scheduledDate,
    this.endTime,
  });

  @override
  ConsumerState<QuizProperScreen> createState() => _QuizProperScreenState();
}

class _QuizProperScreenState extends ConsumerState<QuizProperScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int _selectedAnswer = -1;
  final TextEditingController _answerController = TextEditingController();
  final List<Map<String, dynamic>> _answers = [];
  
  Timer? _timer;
  late int _remainingSeconds;
  late int _timeLimitMinutes;

  @override
  void initState() {
    super.initState();
    _timeLimitMinutes = widget.timeLimit;
    _remainingSeconds = _timeLimitMinutes * 60;
    _fetchQuizData();
  }

  Future<void> _fetchQuizData() async {
    try {
      final api = ref.read(apiServiceProvider);
      final data = await api.getQuizToTake(widget.quizId);
      
      if (data != null && data['questions'] != null) {
        if (mounted) {
          final loadedTimeLimit = data['timeLimit'];
          setState(() {
            _questions = data['questions'];
            if (loadedTimeLimit is int) {
              _timeLimitMinutes = loadedTimeLimit;
            } else {
              _timeLimitMinutes = int.tryParse(loadedTimeLimit?.toString() ?? '') ?? widget.timeLimit;
            }
            _remainingSeconds = _timeLimitMinutes * 60;
            _isLoading = false;
          });
          _startTimer();
        }
      } else {
        if (mounted) setState(() { _error = "Failed to load questions."; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      bool shouldSubmit = false;

      // Check if time limit reached
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        shouldSubmit = true;
      }

      // Check if global end time reached
      if (!shouldSubmit && widget.scheduledDate != null && widget.endTime != null) {
        try {
          final dateStr = DateTime.parse(widget.scheduledDate!).toIso8601String().split('T')[0];
          final endTimeStr = "$dateStr ${widget.endTime}:00";
          final end = DateTime.parse(endTimeStr.replaceAll(' ', 'T'));
          
          if (DateTime.now().isAfter(end)) {
            shouldSubmit = true;
            // Optionally notify user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Deadline reached. Auto-submitting quiz...")),
              );
            }
          }
        } catch (_) {}
      }

      if (shouldSubmit) {
        timer.cancel();
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
    );

    final api = ref.read(apiServiceProvider);
    final timeTaken = (_timeLimitMinutes * 60) - _remainingSeconds;
    
    final result = await api.submitQuizResults(
      quizId: widget.quizId,
      answers: _answers,
      timeTaken: timeTaken,
    );

    if (mounted) {
      Navigator.pop(context); // close loading
      
      if (result != null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizResultsScreen(
          quizTitle: widget.quizTitle, 
          themeColor: widget.themeColor,
          score: result['score'] ?? 0,
          totalQuestions: result['total'] ?? _questions.length,
          xpEarned: result['xpEarned'] ?? 0,
          results: result['results'] ?? [],
        )));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to submit quiz")));
      }
    }
  }

  void _handleNextOrSubmit() {
    final q = _questions[_currentQuestionIndex];
    final options = (q['options'] as List<dynamic>?) ?? [];
    final isTypedAnswer = q['type'] == 'problem-solving' || options.isEmpty;
    final selectedOption = isTypedAnswer
        ? _answerController.text.trim()
        : options[_selectedAnswer].toString();
    
    _answers.add({
      "questionId": q['_id'],
      "questionText": q['text'] ?? '',
      "chosenAnswer": selectedOption,
      "randomizedValues": q['randomizedValues'] ?? {},
    });

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = -1;
        _answerController.clear();
      });
    } else {
      _submitQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: AppTheme.backgroundColor, body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(backgroundColor: AppTheme.backgroundColor, elevation: 0, leading: IconButton(icon: Icon(CupertinoIcons.clear, color: AppTheme.textColor), onPressed: () => Navigator.pop(context))),
        body: Center(child: Text(_error!, style: GoogleFonts.inter(color: Colors.red))),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(backgroundColor: AppTheme.backgroundColor, elevation: 0, leading: IconButton(icon: Icon(CupertinoIcons.clear, color: AppTheme.textColor), onPressed: () => Navigator.pop(context))),
        body: Center(child: Text("No questions available.", style: GoogleFonts.inter(color: AppTheme.subtleText))),
      );
    }

    final q = _questions[_currentQuestionIndex];
    final options = (q['options'] as List<dynamic>?) ?? [];
    final isTypedAnswer = q['type'] == 'problem-solving' || options.isEmpty;
    final imageUrl = (q['imageUrl'] ?? '').toString();
    final canContinue = isTypedAnswer
        ? _answerController.text.trim().isNotEmpty
        : _selectedAnswer != -1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0,
        leading: IconButton(icon: Icon(CupertinoIcons.clear, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("${_currentQuestionIndex + 1} / ${_questions.length}", style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16), child: Row(children: [
            Icon(CupertinoIcons.timer, color: AppTheme.subtleText, size: 18),
            const SizedBox(width: 4),
            Text(_formattedTime, style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
          ])),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: AppTheme.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
            minHeight: 3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            FadeInDown(
              child: Text(q['text'] ?? '', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textColor, height: 1.4)),
            ),
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('data:')) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            if (isTypedAnswer)
              TextField(
                controller: _answerController,
                keyboardType: TextInputType.text,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Type your answer or final value...",
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.themeColor, width: 2),
                  ),
                ),
              )
            else
              ...List.generate(options.length, (i) {
              final isSelected = _selectedAnswer == i;
              return FadeInUp(
                delay: Duration(milliseconds: 100 * i),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedAnswer = i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? widget.themeColor.withValues(alpha: 0.1) : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? widget.themeColor : AppTheme.borderColor, width: isSelected ? 2 : 1),
                    ),
                    child: Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? widget.themeColor : AppTheme.backgroundColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? widget.themeColor : AppTheme.borderColor),
                        ),
                        child: Center(child: Text(String.fromCharCode(65 + i), style: GoogleFonts.inter(color: isSelected ? Colors.white : AppTheme.subtleText, fontWeight: FontWeight.w600, fontSize: 14))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(options[i].toString(), style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
                    ]),
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: canContinue ? _handleNextOrSubmit : null,
                style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, foregroundColor: Colors.white, disabledBackgroundColor: AppTheme.borderColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: Text(_currentQuestionIndex < _questions.length - 1 ? "Next Question" : "Submit Quiz", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
