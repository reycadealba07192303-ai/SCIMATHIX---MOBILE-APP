import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/student/lessons/student_classroom_screen.dart';
import 'package:scimathix/presentation/screens/student/student_notifications_screen.dart';
import 'package:scimathix/presentation/screens/student/chat/student_chat_list_screen.dart';
import 'package:scimathix/presentation/screens/student/student_calendar_screen.dart';
import 'package:scimathix/presentation/screens/student/profile/student_profile_screen.dart';
import 'package:scimathix/presentation/screens/student/lessons/lesson_details_screen.dart';
import 'package:scimathix/presentation/screens/student/quiz/quiz_instructions_screen.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:scimathix/logic/data_providers.dart';
import 'package:scimathix/logic/theme_provider.dart';
import 'package:scimathix/data/services/socket_service.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentIndex = 0;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _socketService.initSocket();
    _socketService.on('new_notification', _handleRealtimeUpdate);
    _socketService.on('classroom_updated', _handleRealtimeUpdate);
    _socketService.on('academic_updated', _handleRealtimeUpdate);
  }

  void _handleRealtimeUpdate(dynamic data) {
    if (!mounted) return;
    ref.invalidate(globalAnnouncementsProvider);
    ref.invalidate(lessonsProvider);
    ref.invalidate(quizzesProvider);
    final sectionId = ref.read(authProvider).user?.section;
    if (sectionId != null && sectionId.isNotEmpty) {
      ref.invalidate(sectionDetailsProvider(sectionId));
    }
  }

  @override
  void dispose() {
    _socketService.off('new_notification', _handleRealtimeUpdate);
    _socketService.off('classroom_updated', _handleRealtimeUpdate);
    _socketService.off('academic_updated', _handleRealtimeUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // Force rebuild on theme change
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeView(user),
          StudentClassroomScreen(),
          StudentChatListScreen(),
          StudentProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeView(dynamic user) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final quizzesAsync = ref.watch(quizzesProvider);
    final announcementsAsync = ref.watch(globalAnnouncementsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user?.name ?? 'Student'),
            const SizedBox(height: 32),
            _buildProgressSection(user?.xp ?? 0),
            const SizedBox(height: 32),
            _buildAnnouncements(announcementsAsync),
            const SizedBox(height: 32),
            _buildRecentLessons(lessonsAsync),
            const SizedBox(height: 32),
            _buildUpcomingQuizzes(quizzesAsync),
            const SizedBox(height: 24), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return FadeInDown(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, $name 👋",
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textColor,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Let's learn something new today!",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.subtleText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(CupertinoIcons.bell, color: AppTheme.textColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentNotificationsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor, width: 1),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(CupertinoIcons.person_solid, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(int xp) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Builder(
          builder: (context) {
            // Dynamic level calculation: every 200 XP = 1 level, minimum Level 1
            const int xpPerLevel = 200;
            final int level = xp <= 0 ? 1 : (xp ~/ xpPerLevel) + 1;
            final int xpInCurrentLevel = xp % xpPerLevel;
            final double progress = xp <= 0 ? 0.0 : xpInCurrentLevel / xpPerLevel;
            final int xpNeeded = xpPerLevel - xpInCurrentLevel;

            return Row(
              children: [
                // XP Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.star_circle_fill, color: AppTheme.accentColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Level $level",
                            style: GoogleFonts.inter(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$xpInCurrentLevel / $xpPerLevel XP to next level",
                        style: GoogleFonts.inter(
                          color: AppTheme.subtleText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Total XP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(CupertinoIcons.bolt_fill, color: AppTheme.secondaryColor, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        "$xp XP",
                        style: GoogleFonts.inter(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnnouncements(AsyncValue<List<dynamic>> announcementsAsync) {
    return FadeInUp(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Announcements",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          announcementsAsync.when(
            data: (announcements) {
              if (announcements.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Center(
                    child: Text(
                      "No recent announcements.",
                      style: GoogleFonts.inter(color: AppTheme.subtleText),
                    ),
                  ),
                );
              }
              // Display the latest announcement
              final latest = announcements.first;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.speaker_2_fill, color: AppTheme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest['title'] ?? 'Announcement',
                            style: GoogleFonts.inter(
                              color: AppTheme.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            latest['message'] ?? '',
                            style: GoogleFonts.inter(
                              color: AppTheme.textColor.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error loading announcements")),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLessons(AsyncValue<List<dynamic>> lessonsAsync) {
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Lessons",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 1; // Switch to Classroom tab
                  });
                },
                child: Text(
                  "See All",
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal List of Activities
          SizedBox(
            height: 160,
            child: lessonsAsync.when(
              data: (lessons) {
                if (lessons.isEmpty) {
                  return Center(
                    child: Text(
                      "No recent lessons yet.",
                      style: GoogleFonts.inter(color: AppTheme.subtleText),
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final subjectObj = lesson['subject'] ?? {};
                    final subjectName = subjectObj['name'] ?? 'General';
                    final title = lesson['title'] ?? 'Untitled Lesson';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonDetailsScreen(
                              lessonTitle: title,
                              themeColor: index % 2 == 0
                                  ? AppTheme.primaryColor
                                  : AppTheme.secondaryColor,
                              lessonId: lesson['_id'],
                              content: lesson['content'],
                              summary: lesson['summary'],
                              objectives: lesson['objectives'],
                              fileUrl: lesson['fileUrl'],
                            ),
                          ),
                        );
                      },
                      child: _buildActivityCard(
                        title: title,
                        subject: subjectName,
                        progress: 0.0, // We can track actual progress later
                        color: index % 2 == 0 ? AppTheme.primaryColor : AppTheme.secondaryColor,
                        icon: CupertinoIcons.book,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String subject,
    required double progress,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subject,
                  style: GoogleFonts.inter(
                    color: AppTheme.subtleText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingQuizzes(AsyncValue<List<dynamic>> quizzesAsync) {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Upcoming Quizzes",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentCalendarScreen()),
                  );
                },
                child: Text(
                  "See All",
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          quizzesAsync.when(
            data: (quizzes) {
              if (quizzes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "No upcoming quizzes.",
                      style: GoogleFonts.inter(color: AppTheme.subtleText),
                    ),
                  ),
                );
              }
              return Column(
                children: quizzes.take(3).map((quiz) {
                  final title = quiz['title'] ?? 'Untitled Quiz';
                  final questionsCount = (quiz['questions'] as List?)?.length ?? 10;
                  final dateRaw = quiz['scheduledDate'] ?? quiz['createdAt'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizInstructionsScreen(
                              quizId: quiz['_id'] ?? '',
                              quizTitle: title,
                              timeLimit: quiz['timeLimit'] ?? 15,
                              questionsCount: questionsCount,
                              passingScore: quiz['passingScore'] ?? 60,
                              themeColor: AppTheme.accentColor,
                              isPractice: quiz['isPractice'] == true,
                              scheduledDate: quiz['scheduledDate'],
                              scheduledTime: quiz['scheduledTime'],
                              endTime: quiz['endTime'],
                            ),
                          ),
                        );
                      },
                      child: _buildQuizTile(
                        title: title,
                        date: _formatQuizDate(dateRaw),
                        questions: questionsCount,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Error: $err")),
          ),
        ],
      ),
    );
  }

  String _formatQuizDate(dynamic raw) {
    if (raw == null) return 'Pending';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return 'Pending';
    }
  }

  Widget _buildQuizTile({
    required String title,
    required String date,
    required int questions,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(CupertinoIcons.timer, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(CupertinoIcons.calendar, size: 14, color: AppTheme.subtleText),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        color: AppTheme.subtleText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(CupertinoIcons.question_circle, size: 14, color: AppTheme.subtleText),
                    const SizedBox(width: 4),
                    Text(
                      "$questions Qs",
                      style: GoogleFonts.inter(
                        color: AppTheme.subtleText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppTheme.primaryColor.withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor);
            }
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.subtleText);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppTheme.primaryColor, size: 22);
            }
            return IconThemeData(color: AppTheme.subtleText, size: 22);
          }),
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(FluentIcons.home_24_regular),
              selectedIcon: Icon(FluentIcons.home_24_filled),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(FluentIcons.book_open_24_regular),
              selectedIcon: Icon(FluentIcons.book_open_24_filled),
              label: 'Classes',
            ),
            NavigationDestination(
              icon: Icon(FluentIcons.chat_24_regular),
              selectedIcon: Icon(FluentIcons.chat_24_filled),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(FluentIcons.person_24_regular),
              selectedIcon: Icon(FluentIcons.person_24_filled),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
