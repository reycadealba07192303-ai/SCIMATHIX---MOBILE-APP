import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/models/user_model.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/teacher/lessons/teacher_lesson_management_screen.dart';
import 'package:scimathix/presentation/screens/teacher/quiz/teacher_quiz_generation_screen.dart';

class TeacherClassroomScreen extends ConsumerStatefulWidget {
  final HandledClassModel handledClass;

  const TeacherClassroomScreen({super.key, required this.handledClass});

  @override
  ConsumerState<TeacherClassroomScreen> createState() => _TeacherClassroomScreenState();
}

class _TeacherClassroomScreenState extends ConsumerState<TeacherClassroomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _students = [];
  bool _loadingStudents = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchStudents();
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.handledClass.subjectName,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              "${widget.handledClass.levelName} • ${widget.handledClass.sectionName}",
              style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            const Tab(text: "Stream"),
            const Tab(text: "Lessons"),
            const Tab(text: "Quizzes"),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Students"),
                  if (!_loadingStudents && _students.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_students.length}",
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStreamTab(),
          const TeacherLessonManagementScreen(),
          const TeacherQuizGenerationScreen(),
          _buildStudentsTab(),
        ],
      ),
    );
  }

  Widget _buildStreamTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Announce box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(CupertinoIcons.person_solid, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Announce something to your class",
                  style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Placeholder post
        Container(
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
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: const Icon(CupertinoIcons.person_solid, color: AppTheme.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("You posted a new material", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor)),
                      Text("Today, 9:00 AM", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Welcome to the first day of class! Please review the syllabus attached in the Lessons tab.",
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textColor, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.person_3, size: 64, color: AppTheme.borderColor),
            const SizedBox(height: 16),
            Text(
              "No students enrolled yet.",
              style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Students will appear here once enrolled in this section.",
              style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: AppTheme.surfaceColor,
          child: Row(
            children: [
              Icon(CupertinoIcons.person_3_fill, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "${_students.length} Student${_students.length != 1 ? 's' : ''} in ${widget.handledClass.sectionName}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(CupertinoIcons.refresh, size: 18, color: AppTheme.primaryColor),
                onPressed: _fetchStudents,
                tooltip: "Refresh",
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final student = _students[index];
              final name = student['name'] ?? 'Unknown';
              final email = student['email'] ?? '';
              final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        initial,
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.subtleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "#${index + 1}",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
