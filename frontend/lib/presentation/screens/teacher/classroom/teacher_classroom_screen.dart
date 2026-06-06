import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/models/user_model.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/data/services/socket_service.dart';
import 'package:scimathix/presentation/screens/teacher/lessons/upload_lesson_screen.dart';
import 'package:scimathix/presentation/screens/teacher/quiz/teacher_quiz_generation_screen.dart';
import 'package:scimathix/presentation/screens/teacher/quiz/teacher_quiz_results_screen.dart';
import 'package:scimathix/presentation/screens/teacher/classroom/student_chat_screen.dart';
import 'package:scimathix/presentation/screens/student/lessons/lesson_details_screen.dart';

class TeacherClassroomScreen extends ConsumerStatefulWidget {
  final HandledClassModel handledClass;

  const TeacherClassroomScreen({super.key, required this.handledClass});

  @override
  ConsumerState<TeacherClassroomScreen> createState() => _TeacherClassroomScreenState();
}

class _TeacherClassroomScreenState extends ConsumerState<TeacherClassroomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final SocketService _socketService;
  List<dynamic> _students = [];
  List<dynamic> _streamPosts = [];
  List<dynamic> _lessons = [];
  List<dynamic> _quizzes = [];
  bool _loadingStudents = true;
  bool _loadingStream = true;
  bool _loadingLessons = true;
  bool _loadingQuizzes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchStudents();
    _fetchStream();
    _fetchLessons();
    _fetchQuizzes();
    _socketService = ref.read(socketServiceProvider);
    _socketService.initSocket();
    _socketService.on('classroom_updated', _handleClassroomUpdate);
    _socketService.on('academic_updated', _handleClassroomUpdate);
  }

  void _handleClassroomUpdate(dynamic data) {
    if (data is Map) {
      final sectionId = data['sectionId']?.toString();
      final subjectId = data['subjectId']?.toString();
      if (sectionId != null && sectionId != widget.handledClass.sectionId) return;
      if (subjectId != null && subjectId != widget.handledClass.subjectId) return;
    }

    _fetchStudents();
    _fetchStream();
    _fetchLessons();
    _fetchQuizzes();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final details = await ref.read(apiServiceProvider).getSectionDetails(widget.handledClass.sectionId);
      if (details != null && mounted) {
        setState(() {
          _students = details['students'] ?? [];
          _loadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _fetchStream() async {
    setState(() => _loadingStream = true);
    try {
      final api = ref.read(apiServiceProvider);
      final posts = await api.getClassroomFeed(
        widget.handledClass.sectionId,
        subjectId: widget.handledClass.subjectId,
      );
      if (mounted) {
        setState(() {
          _streamPosts = posts.where((p) => p['feedType'] == 'announcement').toList();
          _loadingStream = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStream = false);
    }
  }

  Future<void> _fetchLessons() async {
    setState(() => _loadingLessons = true);
    try {
      final api = ref.read(apiServiceProvider);
      final lessons = await api.getLessons();
      if (mounted) {
        setState(() {
          _lessons = lessons.where((l) {
            final subject = l['subject'];
            if (subject == null) return false;
            final subId = subject is Map ? subject['_id'] : subject;
            return subId == widget.handledClass.subjectId;
          }).toList();
          _loadingLessons = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingLessons = false);
    }
  }

  Future<void> _fetchQuizzes() async {
    setState(() => _loadingQuizzes = true);
    try {
      final api = ref.read(apiServiceProvider);
      final quizzes = await api.getQuizzes();
      if (mounted) {
        setState(() {
          _quizzes = quizzes.where((q) {
            final lesson = q['lesson'];
            if (lesson == null) return false;
            final subject = lesson['subject'];
            if (subject == null) return false;
            final subId = subject is Map ? subject['_id'] : subject;
            return subId == widget.handledClass.subjectId;
          }).toList();
          _loadingQuizzes = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingQuizzes = false);
    }
  }

  Future<void> _handleEditAnnouncement(Map<String, dynamic> post) async {
    final TextEditingController _editController = TextEditingController(text: post['content'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text("Edit Announcement", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: _editController,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.subtleText))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context, _editController.text),
            child: Text("Save", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.updateAnnouncement(post['_id'], result);
        _fetchStream();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _handleDeleteAnnouncement(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Announcement", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text("Are you sure you want to delete this announcement?", style: GoogleFonts.inter()),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Delete", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final api = ref.read(apiServiceProvider);
        await api.deleteAnnouncement(postId);
        _fetchStream();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, Color(0xFF1ABC9C)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                              CupertinoIcons.bubble_left_bubble_right_fill,
                              color: Colors.white,
                              size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "New Announcement",
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Title field
                    _buildSheetField(
                      controller: titleController,
                      hint: "Title",
                      maxLines: 1,
                    ),
                    const SizedBox(height: 12),
                    // Date + Time row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: sheetContext,
                                initialDate: selectedDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            child: _buildSheetChip(
                              icon: CupertinoIcons.calendar,
                              label: selectedDate == null
                                  ? "Date"
                                  : "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                              hasValue: selectedDate != null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: sheetContext,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedTime = picked);
                              }
                            },
                            child: _buildSheetChip(
                              icon: CupertinoIcons.clock,
                              label: selectedTime == null
                                  ? "Time"
                                  : selectedTime!.format(sheetContext),
                              hasValue: selectedTime != null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Section chip (read-only)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.person_2_fill,
                              color: AppTheme.subtleText, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Section: ${widget.handledClass.sectionName}",
                            style: GoogleFonts.inter(
                                color: AppTheme.subtleText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Details field
                    _buildSheetField(
                      controller: detailsController,
                      hint: "Details — what do you want to tell your class?",
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppTheme.borderColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => Navigator.pop(sheetContext),
                            child: Text("Cancel",
                                style: GoogleFonts.inter(
                                    color: AppTheme.textColor,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () async {
                              final titleText = titleController.text.trim();
                              final detailsText = detailsController.text.trim();
                              if (titleText.isEmpty || detailsText.isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                      content: Text("Title and details are required.")),
                                );
                                return;
                              }
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text("Posting announcement...",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600)),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ));

                              String? timeStr;
                              if (selectedTime != null) {
                                final h = selectedTime!.hour
                                    .toString()
                                    .padLeft(2, '0');
                                final m = selectedTime!.minute
                                    .toString()
                                    .padLeft(2, '0');
                                timeStr = '$h:$m';
                              }

                              await ref.read(apiServiceProvider).createAnnouncement(
                                widget.handledClass.sectionId,
                                detailsText,
                                subjectId: widget.handledClass.subjectId,
                                title: titleText,
                                scheduledDate: selectedDate,
                                scheduledTime: timeStr,
                              );

                              _fetchStream();
                            },
                            child: Text("Post Announcement",
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.inter(
            color: AppTheme.textColor, fontSize: 15, height: 1.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppTheme.subtleText),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSheetChip({
    required IconData icon,
    required String label,
    required bool hasValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasValue
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hasValue ? AppTheme.primaryColor : AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: hasValue ? AppTheme.primaryColor : AppTheme.subtleText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: hasValue ? AppTheme.primaryColor : AppTheme.subtleText,
                fontSize: 13,
                fontWeight:
                    hasValue ? FontWeight.w600 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socketService.off('classroom_updated', _handleClassroomUpdate);
    _socketService.off('academic_updated', _handleClassroomUpdate);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showEditQuizDialog(Map<String, dynamic> quiz) async {
    final titleController = TextEditingController(text: (quiz['title'] ?? '').toString());
    bool isPractice = quiz['isPractice'] == true;
    final int questionsCount = (quiz['questions'] as List?)?.length ?? 10;
    
    int timeLimit = quiz['timeLimit'] ?? 20;
    int passingScore = quiz['passingScore'] ?? 0;
    
    // If the database has a percentage (e.g. 60), convert it to raw score based on items
    if (passingScore > questionsCount) {
      passingScore = (questionsCount * (passingScore / 100)).round();
    }
    if (passingScore > questionsCount) passingScore = questionsCount;
    if (passingScore < 0) passingScore = 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: Text("Edit Quiz", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Quiz title"),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isPractice,
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppTheme.primaryColor,
                      title: Text("Practice Quiz", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      subtitle: Text("Practice quizzes do not award XP.", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                      onChanged: (value) => setDialogState(() => isPractice = value),
                    ),
                    if (!isPractice) ...[
                      const SizedBox(height: 24),
                      Text("Time limit: $timeLimit minutes", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppTheme.primaryColor,
                          inactiveTrackColor: AppTheme.borderColor,
                          thumbColor: AppTheme.primaryColor,
                          overlayColor: AppTheme.primaryColor.withOpacity(0.15),
                        ),
                        child: Slider(
                          value: timeLimit.toDouble(),
                          min: 5,
                          max: 60,
                          divisions: 11,
                          onChanged: (val) => setDialogState(() => timeLimit = val.toInt()),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Passing score: $passingScore / $questionsCount", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppTheme.primaryColor,
                          inactiveTrackColor: AppTheme.borderColor,
                          thumbColor: AppTheme.primaryColor,
                          overlayColor: AppTheme.primaryColor.withOpacity(0.15),
                        ),
                        child: Slider(
                          value: passingScore.toDouble(),
                          min: 1,
                          max: questionsCount > 0 ? questionsCount.toDouble() : 1,
                          divisions: questionsCount > 1 ? questionsCount - 1 : 1,
                          onChanged: (val) => setDialogState(() => passingScore = val.toInt()),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w700)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  child: Text("Save", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final title = titleController.text.trim();
    if (title.isEmpty) return;

    final updated = await ref.read(apiServiceProvider).updateQuiz(quiz['_id'], {
      'title': title,
      'isPractice': isPractice,
      'timeLimit': isPractice ? 0 : timeLimit,
      'passingScore': isPractice ? 0 : passingScore,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(updated != null ? "Quiz updated." : "Failed to update quiz."),
      backgroundColor: updated != null ? AppTheme.primaryColor : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
    if (updated != null) _fetchQuizzes();
  }

  Future<void> _confirmDeleteQuiz(Map<String, dynamic> quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text("Delete Quiz", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        content: Text(
          "Delete \"${quiz['title'] ?? 'this quiz'}\"? Students will no longer see it.",
          style: GoogleFonts.inter(color: AppTheme.subtleText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await ref.read(apiServiceProvider).deleteQuiz(quiz['_id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? "Quiz deleted." : "Failed to delete quiz."),
      backgroundColor: ok ? AppTheme.primaryColor : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) _fetchQuizzes();
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadLessonScreen()),
          );
          _fetchLessons();
          _fetchStream();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: Text("Upload Lesson", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      );
    } else if (_tabController.index == 2) {
      return FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeacherQuizGenerationScreen()),
          );
        },
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(CupertinoIcons.sparkles, color: Colors.white),
        label: Text("AI Generate Quiz", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: _buildFloatingActionButton(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(CupertinoIcons.book_fill, size: 200, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 100,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.star_fill, color: Colors.white, size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  widget.handledClass.levelName,
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.handledClass.subjectName,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.group_solid, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Section ${widget.handledClass.sectionName}",
                                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(74),
              child: Container(
                height: 74,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: Center(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      dividerHeight: 0,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF0EA5E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.subtleText,
                      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                      labelPadding: EdgeInsets.zero,
                      tabs: [
                        const Tab(text: "Stream"),
                        const Tab(text: "Lessons"),
                        const Tab(text: "Quizzes"),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Students"),
                              if (!_loadingStudents && _students.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _tabController.index == 3 
                                        ? Colors.white.withOpacity(0.2) 
                                        : AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${_students.length}",
                                    style: GoogleFonts.inter(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.w900, 
                                      color: _tabController.index == 3 
                                          ? Colors.white 
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStreamTab(),
                _buildLessonsTab(),
                _buildQuizzesTab(),
                _buildStudentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamTab() {
    final user = ref.watch(authProvider).user;
    
    return RefreshIndicator(
      onRefresh: _fetchStream,
      color: AppTheme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInDown(
            child: GestureDetector(
              onTap: _showCreatePostDialog,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryColor.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))
                  ]
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF1ABC9C)]),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.surfaceColor,
                        child: Text(
                          (user?.name ?? '').isNotEmpty ? user!.name[0].toUpperCase() : 'T',
                          style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "Announce something to your class...",
                        style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.paperplane_fill, color: AppTheme.primaryColor, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          if (_loadingStream)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ))
          else if (_streamPosts.isEmpty)
            FadeInUp(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Icon(CupertinoIcons.bubble_left_bubble_right, size: 48, color: AppTheme.subtleText.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 24),
                      Text("No announcements yet", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textColor)),
                      const SizedBox(height: 8),
                      Text("Start the conversation by posting an update.", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText)),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._streamPosts.map((post) {
              return FadeInUp(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            child: const Icon(CupertinoIcons.person_solid, color: AppTheme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? "Teacher", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textColor, letterSpacing: -0.3)),
                                Text(_formatDate(post['createdAt']), style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          if (post['feedType'] == 'announcement')
                            PopupMenuButton<String>(
                              icon: Icon(CupertinoIcons.ellipsis, color: AppTheme.subtleText, size: 20),
                              color: AppTheme.surfaceColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _handleEditAnnouncement(post);
                                } else if (value == 'delete') {
                                  _handleDeleteAnnouncement(post['_id']);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(CupertinoIcons.pencil, size: 18, color: AppTheme.textColor),
                                    const SizedBox(width: 8),
                                    Text("Edit", style: GoogleFonts.inter(color: AppTheme.textColor)),
                                  ]),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Text("Delete", style: GoogleFonts.inter(color: Colors.redAccent)),
                                  ]),
                                ),
                              ],
                            )
                          else
                            Icon(CupertinoIcons.ellipsis, color: AppTheme.subtleText, size: 20),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: AppTheme.borderColor, height: 1),
                      ),
                      // Title (if present)
                      if ((post['title'] ?? '').toString().trim().isNotEmpty) ...[
                        Text(
                          post['title'].toString(),
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor,
                              letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 6),
                      ],
                      // Scheduled date/time chips
                      if (post['scheduledDate'] != null) ...[
                        Row(
                          children: [
                            _buildInfoChip(
                              CupertinoIcons.calendar,
                              _formatScheduledDate(post['scheduledDate']),
                            ),
                            if ((post['scheduledTime'] ?? '').toString().trim().isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                CupertinoIcons.clock,
                                post['scheduledTime'].toString(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        post['content'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 15, color: AppTheme.textColor, height: 1.6),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return "${date.month}/${date.day}/${date.year} • ${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {
      return '';
    }
  }

  String _formatScheduledDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final date = DateTime.parse(raw.toString()).toLocal();
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEditLesson(Map<String, dynamic> lesson) async {
    final titleController = TextEditingController(text: (lesson['title'] ?? '').toString());
    final contentController = TextEditingController(text: (lesson['content'] ?? '').toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Lesson", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Lesson title"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: "Content (editing re-runs AI analysis)",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Save", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (saved != true) return;
    final title = titleController.text.trim();
    if (title.isEmpty) return;

    final body = <String, dynamic>{'title': title};
    final content = contentController.text.trim();
    if (content.isNotEmpty && content != (lesson['content'] ?? '').toString()) {
      body['content'] = content;
    }

    final ok = await ref.read(apiServiceProvider).updateLesson(lesson['_id'], body);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? "Lesson updated." : "Failed to update lesson."),
      backgroundColor: ok ? AppTheme.primaryColor : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) {
      _fetchLessons();
      _fetchStream();
    }
  }

  Future<void> _handleDeleteLesson(Map<String, dynamic> lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Lesson", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        content: Text(
          "Delete \"${lesson['title'] ?? 'this lesson'}\"? Its practice quizzes will also be removed.",
          style: GoogleFonts.inter(color: AppTheme.subtleText),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancel", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Delete", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await ref.read(apiServiceProvider).deleteLesson(lesson['_id']);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? "Lesson deleted." : "Failed to delete lesson."),
      backgroundColor: ok ? AppTheme.primaryColor : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
    if (ok) {
      _fetchLessons();
      _fetchStream();
      _fetchQuizzes();
    }
  }

  Widget _buildLessonsTab() {
    if (_loadingLessons) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_lessons.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.book_solid,
        title: "No Lessons Found",
        subtitle: "There are no lessons available for ${widget.handledClass.subjectName}."
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLessons,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final lesson = _lessons[index];
          final title = lesson['title'] ?? 'Untitled Lesson';
          final isPublished = lesson['isPublished'] ?? true;
          
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonDetailsScreen(
                      lessonTitle: title,
                      themeColor: AppTheme.primaryColor,
                      lessonId: lesson['_id'],
                      content: lesson['content'],
                      summary: lesson['summary'],
                      objectives: lesson['objectives'],
                      fileUrl: lesson['fileUrl'],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor.withOpacity(0.15), AppTheme.primaryColor.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(CupertinoIcons.doc_text_fill, color: AppTheme.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textColor, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Text(
                                widget.handledClass.levelName,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.subtleText),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPublished ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPublished ? "Published" : "Draft",
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isPublished ? Colors.green : Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(CupertinoIcons.ellipsis_vertical, color: AppTheme.textColor, size: 16),
                      color: AppTheme.surfaceColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') {
                          _handleEditLesson(lesson);
                        } else if (value == 'delete') {
                          _handleDeleteLesson(lesson);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(CupertinoIcons.pencil, size: 18, color: AppTheme.textColor),
                            const SizedBox(width: 8),
                            Text("Edit", style: GoogleFonts.inter(color: AppTheme.textColor)),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            const Icon(CupertinoIcons.trash, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text("Delete", style: GoogleFonts.inter(color: Colors.redAccent)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizzesTab() {
    if (_loadingQuizzes) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_quizzes.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.question_diamond_fill,
        title: "No Quizzes Found",
        subtitle: "There are no quizzes available for ${widget.handledClass.subjectName}."
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchQuizzes,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          final title = quiz['title'] ?? 'Untitled Quiz';
          final questionsCount = (quiz['questions'] as List?)?.length ?? 0;
          final isPractice = quiz['isPractice'] == true;
          
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherQuizResultsScreen(
                      quizId: quiz['_id'],
                      quizTitle: title,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentColor.withOpacity(0.15), AppTheme.accentColor.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(CupertinoIcons.pencil_outline, color: AppTheme.accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textColor, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.list_number, size: 12, color: AppTheme.subtleText),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$questionsCount Questions",
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.subtleText),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPractice ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isPractice ? "Practice" : "Real Quiz",
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isPractice ? AppTheme.primaryColor : AppTheme.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(CupertinoIcons.ellipsis_vertical, color: AppTheme.subtleText, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditQuizDialog(Map<String, dynamic>.from(quiz));
                      } else if (value == 'delete') {
                        _confirmDeleteQuiz(Map<String, dynamic>.from(quiz));
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.pencil, size: 18, color: AppTheme.textColor),
                            const SizedBox(width: 10),
                            Text("Edit", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.delete, size: 18, color: Colors.redAccent),
                            const SizedBox(width: 10),
                            Text("Delete", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_students.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.person_3_fill,
        title: "No Students Yet",
        subtitle: "There are no students enrolled in this section."
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStudents,
      color: AppTheme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInDown(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.group_solid, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Enrolled Students",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textColor, letterSpacing: -0.5),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    "${_students.length} Total",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.subtleText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._students.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            final name = student['name'] ?? 'Unknown';
            final email = student['email'] ?? '';
            
            return FadeInUp(
              delay: Duration(milliseconds: index * 30),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      alignment: Alignment.center,
                      child: Text(
                        "#${index + 1}",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.subtleText),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textColor, letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.chat_bubble_fill, color: AppTheme.primaryColor, size: 22),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentChatScreen(
                              studentId: student['_id'],
                              studentName: name,
                              studentEmail: email,
                            ),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return FadeInUp(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Icon(icon, size: 48, color: AppTheme.subtleText.withOpacity(0.5)),
              ),
              const SizedBox(height: 24),
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textColor)),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
