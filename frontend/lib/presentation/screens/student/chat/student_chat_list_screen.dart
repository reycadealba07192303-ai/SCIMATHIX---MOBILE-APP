import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/logic/theme_provider.dart';
import 'package:scimathix/presentation/screens/student/chat/student_chat_screen.dart';

class StudentChatListScreen extends ConsumerStatefulWidget {
  const StudentChatListScreen({super.key});

  @override
  ConsumerState<StudentChatListScreen> createState() => _StudentChatListScreenState();
}

class _StudentChatListScreenState extends ConsumerState<StudentChatListScreen> {
  List<Map<String, dynamic>> _chatTargets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadChatTargets());
  }

  Future<void> _loadChatTargets() async {
    final user = ref.read(authProvider).user;
    if (user?.section == null || user!.section!.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final details = await api.getSectionDetails(user.section!);

      if (details != null && mounted) {
        final targets = <Map<String, dynamic>>[];

        // Add the section adviser as a chat target
        final teacher = details['teacher'];
        if (teacher != null) {
          targets.add({
            'type': 'teacher',
            'id': teacher['_id'],
            'name': teacher['name'] ?? 'Teacher',
            'profilePicture': teacher['profilePicture'],
            'subtitle': 'Section Adviser',
            'icon': CupertinoIcons.person_crop_circle_badge_checkmark,
            'color': const Color(0xFF3B82F6),
          });
        }

        // Add an AI Study Assistant chat option (lesson-based)
        targets.add({
          'type': 'ai',
          'id': 'ai_assistant',
          'name': 'AI Study Assistant',
          'profilePicture': null,
          'subtitle': 'Ask me anything about your lessons',
          'icon': CupertinoIcons.sparkles,
          'color': const Color(0xFF8B5CF6),
        });

        // Add classmates from the section
        final students = details['students'] as List<dynamic>? ?? [];
        for (final student in students) {
          if (student['_id'] != user.id) {
            targets.add({
              'type': 'classmate',
              'id': student['_id'],
              'name': student['name'] ?? 'Classmate',
              'profilePicture': student['profilePicture'],
              'subtitle': 'Classmate',
              'icon': CupertinoIcons.person,
              'color': const Color(0xFF10B981),
            });
          }
        }

        setState(() {
          _chatTargets = targets;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // Force instant rebuild on theme change
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chatTargets.isEmpty
                      ? _buildEmptyState()
                      : _buildChatList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Messages",
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textColor, letterSpacing: -0.5),
                ),
                Text(
                  "Chat with your teachers & classmates",
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    // Group by type
    final teachers = _chatTargets.where((t) => t['type'] == 'teacher').toList();
    final ai = _chatTargets.where((t) => t['type'] == 'ai').toList();
    final classmates = _chatTargets.where((t) => t['type'] == 'classmate').toList();

    return RefreshIndicator(
      onRefresh: _loadChatTargets,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          // AI Assistant card (special featured card)
          if (ai.isNotEmpty) ...[
            _buildSectionLabel("AI Assistant"),
            const SizedBox(height: 8),
            _buildAICard(ai.first),
            const SizedBox(height: 24),
          ],
          // Teachers
          if (teachers.isNotEmpty) ...[
            _buildSectionLabel("Teachers"),
            const SizedBox(height: 8),
            ...teachers.asMap().entries.map((e) => _buildChatTile(e.value, e.key)),
            const SizedBox(height: 24),
          ],
          // Classmates
          if (classmates.isNotEmpty) ...[
            _buildSectionLabel("Classmates"),
            const SizedBox(height: 8),
            ...classmates.asMap().entries.map((e) => _buildChatTile(e.value, e.key + teachers.length)),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.subtleText, letterSpacing: 0.5),
    );
  }

  Widget _buildAICard(Map<String, dynamic> target) {
    return FadeInUp(
      child: GestureDetector(
        onTap: () => _openChat(target),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF8B5CF6).withOpacity(0.1), const Color(0xFF6366F1).withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target['name'],
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target['subtitle'],
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Chat", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> target, int index) {
    final name = target['name'] as String;
    final subtitle = target['subtitle'] as String;
    final color = target['color'] as Color;
    final profilePic = target['profilePicture'];

    return FadeInUp(
      delay: Duration(milliseconds: 50 * index),
      child: GestureDetector(
        onTap: () => _openChat(target),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.1),
                backgroundImage: (profilePic != null && profilePic.toString().isNotEmpty)
                    ? NetworkImage(ApiConfig.imageUrl(profilePic.toString()))
                    : null,
                child: (profilePic == null || profilePic.toString().isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: color),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(Map<String, dynamic> target) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentChatScreen(
          chatTargetName: target['name'],
          chatTargetType: target['type'],
          chatTargetId: target['id'],
          accentColor: target['color'],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInUp(
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
              child: Icon(CupertinoIcons.chat_bubble_2, size: 48, color: AppTheme.subtleText.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text("No Chats Available", style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textColor)),
            const SizedBox(height: 8),
            Text(
              "You need to be assigned to a section\nto start chatting.",
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
