import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class LessonSearchScreen extends StatefulWidget {
  const LessonSearchScreen({super.key});

  @override
  State<LessonSearchScreen> createState() => _LessonSearchScreenState();
}

class _LessonSearchScreenState extends State<LessonSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Search for lessons, topics...",
                          hintStyle: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 15),
                          prefixIcon: const Icon(CupertinoIcons.search, color: AppTheme.subtleText, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(CupertinoIcons.clear_thick_circled, color: AppTheme.subtleText, size: 16),
                            onPressed: () => _searchController.clear(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Results / Recent
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    "Recent Searches",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.subtleText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentSearch("Algebra equations"),
                  _buildRecentSearch("Newton's third law"),
                  _buildRecentSearch("Cell division"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearch(String text) {
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const Icon(CupertinoIcons.time, color: AppTheme.subtleText, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: AppTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(CupertinoIcons.arrow_up_left, color: AppTheme.borderColor, size: 16),
          ],
        ),
      ),
    );
  }
}
