import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/data/services/socket_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentChatScreen extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  final String studentEmail;

  const StudentChatScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
  });

  @override
  ConsumerState<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends ConsumerState<StudentChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<_ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _socketService.initSocket();
    _socketService.on('direct_message', _handleDirectMessage);
    Future.microtask(() => _loadChatHistory());
  }

  void _handleDirectMessage(dynamic data) {
    if (data is! Map) return;

    final userId = ref.read(authProvider).user?.id;
    final sender = data['sender']?.toString();
    final receiver = data['receiver']?.toString();
    final studentId = widget.studentId;

    final belongsToThread =
        (sender == userId && receiver == studentId) ||
        (sender == studentId && receiver == userId);

    if (belongsToThread) _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final api = ref.read(apiServiceProvider);
      final user = ref.read(authProvider).user;
      final history = await api.getDirectMessageHistory(widget.studentId);
      
      if (mounted) {
        setState(() {
          _messages = history.map<_ChatMessage>((m) {
            final isTeacher = m['sender'] == user?.id;
            return _ChatMessage(
              text: m['content'] ?? '',
              isTeacher: isTeacher,
              time: m['createdAt'] != null ? DateTime.parse(m['createdAt']).toLocal() : DateTime.now(),
            );
          }).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socketService.off('direct_message', _handleDirectMessage);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isTeacher: true,
        time: DateTime.now(),
      ));
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      await api.sendDirectMessage(text, widget.studentId);
    } catch (e) {
      // Could show error
    }

    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leadingWidth: 36,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  initial,
                  style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.studentName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textColor, letterSpacing: -0.3),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Student",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _messages.isEmpty
                ? Center(
                    child: FadeInUp(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Icon(CupertinoIcons.chat_bubble_2, size: 48, color: AppTheme.subtleText.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 24),
                          Text("Start the conversation", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: AppTheme.textColor)),
                          const SizedBox(height: 8),
                          Text("Send a message to ${widget.studentName.split(' ').first}.", style: GoogleFonts.inter(fontSize: 14, color: AppTheme.subtleText)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageBubble(msg, initial);
                    },
                  ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 12,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textColor),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: GoogleFonts.inter(color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF1ABC9C)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, String studentInitial) {
    final isMe = msg.isTeacher;
    final timeStr = "${msg.time.hour > 12 ? msg.time.hour - 12 : (msg.time.hour == 0 ? 12 : msg.time.hour)}:${msg.time.minute.toString().padLeft(2, '0')} ${msg.time.hour >= 12 ? 'PM' : 'AM'}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(studentInitial, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                border: isMe ? null : Border.all(color: AppTheme.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isMe ? AppTheme.primaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isMe ? Colors.white : AppTheme.textColor,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeStr,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.7) : AppTheme.subtleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(CupertinoIcons.person_solid, color: AppTheme.primaryColor, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isTeacher;
  final DateTime time;

  _ChatMessage({required this.text, required this.isTeacher, required this.time});
}
