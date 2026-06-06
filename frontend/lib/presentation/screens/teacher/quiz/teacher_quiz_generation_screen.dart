import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/teacher/quiz/quiz_preview_screen.dart';

class TeacherQuizGenerationScreen extends ConsumerStatefulWidget {
  const TeacherQuizGenerationScreen({super.key});

  @override
  ConsumerState<TeacherQuizGenerationScreen> createState() => _TeacherQuizGenerationScreenState();
}

class _TeacherQuizGenerationScreenState extends ConsumerState<TeacherQuizGenerationScreen> {
  final Set<String> _quizTypes = {"Multiple Choice"};
  int _questionCount = 10;
  int _timeLimit = 20;
  int _passingScore = 6;
  bool _isPractice = false;
  bool _isGenerating = false;

  // Scheduling
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  TimeOfDay? _endTime;

  // Dynamic lesson selection
  List<dynamic> _lessons = [];
  bool _loadingLessons = true;
  Set<String> _selectedLessonIds = {}; // Store selected lesson IDs

  // Dynamic subject from handled classes
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void initState() {
    super.initState();
    _initSubject();
  }

  void _initSubject() {
    final user = ref.read(authProvider).user;
    if (user?.handledClasses != null && user!.handledClasses!.isNotEmpty) {
      _selectedSubjectId = user.handledClasses!.first.subjectId;
      _selectedSubjectName = user.handledClasses!.first.subjectName;
    }
    // Don't auto-select lessons - let teacher choose
    _selectedLessonIds.clear();
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    setState(() => _loadingLessons = true);
    try {
      final api = ref.read(apiServiceProvider);
      final allLessons = await api.getLessons();
      if (mounted) {
        setState(() {
          _lessons = allLessons.where((l) {
            if (_selectedSubjectId == null) return true;
            final subject = l['subject'];
            if (subject == null) return false;
            final subId = subject is Map ? subject['_id'] : subject;
            return subId == _selectedSubjectId;
          }).toList();
          _loadingLessons = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingLessons = false);
    }
  }

  List<Map<String, String>> _getUniqueSubjects() {
    final user = ref.read(authProvider).user;
    if (user?.handledClasses == null) return [];
    final seen = <String>{};
    return user!.handledClasses!
        .where((hc) => seen.add(hc.subjectId))
        .map((hc) => {'id': hc.subjectId, 'name': hc.subjectName})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _getUniqueSubjects();

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
          "AI Quiz Generator",
          style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.5),
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

            // ─── Subject Selector ─────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 50),
              child: _buildSectionHeader("Subject", CupertinoIcons.book_fill),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _buildSubjectSelector(subjects),
            ),
            const SizedBox(height: 32),

            // ─── Source Lessons ─────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: _buildSectionHeader("Source Lessons (Select one or more)", CupertinoIcons.doc_text_fill),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildLessonSelector(),
            ),
            const SizedBox(height: 32),

