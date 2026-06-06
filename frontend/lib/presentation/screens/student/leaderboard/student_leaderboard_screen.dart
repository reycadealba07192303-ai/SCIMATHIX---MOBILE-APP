import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/core/config/api_config.dart';
import 'package:scimathix/logic/auth_provider.dart';

class StudentLeaderboardScreen extends ConsumerStatefulWidget {
  const StudentLeaderboardScreen({super.key});

  @override
  ConsumerState<StudentLeaderboardScreen> createState() => _StudentLeaderboardScreenState();
}

class _StudentLeaderboardScreenState extends ConsumerState<StudentLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Sub-tabs: My Section vs All Sections
  int _scopeIndex = 0; // 0 = My Section, 1 = All Sections
  int _periodIndex = 0; // 0 = All Time, 1 = Weekly, 2 = Monthly

  static const List<String> _periods = ['all', 'weekly', 'monthly'];
  static const List<String> _periodLabels = ['All Time', 'Weekly', 'Monthly'];

  List<dynamic> _scienceLeaderboard = [];
  List<dynamic> _mathLeaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    Future.microtask(() => _fetchLeaderboards());
  }

  Future<void> _fetchLeaderboards() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final user = ref.read(authProvider).user;
      final sectionId = (_scopeIndex == 0 && user?.section != null) ? user!.section : null;
      final period = _periods[_periodIndex];

      final sciResults = await api.getLeaderboard(category: 'Science', sectionId: sectionId, period: period);
      final mathResults = await api.getLeaderboard(category: 'Mathematics', sectionId: sectionId, period: period);

      if (mounted) {
        setState(() {
          _scienceLeaderboard = sciResults;
          _mathLeaderboard = mathResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildPeriodSelector(),
            const SizedBox(height: 12),
            _buildScopeToggle(),
            const SizedBox(height: 16),
            _buildCategoryTabs(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLeaderboardList(_scienceLeaderboard, const Color(0xFF10B981)),
                        _buildLeaderboardList(_mathLeaderboard, const Color(0xFF3B82F6)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(FluentIcons.trophy_24_filled, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Leaderboard",
                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textColor, letterSpacing: -0.5),
                ),
                Text(
                  "Compete and climb the ranks!",
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return FadeInDown(
      delay: const Duration(milliseconds: 80),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: List.generate(_periodLabels.length, (i) {
            final isSelected = _periodIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_periodIndex != i) {
                    setState(() => _periodIndex = i);
                    _fetchLeaderboards();
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(right: i < _periodLabels.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _periodLabels[i],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.subtleText,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScopeToggle() {
    return FadeInDown(
      delay: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.borderColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              _buildScopeSegment("My Section", 0),
              _buildScopeSegment("All Sections", 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeSegment(String label, int index) {
    final isSelected = _scopeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_scopeIndex != index) {
            setState(() => _scopeIndex = index);
            _fetchLeaderboards();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryColor : AppTheme.subtleText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return FadeInDown(
      delay: const Duration(milliseconds: 150),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _tabController.index == 0
                  ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                  : const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
              boxShadow: [
                BoxShadow(
                  color: (_tabController.index == 0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerHeight: 0,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.subtleText,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.beaker_24_regular, size: 18, color: _tabController.index == 0 ? Colors.white : AppTheme.subtleText),
                    const SizedBox(width: 8),
                    const Text("Science"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.calculator_24_regular, size: 18, color: _tabController.index == 1 ? Colors.white : AppTheme.subtleText),
                    const SizedBox(width: 8),
                    const Text("Mathematics"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(List<dynamic> data, Color accentColor) {
    if (data.isEmpty) {
      return _buildEmptyState(accentColor);
    }

    final currentUserId = ref.read(authProvider).user?.id;

    return RefreshIndicator(
      onRefresh: _fetchLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        itemCount: data.length + 1, // +1 for the podium
        itemBuilder: (context, index) {
          if (index == 0) {
            // Podium for top 3
            return _buildPodium(data, accentColor);
          }
          final rank = index;
          if (rank > data.length) return const SizedBox();
          final entry = data[rank - 1];
          final isCurrentUser = entry['_id'] == currentUserId;

          return FadeInUp(
            delay: Duration(milliseconds: 50 * index),
            child: _buildRankTile(entry, rank, accentColor, isCurrentUser),
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<dynamic> data, Color accentColor) {
    if (data.length < 3) {
      // Not enough data for a podium, just return empty
      return const SizedBox(height: 16);
    }

    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withOpacity(0.08), accentColor.withOpacity(0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place
            _buildPodiumSlot(data[1], 2, accentColor, 80),
            // 1st place
            _buildPodiumSlot(data[0], 1, accentColor, 100),
            // 3rd place
            _buildPodiumSlot(data[2], 3, accentColor, 70),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumSlot(dynamic entry, int rank, Color accentColor, double height) {
    final name = entry['name'] ?? 'Unknown';
    final xp = entry['xp'] ?? 0;
    final profilePic = entry['profilePicture'];
    
    final medalColors = {
      1: const Color(0xFFD3AF37), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };
    final medalColor = medalColors[rank]!;
    final medalIcons = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with crown for 1st
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: medalColor, width: rank == 1 ? 3 : 2),
                boxShadow: [
                  BoxShadow(color: medalColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: CircleAvatar(
                radius: rank == 1 ? 32 : 26,
                backgroundColor: medalColor.withOpacity(0.15),
                backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                    ? NetworkImage(ApiConfig.imageUrl(profilePic))
                    : null,
                child: (profilePic == null || profilePic.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: rank == 1 ? 24 : 18, color: medalColor),
                      )
                    : null,
              ),
            ),
            if (rank == 1)
              Positioned(
                top: -14,
                child: Text('👑', style: TextStyle(fontSize: rank == 1 ? 20 : 16)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(medalIcons[rank]!, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "$xp XP",
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: accentColor),
        ),
        const SizedBox(height: 8),
        // Podium bar
        Container(
          width: rank == 1 ? 70 : 58,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor.withOpacity(0.8), accentColor.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              "#$rank",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankTile(dynamic entry, int rank, Color accentColor, bool isCurrentUser) {
    final name = entry['name'] ?? 'Unknown';
    final xp = entry['xp'] ?? 0;
    final profilePic = entry['profilePicture'];
    final sectionObj = entry['section'];
    final sectionName = sectionObj is Map ? sectionObj['name'] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser ? accentColor.withOpacity(0.08) : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? accentColor.withOpacity(0.4) : AppTheme.borderColor,
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              "#$rank",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: rank <= 3 ? accentColor : AppTheme.subtleText,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: accentColor.withOpacity(0.1),
            backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                ? NetworkImage(ApiConfig.imageUrl(profilePic))
                : null,
            child: (profilePic == null || profilePic.isEmpty)
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: accentColor),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name & section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("YOU", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                if (sectionName != null)
                  Text(
                    sectionName,
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$xp XP",
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withOpacity(0.1), width: 2),
              ),
              child: Icon(FluentIcons.trophy_24_filled, size: 56, color: accentColor.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              "No Rankings Yet",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.textColor),
            ),
            const SizedBox(height: 10),
            Text(
              "Take quizzes to start earning XP\nand climb the leaderboard!",
              style: GoogleFonts.inter(fontSize: 15, color: AppTheme.subtleText, height: 1.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
