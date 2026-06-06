import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

/// Combined Achievements / Activity History / Learning Statistics screen.
/// [initialTab]: 0 = Statistics, 1 = Activity, 2 = Achievements
class StudentStatsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const StudentStatsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<StudentStatsScreen> createState() => _StudentStatsScreenState();
}

class _StudentStatsScreenState extends ConsumerState<StudentStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    Future.microtask(_fetch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final api = ref.read(apiServiceProvider);
    final data = await api.getStudentStats();
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? AppTheme.textColor;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: Icon(CupertinoIcons.arrow_left, color: textColor),
            onPressed: () => Navigator.pop(context)),
        title: Text("My Progress",
            style: GoogleFonts.inter(
                color: textColor, fontWeight: FontWeight.w600, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.subtleText,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: "Statistics"),
            Tab(text: "Activity"),
            Tab(text: "Achievements"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatistics(),
                _buildActivity(),
                _buildAchievements(),
              ],
            ),
    );
  }

  // ─── Statistics ──────────────────────────────────────────────
  Widget _buildStatistics() {
    final s = (_data['statistics'] ?? const {}) as Map<String, dynamic>;
    final totalQuizzes = s['totalQuizzes'] ?? 0;
    final avg = s['averageScore'] ?? 0;
    final pass = s['passRate'] ?? 0;
    final best = s['bestScore'] ?? 0;
    final xp = s['totalXp'] ?? 0;
    final timeSec = (s['totalTimeSeconds'] ?? 0) as int;
    final mins = (timeSec / 60).round();

    final cards = [
      _StatCard("Quizzes Taken", "$totalQuizzes", CupertinoIcons.doc_text_fill, AppTheme.primaryColor),
      _StatCard("Average Score", "$avg%", CupertinoIcons.chart_bar_alt_fill, AppTheme.secondaryColor),
      _StatCard("Pass Rate", "$pass%", CupertinoIcons.checkmark_seal_fill, Colors.green),
      _StatCard("Best Score", "$best%", CupertinoIcons.star_fill, AppTheme.accentColor),
      _StatCard("Total XP", "$xp", CupertinoIcons.bolt_fill, const Color(0xFF8B5CF6)),
      _StatCard("Time Spent", "${mins}m", CupertinoIcons.clock_fill, const Color(0xFF3B82F6)),
    ];

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppTheme.primaryColor,
      child: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: cards
            .asMap()
            .entries
            .map((e) => FadeInUp(
                  delay: Duration(milliseconds: e.key * 60),
                  child: _buildStatCard(e.value),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatCard c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(c.icon, color: c.color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.value,
                  style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _textColor())),
              const SizedBox(height: 2),
              Text(c.label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.subtleText)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Activity ────────────────────────────────────────────────
  Widget _buildActivity() {
    final history = (_data['activityHistory'] ?? const []) as List<dynamic>;
    if (history.isEmpty) {
      return _empty(CupertinoIcons.clock, "No activity yet",
          "Take a quiz to start building your history.");
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final a = history[index] as Map<String, dynamic>;
          final pct = a['percentage'] ?? 0;
          final color = pct >= 75
              ? Colors.green
              : (pct >= 50 ? AppTheme.accentColor : Colors.redAccent);
          return FadeInUp(
            delay: Duration(milliseconds: index * 40),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor()),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("$pct%",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: color)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['quizTitle']?.toString() ?? 'Quiz',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: _textColor())),
                        const SizedBox(height: 2),
                        Text(
                          "${a['score']}/${a['totalQuestions']} • ${_formatDate(a['date'])}",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.subtleText),
                        ),
                      ],
                    ),
                  ),
                  if ((a['xpEarned'] ?? 0) > 0)
                    Text("+${a['xpEarned']} XP",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppTheme.primaryColor)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Achievements ────────────────────────────────────────────
  Widget _buildAchievements() {
    final achievements = (_data['achievements'] ?? const []) as List<dynamic>;
    if (achievements.isEmpty) {
      return _empty(CupertinoIcons.rosette, "No achievements yet",
          "Keep learning to unlock badges.");
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final a = achievements[index] as Map<String, dynamic>;
          final unlocked = a['unlocked'] == true;
          return FadeInUp(
            delay: Duration(milliseconds: index * 50),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: unlocked
                    ? AppTheme.accentColor.withValues(alpha: 0.06)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: unlocked
                      ? AppTheme.accentColor.withValues(alpha: 0.4)
                      : _borderColor(),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: unlocked
                          ? AppTheme.accentColor.withValues(alpha: 0.15)
                          : AppTheme.subtleText.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      unlocked
                          ? CupertinoIcons.rosette
                          : CupertinoIcons.lock_fill,
                      color: unlocked ? AppTheme.accentColor : AppTheme.subtleText,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title']?.toString() ?? 'Achievement',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _textColor())),
                        const SizedBox(height: 2),
                        Text(a['description']?.toString() ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppTheme.subtleText)),
                      ],
                    ),
                  ),
                  if (unlocked)
                    const Icon(CupertinoIcons.checkmark_circle_fill,
                        color: Colors.green, size: 22),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _empty(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppTheme.subtleText),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: _textColor())),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppTheme.subtleText)),
        ],
      ),
    );
  }

  Color _textColor() =>
      Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textColor;

  Color _borderColor() =>
      Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkBorder
          : AppTheme.borderColor;

  String _formatDate(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    final local = d.toLocal();
    return "${local.month}/${local.day}/${local.year}";
  }
}

class _StatCard {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);
}
