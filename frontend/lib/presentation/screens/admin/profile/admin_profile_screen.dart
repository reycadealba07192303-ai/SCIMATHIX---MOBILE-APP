import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/logic/theme_provider.dart';
import 'package:scimathix/presentation/screens/student/profile/change_password_screen.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  bool _isUploading = false;
  bool _notificationsEnabled = true;
  int _studentCount = 0;
  int _teacherCount = 0;
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final api = ref.read(apiServiceProvider);
      final stats = await api.getAdminStats();
      final notifs = await api.getNotifications('ADMIN');
      if (mounted) {
        setState(() {
          _studentCount = stats['studentCount'] ?? 0;
          _teacherCount = stats['teacherCount'] ?? 0;
          _notifCount = notifs.where((n) => n['isRead'] != true).length;
        });
      }
    } catch (_) {}
  }

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
      final api = ref.read(apiServiceProvider);
      final bytes = await pickedFile.readAsBytes();
      final response = await api.uploadProfileImage(
        fileName: pickedFile.name,
        fileBytes: bytes,
        filePath: pickedFile.path,
      );
      if (response != null && response['profilePicture'] != null) {
        ref.read(authProvider.notifier).updateProfilePictureLocally(response['profilePicture']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile photo updated!")),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update photo.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
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
    final user = ref.watch(authProvider).user;
    final hasPicture = user?.profilePicture != null && user!.profilePicture!.isNotEmpty;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
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
              Text(user?.name ?? "Super Admin", style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
              const SizedBox(height: 4),
              Text(user?.email ?? "admin@scimathix.com", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _buildMiniStat("$_studentCount", "Students"),
                  Container(width: 1, height: 30, color: AppTheme.borderColor),
                  _buildMiniStat("$_teacherCount", "Teachers"),
                  Container(width: 1, height: 30, color: AppTheme.borderColor),
                  _buildMiniStat("$_notifCount", "Unread"),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 32),
          _buildMenuSection("Preferences", [
            _buildSwitchItem(
              CupertinoIcons.bell, 
              "System Notifications", 
              _notificationsEnabled,
              (val) {
                setState(() => _notificationsEnabled = val);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(val ? "Notifications Enabled" : "Notifications Disabled"),
                  duration: const Duration(seconds: 1),
                ));
              }
            ),
            _buildMenuItem(CupertinoIcons.lock_shield, "Security Settings", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            }),
            _buildSwitchItem(
              CupertinoIcons.moon, 
              "Dark Mode", 
              isDark,
              (val) {
                ref.read(themeModeProvider.notifier).toggle(val);
              }
            ),
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
        (name != null && name.isNotEmpty) ? name[0].toUpperCase() : "A",
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

  Widget _buildSwitchItem(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5))),
      child: Row(children: [
        Icon(icon, color: AppTheme.subtleText, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w500, fontSize: 15))),
        CupertinoSwitch(
          activeColor: AppTheme.primaryColor,
          value: value,
          onChanged: onChanged,
        ),
      ]),
    );
  }
}