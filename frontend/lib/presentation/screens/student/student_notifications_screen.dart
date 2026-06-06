import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/data/services/api_service.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    // Backend returns OVERALL + the requested target.
    final raw = await _api.getNotifications('STUDENT ONLY');
    final mapped = raw
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
    mapped.sort((a, b) {
      final da = DateTime.tryParse(a['timestamp']?.toString() ?? '') ??
          DateTime(1970);
      final db = DateTime.tryParse(b['timestamp']?.toString() ?? '') ??
          DateTime(1970);
      return db.compareTo(da);
    });
    if (mounted) {
      setState(() {
        _notifications = mapped;
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['isRead'] == true) return;
    final id = n['_id']?.toString();
    if (id == null) return;
    setState(() => n['isRead'] = true);
    await _api.markNotificationAsRead(id);
  }

  String _bucketFor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Older';
  }

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };
    for (final n in _notifications) {
      final date =
          DateTime.tryParse(n['timestamp']?.toString() ?? '') ?? DateTime.now();
      map[_bucketFor(date)]!.add(n);
    }
    map.removeWhere((key, value) => value.isEmpty);
    return map;
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'announcement':
        return CupertinoIcons.speaker_2_fill;
      case 'alert':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'classroom_announcement':
        return CupertinoIcons.book_fill;
      default:
        return CupertinoIcons.bell_fill;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'announcement':
        return AppTheme.primaryColor;
      case 'alert':
        return Colors.redAccent;
      case 'classroom_announcement':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.accentColor;
    }
  }

  String _formatTime(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    final local = d.toLocal();
    final h = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return "$h:$m $ampm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(CupertinoIcons.arrow_left,
              color: AppTheme.textColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.inter(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh,
                color: AppTheme.textColor, size: 22),
            onPressed: _isLoading ? null : _fetch,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _fetch,
                    color: AppTheme.primaryColor,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        for (final entry in _grouped.entries) ...[
                          _buildSectionHeader(entry.key),
                          const SizedBox(height: 16),
                          ...entry.value.map(_buildTile),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.bell_slash,
              color: AppTheme.subtleText, size: 48),
          const SizedBox(height: 12),
          Text("No notifications yet.",
              style: GoogleFonts.inter(color: AppTheme.subtleText)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return FadeInLeft(
      duration: const Duration(milliseconds: 400),
      child: Text(
        title,
        style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.subtleText,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> n) {
    final isUnread = n['isRead'] != true;
    final color = _colorFor(n['type']?.toString());
    final icon = _iconFor(n['type']?.toString());

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: () => _markRead(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? color.withValues(alpha: 0.05)
                : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? color.withValues(alpha: 0.3)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            n['title']?.toString() ?? 'Notification',
                            style: GoogleFonts.inter(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                          ),
                        ),
                        Text(
                          _formatTime(n['timestamp']),
                          style: GoogleFonts.inter(
                              color: AppTheme.subtleText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['message']?.toString() ?? '',
                      style: GoogleFonts.inter(
                          color: AppTheme.subtleText,
                          fontSize: 14,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 12),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
