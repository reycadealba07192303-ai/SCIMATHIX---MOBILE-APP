import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/logic/data_providers.dart';
import 'package:scimathix/logic/theme_provider.dart';
import 'package:scimathix/presentation/screens/student/lessons/subject_classroom_screen.dart';
import 'package:scimathix/data/services/socket_service.dart';

class StudentClassroomScreen extends ConsumerStatefulWidget {
  const StudentClassroomScreen({super.key});

  @override
  ConsumerState<StudentClassroomScreen> createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends ConsumerState<StudentClassroomScreen> {
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _socketService.initSocket();
    _socketService.on('academic_updated', _handleAcademicUpdate);
    _socketService.on('classroom_updated', _handleAcademicUpdate);
  }

  void _handleAcademicUpdate(dynamic data) {
    if (!mounted) return;
    final sectionId = ref.read(authProvider).user?.section;
    if (sectionId != null && sectionId.isNotEmpty) {
      ref.invalidate(sectionDetailsProvider(sectionId));
    }
  }

  @override
  void dispose() {
    _socketService.off('academic_updated', _handleAcademicUpdate);
    _socketService.off('classroom_updated', _handleAcademicUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider);
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

    final sectionDetailsAsync = ref.watch(sectionDetailsProvider(user.section!));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(
          "My Classes",
          style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.search, color: AppTheme.textColor),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sectionDetailsAsync.when(
        data: (details) {
          if (details == null) {
             return Center(child: Text("Failed to load section details", style: GoogleFonts.inter(color: AppTheme.textColor)));
          }

          final subjects = details['subjects'] as List<dynamic>? ?? [];
          final sectionName = details['name'] ?? 'Section';

          if (subjects.isEmpty) {
             return _buildEmptyState(
               icon: CupertinoIcons.square_grid_2x2,
               title: "No Subjects",
               subtitle: "There are no subjects assigned to your section yet."
             );
          }

          return RefreshIndicator(
            onRefresh: () async {
               ref.invalidate(sectionDetailsProvider(user.section!));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final subjectName = subject['name'] ?? 'Subject';
                final subjectId = subject['_id'];
                
                // Assign a color dynamically based on index
                final colors = [
                  const Color(0xFF3B82F6), // Blue
                  const Color(0xFF10B981), // Emerald
                  const Color(0xFF8B5CF6), // Purple
                  const Color(0xFFF59E0B), // Amber
                  const Color(0xFFEF4444), // Red
                ];
                final color = colors[index % colors.length];

                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubjectClassroomScreen(
                            subjectId: subjectId,
                            subjectName: subjectName,
                            sectionDetails: details,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 140,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.9), color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20, top: -20,
                            child: Icon(CupertinoIcons.book_circle, size: 120, color: Colors.white.withOpacity(0.1)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        subjectName,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    sectionName,
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(CupertinoIcons.folder_fill, color: Colors.white70, size: 16),
                                    const SizedBox(width: 6),
                                    Text("Open Classroom", style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error loading classes: $e", style: GoogleFonts.inter(color: AppTheme.textColor))),
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