            // ─── Configuration ────────────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 250),
              child: _buildSectionHeader("Configuration", CupertinoIcons.slider_horizontal_3),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _buildQuizTypeSelector(),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 325),
              child: _buildQuizModeSelector(),
            ),
            const SizedBox(height: 24),

            // ─── Number of Questions ──────────────────────
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: _buildSectionHeader("Number of Questions", CupertinoIcons.number),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildQuestionCountSelector(),
            ),
            const SizedBox(height: 24),

            // ─── Time Limit ───────────────────────────────
            if (!_isPractice) ...[
              FadeInUp(
                delay: const Duration(milliseconds: 425),
                child: _buildSectionHeader("Time Limit (Minutes)", CupertinoIcons.time),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 450),
                child: _buildTimeLimitSelector(),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 475),
                child: _buildSectionHeader("Passing Score", CupertinoIcons.checkmark_seal_fill),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 485),
                child: _buildPassingScoreSelector(),
              ),
              const SizedBox(height: 48),
            ],

            FadeInUp(
              delay: const Duration(milliseconds: 490),
              child: _buildSectionHeader("Schedule & Deadline (Optional)", CupertinoIcons.calendar_today),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 495),
              child: _buildSchedulingSelector(),
            ),
            const SizedBox(height: 32),

            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildGenerateButton(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF3498DB).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              "Generate Quizzes in Seconds",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "Our AI analyzes your lesson content and creates accurate assessment questions automatically.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white.withOpacity(0.85), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
            ),
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

  Widget _buildSubjectSelector(List<Map<String, String>> subjects) {
    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Center(child: Text("No subjects assigned.", style: GoogleFonts.inter(color: AppTheme.subtleText))),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: subjects.map((s) {
        final isSelected = _selectedSubjectId == s['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubjectId = s['id'];
              _selectedSubjectName = s['name'];
              _selectedLessonIds.clear();
            });
            _fetchLessons();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor, width: isSelected ? 2 : 1),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Text(
              s['name'] ?? '',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected ? Colors.white : AppTheme.textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLessonSelector() {
    if (_loadingLessons) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Center(
          child: Text(
            "No lessons found for ${_selectedSubjectName ?? 'this subject'}.",
            style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 14),
          ),
        ),
      );
    }

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
        children: _lessons.asMap().entries.map((entry) {
          final lesson = entry.value;
          final title = lesson['title'] ?? 'Untitled';
          final isLast = entry.key == _lessons.length - 1;
          final isSelected = _selectedLessonIds.contains(lesson['_id']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedLessonIds.remove(lesson['_id']);
                } else {
                  _selectedLessonIds.add(lesson['_id']);
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.transparent,
                border: !isLast ? Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)) : null,
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(20))
                    : (entry.key == 0 ? const BorderRadius.vertical(top: Radius.circular(20)) : null),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor, width: 2),
                    ),
                    child: isSelected ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuizTypeSelector() {
    return Row(
      children: [
        _buildTypeOption("Multiple Choice", CupertinoIcons.list_bullet),
        const SizedBox(width: 12),
        _buildTypeOption("True/False", CupertinoIcons.checkmark_circle),
        const SizedBox(width: 12),
        _buildTypeOption("Problem Solving", CupertinoIcons.function),
      ],
    );
  }

  Widget _buildQuizModeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          _buildModeOption("Real Quiz", false),
          _buildModeOption("Practice Quiz", true),
        ],
      ),
    );
  }

  Widget _buildModeOption(String label, bool value) {
    final selected = _isPractice == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isPractice = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppTheme.subtleText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, IconData icon) {
    bool isSelected = _quizTypes.contains(label);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected && _quizTypes.length > 1) {
              _quizTypes.remove(label);
            } else {
              _quizTypes.add(label);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.subtleText, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (_questionCount > 5) {
                    setState(() {
                      _questionCount -= 5;
                      if (_passingScore > _questionCount) _passingScore = _questionCount;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Icon(CupertinoIcons.minus, color: AppTheme.textColor, size: 20),
                ),
              ),
              const SizedBox(width: 32),
              Column(
                children: [
                  Text(
                    "$_questionCount",
                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: -1),
                  ),
                  Text("questions", style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () {
                  if (_questionCount < 30) {
                    setState(() {
                      _questionCount += 5;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Icon(CupertinoIcons.plus, color: AppTheme.textColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.borderColor,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.15),
            ),
            child: Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 30,
              divisions: 5,
              onChanged: (val) {
                setState(() {
                  _questionCount = val.toInt();
                  if (_passingScore > _questionCount) _passingScore = _questionCount;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("5", style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
              Text("30", style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLimitSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (_timeLimit > 5) setState(() => _timeLimit -= 5);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Icon(CupertinoIcons.minus, color: AppTheme.textColor, size: 20),
                ),
              ),
              const SizedBox(width: 32),
              Column(
                children: [
                  Text(
                    "$_timeLimit",
                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: -1),
                  ),
                  Text("minutes", style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () {
                  if (_timeLimit < 60) setState(() => _timeLimit += 5);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Icon(CupertinoIcons.plus, color: AppTheme.textColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.borderColor,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.15),
            ),
            child: Slider(
              value: _timeLimit.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              onChanged: (val) => setState(() => _timeLimit = val.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("5", style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
              Text("60", style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassingScoreSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (_passingScore > 1) setState(() => _passingScore -= 1);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Icon(CupertinoIcons.minus, color: AppTheme.textColor, size: 20),
                ),
              ),
              const SizedBox(width: 32),
              Column(
                children: [
                  Text(
                    "$_passingScore",
                    style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: -1),
                  ),
                  Text("points to pass", style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: () {
                  if (_passingScore < _questionCount) setState(() => _passingScore += 1);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Icon(CupertinoIcons.plus, color: AppTheme.textColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: AppTheme.borderColor,
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.15),
            ),
            child: Slider(
              value: _passingScore.toDouble(),
              min: 1,
              max: _questionCount > 0 ? _questionCount.toDouble() : 1,
              divisions: _questionCount > 1 ? _questionCount - 1 : 1,
              onChanged: (val) => setState(() => _passingScore = val.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("1", style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
              Text("$_questionCount", style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _handleGenerate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text("AI is generating questions...", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text("Generate Quiz with AI", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                ],
              ),
      ),
    );
  }

  void _handleGenerate() async {
    if (_selectedLessonIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please select at least one lesson first.", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final api = ref.read(apiServiceProvider);
      String? formatTime(TimeOfDay? time) {
        if (time == null) return null;
        final h = time.hour.toString().padLeft(2, '0');
        final m = time.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }

      final result = await api.generateQuiz(
        lessonId: _selectedLessonIds.first, // Pass first lesson ID for backward compatibility
        lessonIds: _selectedLessonIds.toList(), // Pass all selected lesson IDs
        count: _questionCount,
        types: _quizTypes.toList(),
        isPractice: _isPractice,
        timeLimit: _isPractice ? 0 : _timeLimit,
        passingScore: _isPractice ? 0 : _passingScore,
        scheduledDate: _scheduledDate?.toIso8601String(),
        scheduledTime: formatTime(_scheduledTime),
        endTime: formatTime(_endTime),
      );
      
      if (mounted) {
        setState(() => _isGenerating = false);
        if (result != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QuizPreviewScreen(
              quizData: result,
              lessonId: _selectedLessonIds.isNotEmpty ? _selectedLessonIds.first : null,
              lessonIds: _selectedLessonIds.toList(),
              count: _questionCount,
              quizTypes: _quizTypes.toList(),
              isPractice: _isPractice,
              timeLimit: _isPractice ? 0 : _timeLimit,
              passingScore: _isPractice ? 0 : _passingScore,
              scheduledDate: _scheduledDate?.toIso8601String(),
              scheduledTime: formatTime(_scheduledTime),
              endTime: formatTime(_endTime),
            )),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Failed to generate quiz.", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_friendlyError(e), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Widget _buildSchedulingSelector() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildDateTimePickerRow(
            label: "Quiz Date",
            valueText: _scheduledDate != null ? "${_scheduledDate!.month}/${_scheduledDate!.day}/${_scheduledDate!.year}" : "Not Set",
            icon: CupertinoIcons.calendar,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _scheduledDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _scheduledDate = date);
            },
          ),
          const Divider(height: 32),
          _buildDateTimePickerRow(
            label: "Start Time",
            valueText: _scheduledTime != null ? _scheduledTime!.format(context) : "Not Set",
            icon: CupertinoIcons.time,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _scheduledTime ?? TimeOfDay.now(),
              );
              if (time != null) setState(() => _scheduledTime = time);
            },
          ),
          const Divider(height: 32),
          _buildDateTimePickerRow(
            label: "End Time",
            valueText: _endTime != null ? _endTime!.format(context) : "Not Set",
            icon: CupertinoIcons.time_solid,
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _endTime ?? TimeOfDay.now(),
              );
              if (time != null) setState(() => _endTime = time);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickerRow({required String label, required String valueText, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textColor))),
          Text(valueText, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: valueText == "Not Set" ? AppTheme.subtleText : AppTheme.primaryColor)),
          const SizedBox(width: 8),
          Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.subtleText),
        ],
      ),
    );
  }
}
