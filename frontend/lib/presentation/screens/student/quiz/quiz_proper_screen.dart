import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_results_screen.dart';

class QuizProperScreen extends StatefulWidget {
  final String quizTitle;
  final Color themeColor;
  const QuizProperScreen({super.key, required this.quizTitle, required this.themeColor});

  @override
  State<QuizProperScreen> createState() => _QuizProperScreenState();
}

class _QuizProperScreenState extends State<QuizProperScreen> {
  int _currentQuestion = 0;
  int _selectedAnswer = -1;
  final int _totalQuestions = 5;
  int _score = 0;
  final List<dynamic> _results = [];

  final List<Map<String, dynamic>> _questions = [
    {"q": "What is the value of x if 2x + 5 = 15?", "options": ["x = 3", "x = 5", "x = 7", "x = 10"], "correct": 1},
    {"q": "What is the square root of 144?", "options": ["10", "11", "12", "14"], "correct": 2},
    {"q": "Which is the powerhouse of the cell?", "options": ["Nucleus", "Ribosome", "Mitochondria", "Golgi Body"], "correct": 2},
    {"q": "What is Newton's second law?", "options": ["F = ma", "E = mc²", "V = IR", "P = IV"], "correct": 0},
    {"q": "What is the chemical symbol for Gold?", "options": ["Go", "Gd", "Au", "Ag"], "correct": 2},
  ];

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentQuestion];
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, elevation: 0,
        leading: IconButton(icon: const Icon(CupertinoIcons.clear, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("${_currentQuestion + 1} / $_totalQuestions", style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w600, fontSize: 16)),
        centerTitle: true,
        actions: [
          Padding(padding: const EdgeInsets.only(right: 16), child: Row(children: [
            const Icon(CupertinoIcons.timer, color: AppTheme.subtleText, size: 18),
            const SizedBox(width: 4),
            Text("28:45", style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
          ])),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentQuestion + 1) / _totalQuestions,
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
              child: Text(q["q"], style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textColor, height: 1.4)),
            ),
            const SizedBox(height: 32),
            ...List.generate(q["options"].length, (i) {
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
                      Expanded(child: Text(q["options"][i], style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
                    ]),
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _selectedAnswer == -1 ? null : () {
                  final isCorrect = _selectedAnswer == q["correct"];
                  if (isCorrect) _score++;
                  _results.add({
                    "question": q["q"],
                    "isCorrect": isCorrect,
                    "selected": q["options"][_selectedAnswer],
                    "correct": q["options"][q["correct"]],
                  });

                  if (_currentQuestion < _totalQuestions - 1) {
                    setState(() { _currentQuestion++; _selectedAnswer = -1; });
                  } else {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizResultsScreen(
                      quizTitle: widget.quizTitle, 
                      themeColor: widget.themeColor,
                      score: _score,
                      totalQuestions: _totalQuestions,
                      xpEarned: _score * 10,
                      results: _results,
                    )));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor, foregroundColor: Colors.white, disabledBackgroundColor: AppTheme.borderColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: Text(_currentQuestion < _totalQuestions - 1 ? "Next Question" : "Submit Quiz", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
