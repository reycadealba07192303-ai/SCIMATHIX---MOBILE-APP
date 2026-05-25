import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AdminAcademicScreen extends ConsumerStatefulWidget {
  const AdminAcademicScreen({super.key});

  @override
  ConsumerState<AdminAcademicScreen> createState() => _AdminAcademicScreenState();
}

class _AdminAcademicScreenState extends ConsumerState<AdminAcademicScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Academic Management",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.subtleText,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: "Classes"),
            Tab(text: "Assign Teachers"),
            Tab(text: "Enroll Students"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ManageClassesTab(),
          _AssignTeachersTab(),
          _EnrollStudentsTab(),
        ],
      ),
    );
  }
}

class _ManageClassesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ManageClassesTab> createState() => _ManageClassesTabState();
}

class _ManageClassesTabState extends ConsumerState<_ManageClassesTab> {
  final _levelController = TextEditingController();
  final _sectionController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  
  List<dynamic> _levels = [];
  String? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    // Placeholder for loading levels if implemented in api_service
  }

  Future<void> _createSection() async {
    if (_sectionController.text.isEmpty || _selectedLevelId == null) return;
    final success = await ref.read(apiServiceProvider).createSection(_sectionController.text, _selectedLevelId!);
    if (success) {
      _sectionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Section created')));
    }
  }

  Future<void> _createSubject() async {
    if (_subjectNameController.text.isEmpty || _subjectCodeController.text.isEmpty) return;
    final success = await ref.read(apiServiceProvider).createSubject(_subjectNameController.text, _subjectCodeController.text);
    if (success) {
      _subjectNameController.clear();
      _subjectCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subject created')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          "Create Section",
          Column(
            children: [
              // For simplicity, assuming level selection exists, we use a placeholder or dropdown
              TextField(
                controller: _sectionController,
                decoration: const InputDecoration(labelText: "Section Name (e.g. Section A)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createSection,
                child: const Text("Create Section"),
              )
            ],
          )
        ),
        const SizedBox(height: 32),
        _buildSection(
          "Create Subject",
          Column(
            children: [
              TextField(
                controller: _subjectNameController,
                decoration: const InputDecoration(labelText: "Subject Name (e.g. Science)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectCodeController,
                decoration: const InputDecoration(labelText: "Subject Code (e.g. SCI-101)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createSubject,
                child: const Text("Create Subject"),
              )
            ],
          )
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }
}

class _AssignTeachersTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AssignTeachersTab> createState() => _AssignTeachersTabState();
}

class _AssignTeachersTabState extends ConsumerState<_AssignTeachersTab> {
  // Logic to load teachers, sections, subjects and assign
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Teacher Assignment Panel"));
  }
}

class _EnrollStudentsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EnrollStudentsTab> createState() => _EnrollStudentsTabState();
}

class _EnrollStudentsTabState extends ConsumerState<_EnrollStudentsTab> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Student Enrollment Panel"));
  }
}
