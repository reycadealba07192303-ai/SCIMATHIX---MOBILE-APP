import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/student/leaderboard/student_leaderboard_screen.dart';
import 'package:scimathix/presentation/screens/student/profile/settings_screen.dart';
import 'package:scimathix/presentation/screens/student/profile/student_stats_screen.dart';
import 'package:scimathix/presentation/screens/student/profile/notifications_screen.dart';
import 'package:scimathix/presentation/screens/student/profile/privacy_screen.dart';
import 'package:scimathix/logic/theme_provider.dart';
class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text("Change Profile Photo", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.textColor)),
              const SizedBox(height: 20),
              _buildSourceTile(ctx, CupertinoIcons.camera_fill, "Take a Photo", ImageSource.camera),
              const SizedBox(height: 12),
              _buildSourceTile(ctx, CupertinoIcons.photo_fill, "Choose from Gallery", ImageSource.gallery),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final fileBytes = await pickedFile.readAsBytes();
      final api = ref.read(apiServiceProvider);
      
      final response = await api.uploadProfileImage(
        fileName: pickedFile.name,
        fileBytes: fileBytes,
        filePath: pickedFile.path,
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

  Widget _buildSourceTile(BuildContext ctx, IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, source),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 15, color: AppTheme.textColor)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeModeProvider); // Force instant rebuild on theme change
    final user = ref.watch(authProvider).user;
    final hasPicture = user?.profilePicture != null && user!.profilePicture!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor, 
        elevation: 0, 
        centerTitle: true,
        title: Text("Profile", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FadeInDown(
            child: Column(children: [
              // Avatar
              GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Stack(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: _isUploading
                            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2))
                            : hasPicture
                                ? Image.network(
                                    ApiConfig.imageUrl(user.profilePicture),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildInitialAvatar(user.name),
                                  )
                                : _buildInitialAvatar(user?.name),
                      ),
                    ),
                    // Edit badge
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(user?.name ?? "Student", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
              const SizedBox(height: 4),
              Text(user?.email ?? "student@scimathix.com", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Builder(
                  builder: (context) {
                    final int xp = user?.xp ?? 0;
                    const int xpPerLevel = 200;
                    final int level = xp <= 0 ? 1 : (xp ~/ xpPerLevel) + 1;
                    
                    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _buildMiniStat("$xp", "XP"),
                      Container(width: 1, height: 30, color: AppTheme.borderColor),
                      _buildMiniStat("$level", "Level"),
                      Container(width: 1, height: 30, color: AppTheme.borderColor),
                      _buildMiniStat("0", "Streak"), // Setting to 0 as placeholder for now
                    ]);
                  }
                ),
              ),
            ]),
          ),
          const SizedBox(height: 32),
          _buildMenuSection("Progress", [
            _buildMenuItem(CupertinoIcons.chart_bar, "Learning Statistics", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentStatsScreen(initialTab: 0)))),
            _buildMenuItem(CupertinoIcons.time, "Activity History", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentStatsScreen(initialTab: 1)))),
            _buildMenuItem(CupertinoIcons.rosette, "Achievements", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentStatsScreen(initialTab: 2)))),
            _buildMenuItem(CupertinoIcons.chart_bar_alt_fill, "Leaderboard", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentLeaderboardScreen()))),
          ]),
          const SizedBox(height: 24),
          _buildMenuSection("Settings", [
            _buildMenuItem(CupertinoIcons.gear, "Settings", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            _buildMenuItem(CupertinoIcons.bell, "Notifications", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
            _buildMenuItem(CupertinoIcons.lock, "Privacy", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
          ]),
          const SizedBox(height: 24),
          FadeInUp(
            child: GestureDetector(
              onTap: () {
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(CupertinoIcons.square_arrow_left, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 8),
                  Text("Log Out", style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(String? name) {
    return Center(
      child: Text(
        (name ?? "S")[0].toUpperCase(),
        style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 32),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(children: [
      Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.subtleText, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor)),
          child: Column(children: items),
        ),
      ]),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5))),
        child: Row(children: [
          Icon(icon, color: AppTheme.subtleText, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w500, fontSize: 15))),
          Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
        ]),
      ),
    );
  }
}
