import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class LessonCard extends StatelessWidget {
  final String title;
  final String description;
  final String duration;
  final double progress;
  final Color themeColor;
  final VoidCallback onTap;
  final bool isSaved;
  final bool isDownloaded;
  final VoidCallback? onSaveTap;
  final VoidCallback? onDownloadTap;

  const LessonCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.progress,
    required this.themeColor,
    required this.onTap,
    this.isSaved = false,
    this.isDownloaded = false,
    this.onSaveTap,
    this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CupertinoIcons.book, color: themeColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: AppTheme.subtleText,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onSaveTap != null || onDownloadTap != null)
                  Column(
                    children: [
                      if (onSaveTap != null)
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isSaved ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                            color: isSaved ? themeColor : AppTheme.subtleText,
                            size: 20,
                          ),
                          onPressed: onSaveTap,
                        ),
                      if (onDownloadTap != null) ...[
                        const SizedBox(height: 12),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isDownloaded ? CupertinoIcons.cloud_download_fill : CupertinoIcons.cloud_download,
                            color: isDownloaded ? themeColor : AppTheme.subtleText,
                            size: 20,
                          ),
                          onPressed: onDownloadTap,
                        ),
                      ]
                    ],
                  )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(CupertinoIcons.clock, size: 14, color: AppTheme.subtleText),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: GoogleFonts.inter(
                    color: AppTheme.subtleText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  "${(progress * 100).toInt()}% Completed",
                  style: GoogleFonts.inter(
                    color: AppTheme.subtleText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
