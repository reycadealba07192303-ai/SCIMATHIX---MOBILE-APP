import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/data/services/api_service.dart';
import 'package:scimathix/data/services/socket_service.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AdminUserLogsScreen extends ConsumerStatefulWidget {
  const AdminUserLogsScreen({super.key});

  @override
  ConsumerState<AdminUserLogsScreen> createState() => _AdminUserLogsScreenState();
}

class _AdminUserLogsScreenState extends ConsumerState<AdminUserLogsScreen> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _setupSocket();
  }

  void _setupSocket() {
    final socketService = ref.read(socketServiceProvider);
    socketService.initSocket();
    
    socketService.on('new_log', (data) {
      if (mounted) {
        setState(() {
          _logs.insert(0, data);
        });
      }
    });
  }

  @override
  void dispose() {
    final socketService = ref.read(socketServiceProvider);
    socketService.off('new_log');
    socketService.disconnect();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    final apiService = ref.read(apiServiceProvider);
    final logs = await apiService.getLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  IconData _getIcon(String iconStr) {
    switch (iconStr) {
      case 'settings': return CupertinoIcons.settings;
      case 'book': return CupertinoIcons.book;
      case 'checkmark': return CupertinoIcons.checkmark_alt;
      case 'login': return CupertinoIcons.arrow_right_square;
      case 'warning': return CupertinoIcons.exclamationmark_triangle;
      default: return CupertinoIcons.info;
    }
  }

  Color _getColor(String colorStr) {
    switch (colorStr) {
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      case 'red': return Colors.red;
      case 'purple': return AppTheme.primaryColor;
      default: return Colors.blue;
    }
  }

  String _formatTime(String timestamp) {
    final date = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        title: Text(
          "User Logs",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchLogs();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Text(
                    "No logs found.",
                    style: GoogleFonts.inter(color: AppTheme.subtleText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final color = _getColor(log['color'] ?? 'blue');
                    final icon = _getIcon(log['icon'] ?? 'info');
                    
                    return FadeInUp(
                      delay: Duration(milliseconds: (index < 10) ? index * 50 : 0),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
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
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textColor),
                                      children: [
                                        TextSpan(text: "${log['user']} ", style: const TextStyle(fontWeight: FontWeight.w700)),
                                        TextSpan(
                                          text: "(${log['role']}) ",
                                          style: TextStyle(color: AppTheme.subtleText, fontSize: 12),
                                        ),
                                        TextSpan(text: log['action']),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log['timestamp'] != null ? _formatTime(log['timestamp']) : 'Unknown time',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

