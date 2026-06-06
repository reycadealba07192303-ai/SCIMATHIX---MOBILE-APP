import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/data/services/socket_service.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupSocket();
  }

  void _setupSocket() {
    _socketService = ref.read(socketServiceProvider);
    _socketService.initSocket();

    _socketService.on('new_notification', (data) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, data);
        });
      }
    });
  }

  @override
  void dispose() {
    _socketService.off('new_notification');
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    final apiService = ref.read(apiServiceProvider);
    final data = await apiService.getNotifications('ADMIN');
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'announcement':
        return CupertinoIcons.speaker_2_fill;
      case 'alert':
        return CupertinoIcons.exclamationmark_triangle_fill;
      default:
        return CupertinoIcons.bell_fill;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'announcement':
        return AppTheme.primaryColor;
      case 'alert':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
      if (diff.inDays < 1) return '${diff.inHours} hours ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return '';
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
          "System Notifications",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh, color: AppTheme.textColor),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchNotifications();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.bell_slash, color: AppTheme.subtleText.withOpacity(0.4), size: 50),
                      const SizedBox(height: 16),
                      Text(
                        "No notifications yet",
                        style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Notifications will appear here in real-time",
                        style: GoogleFonts.inter(color: AppTheme.subtleText.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isRead = notif['isRead'] == true;
                      final color = _getColor(notif['type']);
                      final icon = _getIcon(notif['type']);

                      return FadeInUp(
                        delay: Duration(milliseconds: (index < 10) ? index * 60 : 0),
                        child: GestureDetector(
                          onTap: () => _showNotificationDetail(notif),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? AppTheme.surfaceColor
                                  : AppTheme.primaryColor.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isRead ? AppTheme.borderColor : AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
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
                                              notif['title'] ?? 'Notification',
                                              style: GoogleFonts.inter(
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                                fontSize: 14,
                                                color: AppTheme.textColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            _formatTime(notif['timestamp']),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppTheme.subtleText,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['message'] ?? '',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.subtleText,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (!isRead)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "NEW",
                                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showNotificationDetail(Map<String, dynamic> notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.subtleText.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColor(notif['type']).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(notif['type']), color: _getColor(notif['type']), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['title'] ?? 'Notification',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textColor),
                      ),
                      Text(
                        _formatTime(notif['timestamp']),
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              notif['message'] ?? '',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textColor, height: 1.6),
            ),
            if (notif['target'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Target: ${notif['target']}",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
