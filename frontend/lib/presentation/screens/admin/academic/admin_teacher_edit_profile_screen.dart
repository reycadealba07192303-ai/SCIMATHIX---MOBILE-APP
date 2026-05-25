import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AdminTeacherEditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onUpdated;

  const AdminTeacherEditProfileScreen({
    super.key,
    required this.teacher,
    required this.onUpdated,
  });

  @override
  ConsumerState<AdminTeacherEditProfileScreen> createState() => _AdminTeacherEditProfileScreenState();
}

class _AdminTeacherEditProfileScreenState extends ConsumerState<AdminTeacherEditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  late Map<String, dynamic> _currentTeacher;

  @override
  void initState() {
    super.initState();
    _currentTeacher = Map<String, dynamic>.from(widget.teacher);
    _nameController = TextEditingController(text: _currentTeacher['name'] ?? '');
    _emailController = TextEditingController(text: _currentTeacher['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fields cannot be empty.")));
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(apiServiceProvider).updateTeacherProfile(_currentTeacher['_id'], name, email);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
        widget.onUpdated();
        Navigator.pop(context); // Go back after updating
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile.")));
      }
    }
  }

  Future<void> _removeHandledClass(String handledClassId) async {
    setState(() => _isLoading = true);
    final success = await ref.read(apiServiceProvider).removeHandledClass(_currentTeacher['_id'], handledClassId);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        // Remove locally from UI for immediate feedback
        setState(() {
          final classes = List<dynamic>.from(_currentTeacher['handledClasses'] ?? []);
          classes.removeWhere((hc) => hc['_id'] == handledClassId);
          _currentTeacher['handledClasses'] = classes;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Handled section removed.")));
        widget.onUpdated(); // Tell parent to refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to remove handled section.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _currentTeacher['subjectRole'] ?? "No Subject Role Assigned";
    final handledClasses = _currentTeacher['handledClasses'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        title: Text(
          "Edit Teacher Profile",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Description of Teacher
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          (_currentTeacher['name'] ?? "T")[0],
                          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentTeacher['name'] ?? "",
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role,
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Edit Information Form
                Text("EDIT INFORMATION", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.subtleText, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: GoogleFonts.inter(color: AppTheme.subtleText),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderColor)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    labelStyle: GoogleFonts.inter(color: AppTheme.subtleText),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderColor)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Update Information", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Handled Sections (CRUD)
                Text("HANDLED SECTIONS", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.subtleText, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                if (handledClasses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        Icon(CupertinoIcons.doc_text_search, size: 40, color: AppTheme.subtleText.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text("No assigned sections", style: GoogleFonts.inter(color: AppTheme.subtleText)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: handledClasses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final hc = handledClasses[index];
                      // hc = { _id, section: { name, level: { name } }, subject: { name, code } }
                      final sectionName = hc['section']?['name'] ?? 'Unknown Section';
                      final levelName = hc['section']?['level']?['name'] ?? '';
                      final subjectName = hc['subject']?['name'] ?? 'Unknown Subject';
                      final subjectCode = hc['subject']?['code'] ?? '';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.book, color: AppTheme.secondaryColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$levelName - $sectionName",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "$subjectName ($subjectCode)",
                                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showCupertinoDialog(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text("Remove Assignment"),
                                    content: Text("Remove this teacher from $sectionName?"),
                                    actions: [
                                      CupertinoDialogAction(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
                                      CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _removeHandledClass(hc['_id']);
                                        },
                                        child: const Text("Remove"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(CupertinoIcons.delete, color: Colors.redAccent, size: 20),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
