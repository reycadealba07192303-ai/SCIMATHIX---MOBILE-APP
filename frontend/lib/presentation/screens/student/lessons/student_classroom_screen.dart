import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/logic/data_providers.dart';
import 'package:scimathix/presentation/screens/student/lessons/lesson_details_screen.dart';

class StudentClassroomScreen extends ConsumerWidget {
  const StudentClassroomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final sectionId = user?.section;

    if (sectionId == null || sectionId.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Text("You are not assigned to a section yet."),
        ),
      );
    }

    final sectionDetailsAsync = ref.watch(sectionDetailsProvider(sectionId));
    final feedAsync = ref.watch(classroomFeedProvider(sectionId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Classroom",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: AppTheme.textColor),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            ref.invalidate(sectionDetailsProvider(sectionId));
            ref.invalidate(classroomFeedProvider(sectionId));
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Section Header
              sectionDetailsAsync.when(
                data: (details) {
                  if (details == null) return const SizedBox();
                  final sectionName = details['name'] ?? 'Your Section';
                  final teacherObj = details['teacher'];
                  final teacherName = teacherObj != null ? teacherObj['name'] : 'No Assigned Teacher';
                  return FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sectionName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.person_alt_circle, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Instructor: $teacherName",
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
              ),
              
              const SizedBox(height: 32),
              
              Text(
                "Classroom Feed",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Feed List
              feedAsync.when(
                data: (feedItems) {
                  if (feedItems.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          "No announcements or lessons yet.",
                          style: GoogleFonts.inter(color: AppTheme.subtleText),
                        ),
                      ),
                    );
                  }
                  
                  return Column(
                    children: feedItems.map<Widget>((item) {
                      final isAnnouncement = item['feedType'] == 'announcement';
                      return FadeInUp(
                        child: isAnnouncement 
                            ? _buildAnnouncementCard(item) 
                            : _buildLessonCard(context, item),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                )),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> item) {
    final teacherObj = item['teacher'];
    final teacherName = teacherObj != null ? teacherObj['name'] : 'Teacher';
    final content = item['content'] ?? '';
    // Format date if needed, keeping it simple for now
    final date = "Recently"; 

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.speaker_2_fill, color: AppTheme.secondaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                    Text(date, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textColor.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] ?? 'Untitled Lesson';
    final subjectObj = item['subject'];
    final subjectName = subjectObj != null ? subjectObj['name'] : 'General';
    final teacherObj = item['teacher'];
    final teacherName = teacherObj != null ? teacherObj['name'] : 'Teacher';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonDetailsScreen(
              lessonTitle: title,
              themeColor: AppTheme.primaryColor,
              lessonId: item['_id'],
              content: item['content'],
              summary: item['summary'],
              objectives: item['objectives'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.book_fill, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("New Lesson Posted", style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                  const SizedBox(height: 4),
                  Text("$subjectName • By $teacherName", style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
