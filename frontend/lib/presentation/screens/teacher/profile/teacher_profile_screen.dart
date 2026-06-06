import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scimathix/presentation/screens/teacher/teacher_notifications_screen.dart';

class TeacherProfileScreen extends ConsumerStatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  ConsumerState<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends ConsumerState<TeacherProfileScreen> {
  bool _isUploading = false;

  Future<void> _showEditProfile(String currentName) async {
    final nameController = TextEditingController(text: currentName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Profile", style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.textColor)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Full name"),
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
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final ok = await ref.read(apiServiceProvider).updateOwnProfile(name: name);
    if (ok) {
      await ref.read(authProvider.notifier).refreshCurrentUser();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? "Profile updated." : "Failed to update profile."),
      backgroundColor: ok ? AppTheme.primaryColor : Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showMySections(dynamic user) {
    final handled = (user?.handledClasses as List?) ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("My Sections",
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
              const SizedBox(height: 12),
              if (handled.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No sections assigned yet.",
                        style: GoogleFonts.inter(color: AppTheme.subtleText)),
                  ),
                )
              else
                ...handled.map((hc) {
                  final sectionName = hc.sectionName ?? 'Section';
                  final subjectName = hc.subjectName ?? 'Subject';
                  return ListTile(
                    leading: const Icon(CupertinoIcons.group_solid, color: AppTheme.primaryColor),
                    title: Text(subjectName,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                    subtitle: Text("Section $sectionName",
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLessonHistory() async {
    final lessons = await ref.read(apiServiceProvider).getLessons();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Lesson History",
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
              const SizedBox(height: 12),
              if (lessons.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("You haven't created any lessons yet.",
                        style: GoogleFonts.inter(color: AppTheme.subtleText)),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(sheetContext).size.height * 0.5),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final l = lessons[index];
                      final title = (l['title'] ?? 'Untitled').toString();
                      final subj = l['subject'];
                      final subjName = subj is Map ? (subj['name'] ?? '') : '';
                      return ListTile(
                        leading: const Icon(CupertinoIcons.doc_text_fill, color: AppTheme.primaryColor),
                        title: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                        subtitle: subjName.toString().isNotEmpty
                            ? Text(subjName.toString(),
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText))
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _isUploading = true);
      try {
        final file = result.files.first;
        final api = ref.read(apiServiceProvider);
        
        final response = await api.uploadProfileImage(
          fileName: file.name,
          fileBytes: file.bytes,
          filePath: file.path,
        );

        if (response != null) {
          final newProfilePic = response['profilePicture'];
          if (newProfilePic != null) {
            ref.read(authProvider.notifier).updateProfilePictureLocally(newProfilePic);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile image updated successfully!')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile image.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final sectionsCount = user?.handledClasses?.length ?? 0;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Teacher Profile",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(user?.name ?? "Teacher", user?.email ?? "teacher@scimathix.com", user?.profilePicture),
            const SizedBox(height: 32),
            _buildStatsSection(sectionsCount),
            const SizedBox(height: 32),
            _buildMenuSection("Account", [
              _buildMenuItem("Edit Profile", CupertinoIcons.person, () => _showEditProfile(user?.name ?? '')),
              _buildMenuItem("My Sections", CupertinoIcons.group, () => _showMySections(user)),
              _buildMenuItem("Lesson History", CupertinoIcons.time, _showLessonHistory),
            ]),

            const SizedBox(height: 32),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email, String? profilePicture) {
    return FadeInDown(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    backgroundImage: (profilePicture != null && profilePicture.isNotEmpty)
                        ? NetworkImage(ApiConfig.imageUrl(profilePicture))
                        : null,
                    child: (profilePicture == null || profilePicture.isEmpty)
                        ? const Icon(CupertinoIcons.person_solid, size: 48, color: AppTheme.primaryColor)
                        : null,
                  ),
                  if (_isUploading)
                    const CircularProgressIndicator(color: AppTheme.primaryColor),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.subtleText,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Faculty Member",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(int sectionsCount) {
    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(sectionsCount.toString(), "Sections Handled"),
            _buildVerticalDivider(),
            _buildStatItem("Active", "Status"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.subtleText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppTheme.borderColor,
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return FadeInUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.subtleText,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.subtleText, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
            const Spacer(),
            Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return FadeInUp(
      child: TextButton(
        onPressed: () {
          ref.read(authProvider.notifier).logout();
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
        ),
        child: Text(
          "Log Out",
          style: GoogleFonts.inter(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
