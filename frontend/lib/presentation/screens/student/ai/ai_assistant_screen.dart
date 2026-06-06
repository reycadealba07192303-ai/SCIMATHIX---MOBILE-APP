import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/student/ai/ai_chat_screen.dart';
import 'package:scimathix/presentation/screens/student/ai/ai_recommended_screen.dart';
import 'package:scimathix/presentation/screens/student/ai/weak_topics_screen.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "AI Assistant",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FadeInDown(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.sparkles, color: AppTheme.primaryColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "How can I help you today?",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Ask questions, get explanations, or explore AI-powered study tools.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.subtleText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureCard(
              context,
              icon: CupertinoIcons.chat_bubble_2,
              title: "Ask a Question",
              description: "Chat with the AI to get instant answers and explanations.",
              color: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AiChatScreen()));
              },
            ),
            _buildFeatureCard(
              context,
              icon: CupertinoIcons.lightbulb,
              title: "Recommended Activities",
              description: "Get personalized activity suggestions based on your progress.",
              color: AppTheme.secondaryColor,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AiRecommendedScreen()));
              },
            ),
            _buildFeatureCard(
              context,
              icon: CupertinoIcons.exclamationmark_triangle,
              title: "Weak Topics",
              description: "Identify areas where you need improvement and get study plans.",
              color: AppTheme.accentColor,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WeakTopicsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(description, style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              Icon(CupertinoIcons.chevron_right, color: AppTheme.borderColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
