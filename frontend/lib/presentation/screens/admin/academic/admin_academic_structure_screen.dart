import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_section_details_screen.dart';

import 'package:scimathix/presentation/screens/admin/academic/admin_add_level_screen.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_add_section_screen.dart';

class AdminAcademicStructureScreen extends ConsumerStatefulWidget {
  const AdminAcademicStructureScreen({super.key});

  @override
  ConsumerState<AdminAcademicStructureScreen> createState() => _AdminAcademicStructureScreenState();
}

class _AdminAcademicStructureScreenState extends ConsumerState<AdminAcademicStructureScreen> {
  List<dynamic> _levels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStructure();
  }

  Future<void> _fetchStructure() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final levels = await apiService.getLevels();
      
      // For each level, fetch its sections
      List<Map<String, dynamic>> enrichedLevels = [];
      for (var level in levels) {
        final sections = await apiService.getSections(level['_id']);
        enrichedLevels.add({
          ...level,
          "sections": sections,
          "isOpen": false,
        });
      }

      if (mounted) {
        setState(() {
          _levels = enrichedLevels;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fetch Structure Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Academic Structure",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled, color: AppTheme.primaryColor),
            onPressed: () => _showAddLevelDialog(),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStructure,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _levels.length,
              itemBuilder: (context, index) {
                return _buildLevelCard(_levels[index], index);
              },
            ),
          ),
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> level, int index) {
    final sections = level['sections'] as List<dynamic>? ?? [];
    
    return FadeInUp(
      delay: Duration(milliseconds: index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                setState(() {
                  level['isOpen'] = !(level['isOpen'] ?? false);
                });
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.layers, color: AppTheme.primaryColor, size: 20),
              ),
              title: Text(
                level['name'] ?? "Unknown Level",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textColor,
                ),
              ),
              subtitle: Text(
                "${sections.length} Sections",
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
              ),
              trailing: Icon(
                (level['isOpen'] ?? false) ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                size: 16,
                color: AppTheme.subtleText,
              ),
            ),
            if (level['isOpen'] ?? false) ...[
              const Divider(height: 1, color: AppTheme.borderColor),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ...sections.map((section) => _buildSectionItem(section, level['name'])).toList(),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _showAddSectionDialog(index),
                      icon: const Icon(CupertinoIcons.add, size: 14),
                      label: const Text("Add Section"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem(Map<String, dynamic> section, String levelName) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminSectionDetailsScreen(
              levelName: levelName,
              sectionName: section['name'],
              sectionId: section['_id'],
            ),
          ),
        ).then((_) => _fetchStructure());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.group, size: 16, color: AppTheme.secondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                section['name'] ?? "",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.trash, size: 14, color: Colors.redAccent),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLevelDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAddLevelScreen()),
    ).then((value) {
      if (value == true) _fetchStructure();
    });
  }

  void _showAddSectionDialog(int levelIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddSectionScreen(
          levelId: _levels[levelIndex]['_id'],
          levelName: _levels[levelIndex]['name'],
        ),
      ),
    ).then((value) {
      if (value == true) _fetchStructure();
    });
  }
}
