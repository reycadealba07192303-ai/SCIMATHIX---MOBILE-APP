import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class StudentCalendarScreen extends ConsumerStatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  ConsumerState<StudentCalendarScreen> createState() =>
      _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends ConsumerState<StudentCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _weekStart;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _events = const [];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - DateTime.monday),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchEvents());
  }

  Future<void> _fetchEvents() async {
    final sectionId = ref.read(authProvider).user?.section;
    if (sectionId == null || sectionId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'You are not assigned to a section yet.';
        _events = const [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final raw = await api.getCalendarAnnouncements(sectionId);
      final mapped = raw.whereType<Map>().map((e) {
        return e.map((k, v) => MapEntry(k.toString(), v));
      }).toList();
      if (!mounted) return;
      setState(() {
        _events = mapped;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load events.';
        _events = const [];
      });
    }
  }

  List<Map<String, dynamic>> get _eventsForSelectedDay {
    final result = _events.where((e) {
      final dateStr = e['scheduledDate']?.toString();
      if (dateStr == null) return false;
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return false;
      final local = parsed.toLocal();
      return local.year == _selectedDate.year &&
          local.month == _selectedDate.month &&
          local.day == _selectedDate.day;
    }).toList();

    int compareEvents(Map<String, dynamic> a, Map<String, dynamic> b) {
      final timeA = (a['scheduledTime'] ?? '').toString();
      final timeB = (b['scheduledTime'] ?? '').toString();
      if (timeA.isEmpty && timeB.isEmpty) return 0;
      if (timeA.isEmpty) return 1;
      if (timeB.isEmpty) return -1;
      return timeA.compareTo(timeB);
    }

    result.sort(compareEvents);
    return result;
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
          "Calendar",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh,
                color: AppTheme.textColor, size: 22),
            onPressed: _isLoading ? null : _fetchEvents,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildWeekCalendar(),
            const SizedBox(height: 24),
            Expanded(child: _buildEventsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildEmptyState(_error!);
    }

    final events = _eventsForSelectedDay;
    if (events.isEmpty) {
      return _buildEmptyState(
        'No scheduled events for this day.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        FadeInLeft(
          child: Text(
            "Scheduled for ${_formatSelectedDate()}",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (final e in events) _buildEventCard(e),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.calendar,
                color: AppTheme.subtleText, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.subtleText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSelectedDate() {
    final m = _monthNames[_selectedDate.month - 1];
    return '$m ${_selectedDate.day}, ${_selectedDate.year}';
  }

  Color _colorForEvent(Map<String, dynamic> event) {
    final source = event['source']?.toString();
    if (source == 'notification') return AppTheme.accentColor;
    final subject = event['subject'];
    if (subject is Map) {
      final category = subject['category']?.toString().toLowerCase();
      if (category == 'science') return AppTheme.secondaryColor;
      if (category == 'mathematics') return AppTheme.primaryColor;
    }
    return AppTheme.primaryColor;
  }

  String _subjectTag(Map<String, dynamic> event) {
    final source = event['source']?.toString();
    if (source == 'notification') return 'School-wide';
    final subject = event['subject'];
    if (subject is Map) {
      final name = subject['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
      final category = subject['category']?.toString();
      if (category != null && category.isNotEmpty) return category;
    }
    return 'Class';
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final color = _colorForEvent(event);
    final subjectTag = _subjectTag(event);
    final title = (event['title']?.toString().trim().isNotEmpty == true)
        ? event['title'].toString()
        : 'Announcement';
    final time = (event['scheduledTime']?.toString().trim().isNotEmpty == true)
        ? event['scheduledTime'].toString()
        : 'All day';
    final description = event['content']?.toString() ?? '';
    final teacher = event['teacher'];
    final teacherName =
        teacher is Map ? (teacher['name']?.toString() ?? '') : '';

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppTheme.backgroundColor, width: 2),
                  ),
                ),
                Container(
                  width: 2,
                  height: 100,
                  color: AppTheme.borderColor,
                ),
              ],
            ),
            const SizedBox(width: 16),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            subjectTag,
                            style: GoogleFonts.inter(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(CupertinoIcons.bell_solid,
                            color: AppTheme.subtleText, size: 16),
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
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: AppTheme.subtleText,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (teacherName.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(CupertinoIcons.person,
                              size: 12, color: AppTheme.subtleText),
                          const SizedBox(width: 4),
                          Text(
                            teacherName,
                            style: GoogleFonts.inter(
                              color: AppTheme.subtleText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final dates = List<DateTime>.generate(
      7,
      (i) => _weekStart.add(Duration(days: i)),
    );
    final monthLabel =
        '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            bottom: BorderSide(color: AppTheme.borderColor),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(CupertinoIcons.chevron_left,
                      color: AppTheme.subtleText, size: 18),
                  onPressed: () {
                    setState(() {
                      _weekStart =
                          _weekStart.subtract(const Duration(days: 7));
                    });
                  },
                ),
                Text(
                  monthLabel,
                  style: GoogleFonts.inter(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: Icon(CupertinoIcons.chevron_right,
                      color: AppTheme.subtleText, size: 18),
                  onPressed: () {
                    setState(() {
                      _weekStart = _weekStart.add(const Duration(days: 7));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(date.year, date.month, date.day);
                      });
                    },
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayLabels[index],
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.subtleText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            date.day.toString(),
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textColor,
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
}
