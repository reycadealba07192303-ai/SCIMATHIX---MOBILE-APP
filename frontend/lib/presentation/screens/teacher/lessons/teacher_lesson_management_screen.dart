import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/teacher/lessons/upload_lesson_screen.dart';

class TeacherLessonManagementScreen extends ConsumerStatefulWidget {
  const TeacherLessonManagementScreen({super.key});

  @override
  ConsumerState<TeacherLessonManagementScreen> createState() => _TeacherLessonManagementScreenState();
}

class _TeacherLessonManagementScreenState extends ConsumerState<TeacherLessonManagementScreen> {
  List<dynamic> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    final lessons = await ref.read(apiServiceProvider).getLessons();
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteLesson(String lessonId) async {
    final ok = await ref.read(apiServiceProvider).deleteLesson(lessonId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lesson deleted.")));
      _loadLessons();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete lesson.")));
    }
  }

  void _showEditDialog(Map<String, dynamic> lesson) {
    final titleController = TextEditingController(text: lesson['title'] ?? '');
    final contentController = TextEditingController(text: lesson['content'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Lesson", style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(labelText: "Content"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final ok = await ref.read(apiServiceProvider).updateLesson(lesson['_id'], {
                'title': titleController.text.trim(),
                'content': contentController.text.trim(),
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lesson updated.")));
                _loadLessons();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update lesson.")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Lesson Management",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadLessons,
            icon: Icon(CupertinoIcons.refresh, color: AppTheme.textColor),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? Center(child: Text("No lessons yet.", style: GoogleFonts.inter(color: AppTheme.subtleText)))
              : RefreshIndicator(
                  onRefresh: _loadLessons,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _lessons.length,
                    itemBuilder: (context, index) => _buildLessonItem(Map<String, dynamic>.from(_lessons[index]), index),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadLessonScreen()),
          );
          _loadLessons();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLessonItem(Map<String, dynamic> lesson, int index) {
    final subject = lesson['subject'];
    final subjectName = subject is Map ? subject['name'] ?? 'Subject' : 'Subject';
    final title = lesson['title'] ?? 'Untitled Lesson';

    return FadeInUp(
      delay: Duration(milliseconds: index * 40),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textColor)),
                  const SizedBox(height: 4),
                  Text(subjectName, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.pencil, color: AppTheme.primaryColor),
              onPressed: () => _showEditDialog(lesson),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.delete, color: Colors.redAccent),
              onPressed: () => _deleteLesson(lesson['_id']),
            ),
          ],
        ),
      ),
    );
  }
}
