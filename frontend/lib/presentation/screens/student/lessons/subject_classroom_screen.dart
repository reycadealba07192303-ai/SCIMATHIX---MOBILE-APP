import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/data/services/socket_service.dart';
import 'package:scimathix/presentation/screens/student/lessons/lesson_details_screen.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_instructions_screen.dart';

class SubjectClassroomScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final Map<String, dynamic> sectionDetails;

  const SubjectClassroomScreen({
    super.key, 
    required this.subjectId, 
    required this.subjectName,
    required this.sectionDetails,
  });

  @override
  ConsumerState<SubjectClassroomScreen> createState() => _SubjectClassroomScreenState();
}

class _SubjectClassroomScreenState extends ConsumerState<SubjectClassroomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  late final SocketService _socketService;

  List<dynamic> _streamPosts = [];
  List<dynamic> _lessons = [];
  List<dynamic> _quizzes = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _socketService = ref.read(socketServiceProvider);
    _socketService.initSocket();
    _socketService.on('classroom_updated', _handleClassroomUpdate);
    _socketService.on('academic_updated', _handleClassroomUpdate);
    Future.microtask(() => _fetchClassroomData());
  }

  void _handleClassroomUpdate(dynamic data) {
    final user = ref.read(authProvider).user;
    if (data is Map) {
      final sectionId = data['sectionId']?.toString();
      final subjectId = data['subjectId']?.toString();
      if (sectionId != null && sectionId != user?.section) return;
      if (subjectId != null && subjectId != widget.subjectId) return;
    }

    _fetchClassroomData();
  }

  Future<void> _fetchClassroomData() async {
    final user = ref.read(authProvider).user;
    if (user?.section == null || user!.section!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final sectionId = user.section!;
      
      // Fetch Stream (Announcements & Lessons mixed or just announcements)
      final feed = await api.getClassroomFeed(sectionId, subjectId: widget.subjectId);
      
      // Fetch Quizzes
      final allQuizzes = await api.getQuizzes();
      
      // In a real app, we'd also have an endpoint for classmates.
      // We will mock classmates for now or fetch if available.
      
      if (mounted) {
        setState(() {
          _streamPosts = feed.where((item) => item['feedType'] == 'announcement').toList();
          
          _lessons = feed.where((item) {
            if (item['feedType'] != 'lesson') return false;
            final subject = item['subject'];
            final subId = subject is Map ? subject['_id'] : subject;
            return subId == widget.subjectId;
          }).toList();
          
          _quizzes = allQuizzes.where((q) {
            final lesson = q['lesson'];
            if (lesson == null) return false;
            final lessonSections = lesson['sections'] as List<dynamic>? ?? [];
            final subject = lesson['subject'];
            final subId = subject is Map ? subject['_id'] : subject;
            return (lessonSections.contains(sectionId) || lesson['section'] == sectionId) && subId == widget.subjectId;
          }).toList();
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _socketService.off('classroom_updated', _handleClassroomUpdate);
    _socketService.off('academic_updated', _handleClassroomUpdate);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user?.section == null || user!.section!.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: _buildEmptyState(
            icon: CupertinoIcons.exclamationmark_circle,
            title: "No Assigned Section",
            subtitle: "You are not assigned to any classroom section yet."
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240.0,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.surfaceColor,
              elevation: innerBoxIsScrolled ? 4 : 0,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.arrow_left, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Builder(
                  builder: (context) {
                    final details = widget.sectionDetails;
                    final sectionName = details['name'] ?? 'Section';
                    final subjectTeachers = details['subjectTeachers'] as Map<String, dynamic>? ?? {};
                    final teacherObj = subjectTeachers[widget.subjectId] ?? details['teacher'];
                    final teacherName = teacherObj != null ? teacherObj['name'] : 'Instructor';

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Decorative elements
                        Positioned(
                          right: -50, top: -50,
                          child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
                        ),
                        Positioned(
                          left: -30, bottom: -30,
                          child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  sectionName,
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.subjectName,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.person_alt_circle, color: Colors.white70, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Adviser: $teacherName",
                                    style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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
                        tabs: const [
                          Tab(text: "Stream"),
                          Tab(text: "Lessons"),
                          Tab(text: "Quizzes"),
                          Tab(text: "Classmates"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStreamTab(),
                  _buildLessonsTab(),
                  _buildQuizzesTab(),
                  _buildClassmatesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildStreamTab() {
    if (_streamPosts.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.chat_bubble_2,
        title: "No Announcements Yet",
        subtitle: "Your teacher hasn't posted any announcements for this section."
      );
    }
    
    return RefreshIndicator(
      onRefresh: _fetchClassroomData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _streamPosts.length,
        itemBuilder: (context, index) {
          final item = _streamPosts[index];
          final teacherObj = item['teacher'];
          final teacherName = teacherObj != null ? teacherObj['name'] : 'Teacher';
          final title = (item['title'] ?? '').toString();
          final content = item['content'] ?? '';
          final scheduledDate = item['scheduledDate'];
          final scheduledTime = (item['scheduledTime'] ?? '').toString();
          final dateStr = item['createdAt'] ?? '';
          final formattedDate = dateStr.length > 10 ? dateStr.substring(0, 10) : 'Recently';

          return FadeInUp(
            delay: Duration(milliseconds: 50 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.speaker_2_fill, color: AppTheme.primaryColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacherName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textColor)),
                            const SizedBox(height: 2),
                            Text(formattedDate, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (title.trim().isNotEmpty) ...[
                    Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (scheduledDate != null) ...[
                    Row(
                      children: [
                        _buildScheduleChip(CupertinoIcons.calendar, _formatScheduleDate(scheduledDate)),
                        if (scheduledTime.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildScheduleChip(CupertinoIcons.clock, scheduledTime),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    content,
                    style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textColor.withOpacity(0.9), height: 1.5),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatScheduleDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildLessonsTab() {
    if (_lessons.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.book,
        title: "No Lessons",
        subtitle: "There are no lessons uploaded for this section yet."
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchClassroomData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final lesson = _lessons[index];
          final title = lesson['title'] ?? 'Untitled';
          final subjectObj = lesson['subject'];
          final subjectName = subjectObj != null ? subjectObj['name'] : 'General';
          final teacherObj = lesson['teacher'];
          final teacherName = teacherObj != null ? teacherObj['name'] : 'Teacher';
          
          return FadeInUp(
            delay: Duration(milliseconds: 50 * index),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonDetailsScreen(
                      lessonTitle: title,
                      themeColor: const Color(0xFF10B981), // Emerald
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
                  gradient: LinearGradient(
                    colors: [const Color(0xFF10B981).withOpacity(0.05), const Color(0xFF10B981).withOpacity(0.01)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.doc_text_fill, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subjectName, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                          const SizedBox(height: 4),
                          Text("By $teacherName", style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor),
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
    if (_quizzes.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.check_mark_circled,
        title: "No Quizzes",
        subtitle: "There are no quizzes assigned to this section."
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchClassroomData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          final title = quiz['title'] ?? 'Quiz';
          final questions = (quiz['questions'] as List?)?.length ?? 0;
          final lessonObj = quiz['lesson'];
          final lessonTitle = lessonObj != null ? lessonObj['title'] : 'General';
          
          return FadeInUp(
            delay: Duration(milliseconds: 50 * index),
            child: GestureDetector(
              onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizInstructionsScreen(
                        quizId: quiz['_id'] ?? '',
                        quizTitle: title,
                        timeLimit: quiz['timeLimit'] ?? 15,
                        questionsCount: quiz['questionsCount'] ?? questions,
                        passingScore: quiz['passingScore'] ?? 60,
                        themeColor: const Color(0xFF8B5CF6),
                        isPractice: quiz['isPractice'] == true,
                        scheduledDate: quiz['scheduledDate'],
                        scheduledTime: quiz['scheduledTime'],
                        endTime: quiz['endTime'],
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
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(CupertinoIcons.question_diamond_fill, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Quiz • $questions Items", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                          const SizedBox(height: 4),
                          Text("Topic: $lessonTitle", style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("Take", style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 13)),
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

  Widget _buildClassmatesTab() {
    final user = ref.read(authProvider).user;
    final students = (widget.sectionDetails['students'] as List<dynamic>? ?? [])
        .where((s) => s != null)
        .toList();

    if (students.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.person_3_fill,
        title: "No Classmates Yet",
        subtitle: "There are no other students enrolled in this section yet.",
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchClassroomData,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final name = (student['name'] ?? 'Student').toString();
          final email = (student['email'] ?? '').toString();
          final isMe = student['_id'] == user?.id;

          return FadeInUp(
            delay: Duration(milliseconds: 40 * index),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("You",
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryColor)),
                              ),
                            ],
                          ],
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppTheme.subtleText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
