import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  final String? lessonId;
  const AiChatScreen({super.key, this.lessonId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "ai", "text": "Hi! I'm your SCIMATHIX AI assistant. Ask me anything about Math or Science! 🧪"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg["role"] == "ai";
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
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isAi ? AppTheme.textColor : Colors.white,
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
      decoration: const BoxDecoration(
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
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                setState(() {
                  _messages.add({"role": "user", "text": _messageController.text.trim()});
                  _messages.add({"role": "ai", "text": "Great question! Let me think about that... This feature will be powered by the AI backend once integrated."});
                  _messageController.clear();
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
