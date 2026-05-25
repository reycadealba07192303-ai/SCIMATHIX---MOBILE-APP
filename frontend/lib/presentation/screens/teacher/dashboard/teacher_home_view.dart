import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/teacher/teacher_notifications_screen.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/teacher/classroom/teacher_classroom_screen.dart';

class TeacherHomeView extends ConsumerWidget {
  final String name;
  const TeacherHomeView({super.key, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final handledClasses = user?.handledClasses ?? [];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, user?.profilePicture),
                  const SizedBox(height: 32),
                  Text(
                    "Handled Classes",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (handledClasses.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "No classes assigned yet.",
                          style: GoogleFonts.inter(color: AppTheme.subtleText),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (handledClasses.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final handledClass = handledClasses[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 100 * index),
                      child: _buildClassCard(context, handledClass),
                    );
                  },
                  childCount: handledClasses.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? profilePicture) {
    final baseUrl = 'http://10.185.199.230:5000/uploads/';
    
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
                  "Here are your classes for today.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.subtleText,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.bell, color: AppTheme.textColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TeacherNotificationsScreen()),
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
                  backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage('$baseUrl$profilePicture')
                      : null,
                  child: profilePicture == null || profilePicture.isEmpty
                      ? const Icon(CupertinoIcons.person_solid, color: AppTheme.primaryColor)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, dynamic handledClass) {
    // Generate a beautiful gradient based on the subject name length just for variety
    final isMath = handledClass.subjectName.toLowerCase().contains("math");
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isMath 
        ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
        : [const Color(0xFF10B981), const Color(0xFF047857)],
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherClassroomScreen(handledClass: handledClass),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: isMath ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          handledClass.subjectCode,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        handledClass.subjectName,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        handledClass.levelName,
                        style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      Text(
                        handledClass.sectionName,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
