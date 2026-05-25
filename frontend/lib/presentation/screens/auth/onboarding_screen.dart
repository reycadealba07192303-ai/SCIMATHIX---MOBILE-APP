import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/presentation/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Interactive Learning",
      description: "Master Mathematics and Science with our AI-powered interactive modules.",
      icon: Icons.biotech_outlined,
      color: AppTheme.primaryColor,
    ),
    OnboardingData(
      title: "AI-Generated Quizzes",
      description: "Test your knowledge with personalized quizzes designed to help you improve.",
      icon: Icons.psychology_outlined,
      color: AppTheme.primaryColor,
    ),
    OnboardingData(
      title: "Gamified Progress",
      description: "Earn XP, badges, and climb the leaderboard while mastering complex topics.",
      icon: Icons.workspace_premium_outlined,
      color: AppTheme.primaryColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            ),
            
            // Navigation Controls
            Positioned(
              bottom: 40,
              left: 32,
              right: 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? AppTheme.primaryColor 
                              : AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  
                  // Next/Get Started Button
                  FadeInRight(
                    child: GestureDetector(
                      onTap: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.of(context).pushReplacementNamed('/root');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? "Get Started" : "Next",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Skip Button
            if (_currentPage < _pages.length - 1)
              Positioned(
                top: 20,
                right: 20,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/root');
                  },
                  child: Text(
                    "Skip",
                    style: GoogleFonts.inter(
                      color: AppTheme.subtleText,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoomIn(
            duration: const Duration(milliseconds: 600),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                data.icon,
                size: 80,
                color: data.color,
              ),
            ),
          ),
          const SizedBox(height: 64),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.subtleText,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 80), // Space for bottom controls
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
