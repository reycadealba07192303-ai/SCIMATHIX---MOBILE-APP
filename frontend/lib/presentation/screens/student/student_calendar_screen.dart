import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  int _selectedDay = 14; // Mock selected day

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: AppTheme.textColor, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Calendar",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.search, color: AppTheme.textColor, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildWeekCalendar(),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  FadeInLeft(
                    child: Text(
                      "Upcoming Schedule",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTimelineEvent(
                    time: "10:00 AM",
                    title: "Geometry Fundamentals Quiz",
                    subject: "Mathematics",
                    duration: "45 mins",
                    color: AppTheme.primaryColor,
                    icon: CupertinoIcons.timer,
                  ),
                  _buildTimelineEvent(
                    time: "02:00 PM",
                    title: "Cell Structure Final Project",
                    subject: "Science",
                    duration: "Deadline",
                    color: AppTheme.secondaryColor,
                    icon: CupertinoIcons.doc_checkmark,
                  ),
                  _buildTimelineEvent(
                    time: "04:30 PM",
                    title: "AI Study Session",
                    subject: "Review",
                    duration: "30 mins",
                    color: AppTheme.accentColor,
                    icon: CupertinoIcons.sparkles,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<int> dates = [12, 13, 14, 15, 16, 17, 18];

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            bottom: BorderSide(color: AppTheme.borderColor),
          ),
        ),
        child: Column(
          children: [
            Text(
              "May 2026",
              style: GoogleFonts.inter(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final isSelected = dates[index] == _selectedDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = dates[index];
                      });
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            days[index],
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : AppTheme.subtleText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dates[index].toString(),
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : AppTheme.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineEvent({
    required String time,
    required String title,
    required String subject,
    required String duration,
    required Color color,
    required IconData icon,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Column
            SizedBox(
              width: 70,
              child: Text(
                time,
                style: GoogleFonts.inter(
                  color: AppTheme.subtleText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            
            // Timeline Line & Dot
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.backgroundColor, width: 2),
                  ),
                ),
                Container(
                  width: 2,
                  height: 100, // Fixed height for visual consistency
                  color: AppTheme.borderColor,
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Event Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subject,
                            style: GoogleFonts.inter(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(icon, color: AppTheme.subtleText, size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(CupertinoIcons.clock, size: 12, color: AppTheme.subtleText),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: GoogleFonts.inter(
                            color: AppTheme.subtleText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
