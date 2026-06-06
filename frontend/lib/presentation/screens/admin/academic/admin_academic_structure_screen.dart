import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

import 'package:scimathix/presentation/screens/admin/academic/admin_add_school_year_screen.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_grade_levels_screen.dart';
import 'package:scimathix/core/utils/app_logger.dart';

class AdminAcademicStructureScreen extends ConsumerStatefulWidget {
  const AdminAcademicStructureScreen({super.key});

  @override
  ConsumerState<AdminAcademicStructureScreen> createState() => _AdminAcademicStructureScreenState();
}

class _AdminAcademicStructureScreenState extends ConsumerState<AdminAcademicStructureScreen> {
  List<dynamic> _schoolYears = [];
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
      final years = await apiService.getSchoolYears();
      
      if (mounted) {
        setState(() {
          _schoolYears = years;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Fetch Structure', e);
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
          icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
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
            onPressed: () => _showAddSchoolYearDialog(),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchStructure,
            child: _schoolYears.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _schoolYears.length,
              itemBuilder: (context, index) {
                return _buildYearCard(_schoolYears[index], index);
              },
            ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.calendar, size: 64, color: AppTheme.subtleText.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No Academic Years Yet",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.subtleText),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the + icon to add one.",
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildYearCard(Map<String, dynamic> yearData, int index) {
    return FadeInUp(
      delay: Duration(milliseconds: index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminGradeLevelsScreen(
                  schoolYear: yearData['year'] ?? "Unknown",
                ),
              ),
            ).then((_) => _fetchStructure());
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.calendar, color: AppTheme.primaryColor, size: 20),
          ),
          title: Text(
            "SY ${yearData['year'] ?? "Unknown Year"}",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textColor,
            ),
          ),
          subtitle: Text(
            "Tap to manage grade levels & sections",
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: AppTheme.subtleText,
          ),
        ),
      ),
    );
  }

  void _showAddSchoolYearDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminAddSchoolYearScreen()),
    ).then((value) {
      if (value == true) _fetchStructure();
    });
  }
}
