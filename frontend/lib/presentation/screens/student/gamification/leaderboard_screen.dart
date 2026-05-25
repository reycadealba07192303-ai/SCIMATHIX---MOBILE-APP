import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _students = [
    {"name": "Ana Garcia", "xp": 2450, "avatar": "A"},
    {"name": "Mark Santos", "xp": 2380, "avatar": "M"},
    {"name": "Reyca De Alba", "xp": 2210, "avatar": "R"},
    {"name": "Luis Reyes", "xp": 1980, "avatar": "L"},
    {"name": "Sofia Cruz", "xp": 1850, "avatar": "S"},
    {"name": "Carlos Tan", "xp": 1720, "avatar": "C"},
    {"name": "Maya Rivera", "xp": 1650, "avatar": "M"},
  ];

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
        backgroundColor: AppTheme.backgroundColor, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Leaderboard", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.subtleText,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [Tab(text: "All Time"), Tab(text: "Weekly"), Tab(text: "Monthly")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLeaderList(), _buildLeaderList(), _buildLeaderList()],
      ),
    );
  }

  Widget _buildLeaderList() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Top 3 Podium
        FadeInDown(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildPodium(_students[1], 2, 80),
              const SizedBox(width: 8),
              _buildPodium(_students[0], 1, 100),
              const SizedBox(width: 8),
              _buildPodium(_students[2], 3, 60),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Remaining list
        ...List.generate(_students.length - 3, (i) {
          final s = _students[i + 3];
          return FadeInUp(
            delay: Duration(milliseconds: 100 * i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
              child: Row(children: [
                SizedBox(width: 28, child: Text("#${i + 4}", style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w700, fontSize: 14))),
                const SizedBox(width: 12),
                CircleAvatar(radius: 18, backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1), child: Text(s["avatar"], style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 14))),
                const SizedBox(width: 12),
                Expanded(child: Text(s["name"], style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 15))),
                Text("${s["xp"]} XP", style: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPodium(Map<String, dynamic> student, int rank, double height) {
    final colors = {1: AppTheme.accentColor, 2: const Color(0xFFC0C0C0), 3: const Color(0xFFCD7F32)};
    final color = colors[rank]!;
    return Column(children: [
      CircleAvatar(radius: rank == 1 ? 28 : 22, backgroundColor: color.withValues(alpha: 0.2), child: Text(student["avatar"], style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: rank == 1 ? 18 : 14))),
      const SizedBox(height: 8),
      Text(student["name"].toString().split(' ')[0], style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 13)),
      Text("${student["xp"]} XP", style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 11)),
      const SizedBox(height: 8),
      Container(
        width: 80, height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(child: Text("#$rank", style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 18))),
      ),
    ]);
  }
}
