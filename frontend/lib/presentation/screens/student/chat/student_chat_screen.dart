import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/data/services/socket_service.dart';

class StudentChatScreen extends ConsumerStatefulWidget {
  final String chatTargetName;
  final String chatTargetType; // 'teacher', 'classmate', 'ai'
  final String chatTargetId;
  final Color accentColor;

  const StudentChatScreen({
    super.key,
    required this.chatTargetName,
    required this.chatTargetType,
    required this.chatTargetId,
    required this.accentColor,
  });

  @override
  ConsumerState<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends ConsumerState<StudentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _conversationId; // active AI conversation thread
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
    if (widget.chatTargetType == 'ai' || data is! Map) return;

    final userId = ref.read(authProvider).user?.id;
    final sender = data['sender']?.toString();
    final receiver = data['receiver']?.toString();
    final targetId = widget.chatTargetId;

    final belongsToThread =
        (sender == userId && receiver == targetId) ||
        (sender == targetId && receiver == userId);

    if (belongsToThread) {
      if (mounted) {
        // If it's our own message, it was already added optimistically in _sendMessage
        // We only need to append if it's from the other person
        if (sender != userId) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': data['content'] ?? '',
              'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
            });
          });
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _loadChatHistory() async {
    if (widget.chatTargetType == 'ai') {
      // Start the AI assistant on a fresh conversation each open.
      // Past threads are reachable via the history button.
      if (mounted) {
        setState(() {
          _messages = [];
          _conversationId = null;
          _isLoading = false;
        });
      }
    } else {
      try {
        final api = ref.read(apiServiceProvider);
        final user = ref.read(authProvider).user;
        final history = await api.getDirectMessageHistory(widget.chatTargetId);
        
        if (mounted) {
          setState(() {
            _messages = history.map<Map<String, dynamic>>((m) {
              final isMe = m['sender'] == user?.id;
              return {
                'role': isMe ? 'user' : 'assistant',
                'content': m['content'] ?? '',
                'createdAt': m['createdAt'] ?? '',
              };
            }).toList();
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    if (widget.chatTargetType == 'ai') {
      try {
        final api = ref.read(apiServiceProvider);
        final result = await api.sendMessage(
          text,
          widget.chatTargetId,
          conversationId: _conversationId,
        );
        if (result != null && mounted) {
          final aiMsg = result['assistantMessage'];
          // Capture the conversation id so the whole thread stays grouped
          _conversationId =
              result['conversationId']?.toString() ?? _conversationId;
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': aiMsg?['content'] ?? 'No response.',
              'createdAt': aiMsg?['createdAt'] ?? DateTime.now().toIso8601String(),
            });
          });
          _scrollToBottom();
        } else if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': 'Sorry, the assistant is unavailable right now. Please try again.',
              'createdAt': DateTime.now().toIso8601String(),
            });
          });
          _scrollToBottom();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'content': 'Sorry, I encountered an error. Please try again.',
              'createdAt': DateTime.now().toIso8601String(),
            });
          });
          _scrollToBottom();
        }
      }
    } else {
      try {
        final api = ref.read(apiServiceProvider);
        await api.sendDirectMessage(text, widget.chatTargetId);
      } catch (e) {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'system',
              'content': 'Failed to send message. Please try again.',
              'createdAt': DateTime.now().toIso8601String(),
            });
          });
          _scrollToBottom();
        }
      }
    }

    if (mounted) setState(() => _isSending = false);
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

  void _startNewConversation() {
    setState(() {
      _messages = [];
      _conversationId = null;
      _isSending = false;
    });
  }

  Future<void> _showConversationHistory() async {
    final api = ref.read(apiServiceProvider);
    final conversations = await api.getAiConversations();
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Conversation History",
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor)),
                  const SizedBox(height: 12),
                  if (conversations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text("No past conversations yet.",
                            style: GoogleFonts.inter(color: AppTheme.subtleText)),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final c = conversations[index] as Map<String, dynamic>;
                          final title =
                              (c['title'] ?? 'New Conversation').toString();
                          final last = (c['lastMessage'] ?? '').toString();
                          return ListTile(
                            leading: const Icon(CupertinoIcons.chat_bubble_text,
                                color: AppTheme.primaryColor),
                            title: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor)),
                            subtitle: Text(last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: AppTheme.subtleText)),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _loadConversation(c['conversationId']?.toString());
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadConversation(String? conversationId) async {
    if (conversationId == null) return;
    setState(() {
      _isLoading = true;
      _conversationId = conversationId;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final history = await api.getChatHistory(
        widget.chatTargetId,
        conversationId: conversationId,
      );
      if (mounted) {
        setState(() {
          _messages = history.map<Map<String, dynamic>>((m) => {
                'role': m['role'] ?? 'user',
                'content': m['content'] ?? '',
                'createdAt': m['createdAt'] ?? '',
              }).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _socketService.off('direct_message', _handleDirectMessage);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isAI = widget.chatTargetType == 'ai';
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.accentColor, widget.accentColor.withOpacity(0.7)]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAI ? CupertinoIcons.sparkles : CupertinoIcons.person_fill,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatTargetName,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isAI ? 'AI-powered study help' : widget.chatTargetType == 'teacher' ? 'Section Adviser' : 'Classmate',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: isAI
          ? [
              IconButton(
                tooltip: 'Conversation history',
                icon: Icon(CupertinoIcons.clock, color: AppTheme.textColor),
                onPressed: _showConversationHistory,
              ),
              IconButton(
                tooltip: 'New conversation',
                icon: Icon(CupertinoIcons.square_pencil, color: AppTheme.textColor),
                onPressed: _startNewConversation,
              ),
            ]
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.borderColor),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final role = msg['role'] as String;

        if (role == 'system') {
          return _buildSystemMessage(msg['content']);
        } else if (role == 'user') {
          return _buildUserBubble(msg['content'], index);
        } else {
          return _buildAssistantBubble(msg['content'], index);
        }
      },
    );
  }

  Widget _buildSystemMessage(String content) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.borderColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          content,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText, fontWeight: FontWeight.w500, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildUserBubble(String content, int index) {
    return FadeInRight(
      delay: Duration(milliseconds: index < 5 ? 50 * index : 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          margin: const EdgeInsets.only(bottom: 8, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.accentColor, widget.accentColor.withOpacity(0.85)],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(color: widget.accentColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Text(
            content,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(String content, int index) {
    return FadeInLeft(
      delay: Duration(milliseconds: index < 5 ? 50 * index : 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: widget.accentColor.withOpacity(0.1),
              child: Icon(
                widget.chatTargetType == 'ai' ? CupertinoIcons.sparkles : CupertinoIcons.person_fill,
                size: 14,
                color: widget.accentColor,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(18),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(
                  content,
                  style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textColor),
                decoration: InputDecoration(
                  hintText: widget.chatTargetType == 'ai' ? 'Ask me about your lessons...' : 'Type a message...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.subtleText.withOpacity(0.6), fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [widget.accentColor, widget.accentColor.withOpacity(0.8)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: widget.accentColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
