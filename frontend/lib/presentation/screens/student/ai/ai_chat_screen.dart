import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  const AiChatScreen({super.key, this.lessonId});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "assistant", "text": "Hi! I'm your SCIMATHIX AI assistant. Ask me anything about Math or Science! 🧪"},
  ];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (widget.lessonId == null) return;
    setState(() => _isLoading = true);
    final api = ref.read(apiServiceProvider);
    final history = await api.getChatHistory(widget.lessonId!);
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages.clear();
        for (var msg in history) {
          _messages.add({
            "role": msg['role'] == 'user' ? 'user' : 'assistant',
            "text": msg['content'] ?? '',
          });
        }
      });
      _scrollToBottom();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryColor, size: 16),
            ),
            const SizedBox(width: 10),
            Text("AI Assistant", style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.length <= 1
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isAi = msg["role"] == "assistant" || msg["role"] == "ai";
                      return FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: _buildMessageBubble(msg["text"]!, isAi),
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAi ? AppTheme.surfaceColor : AppTheme.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAi ? 4 : 16),
            bottomRight: Radius.circular(isAi ? 16 : 4),
          ),
          border: isAi ? Border.all(color: AppTheme.borderColor) : null,
        ),
        child: isAi
          ? MarkdownBody(
              data: text,
              shrinkWrap: true,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(
                  color: AppTheme.textColor,
                  fontSize: 15,
                  height: 1.5,
                ),
                strong: GoogleFonts.inter(
                  color: AppTheme.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
                em: GoogleFonts.inter(
                  color: AppTheme.textColor,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                listBullet: GoogleFonts.inter(
                  color: AppTheme.textColor,
                  fontSize: 15,
                  height: 1.5,
                ),
                code: GoogleFonts.inter(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                ),
              ),
            )
          : Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Ask a question...",
                  hintStyle: GoogleFonts.inter(color: AppTheme.subtleText),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isLoading ? null : () async {
              if (_messageController.text.trim().isNotEmpty && widget.lessonId != null) {
                final text = _messageController.text.trim();
                setState(() {
                  _messages.add({"role": "user", "text": text});
                  _messageController.clear();
                  _isLoading = true;
                });
                _scrollToBottom();
                
                final api = ref.read(apiServiceProvider);
                final res = await api.sendMessage(text, widget.lessonId);
                
                if (mounted) {
                  setState(() {
                    if (res != null && res['assistantMessage'] != null) {
                      _messages.add({
                        "role": "assistant",
                        "text": res['assistantMessage']['content'] ?? "I didn't understand that."
                      });
                    } else {
                      _messages.add({
                        "role": "assistant",
                        "text": "Sorry, I'm having trouble connecting to the server."
                      });
                    }
                    _isLoading = false;
                  });
                  _scrollToBottom();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLoading ? AppTheme.subtleText : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
