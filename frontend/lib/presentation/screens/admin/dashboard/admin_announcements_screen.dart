import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final List<Map<String, String>> _announcements = [
    {
      "title": "Welcome to SCIMATHIX v1.0",
      "content": "The system is now live for all teachers and students. Please make sure all accounts are verified.",
      "date": "May 25, 2026",
      "author": "System Admin"
    },
    {
      "title": "Scheduled Maintenance",
      "content": "There will be a scheduled downtime this weekend for server upgrades. Please save all your work.",
      "date": "May 20, 2026",
      "author": "IT Department"
    }
  ];

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateAnnouncementDialog(
        onSubmit: (data) {
          setState(() {
            _announcements.insert(0, {
              "title": data['title'],
              "content": "${data['description']}\n\nTarget: ${data['target']}\nWhen: ${data['date']} at ${data['time']}",
              "date": "Just now",
              "author": "System Admin"
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event Published!"), backgroundColor: Colors.green),
          );
        },
      ),
    );
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
          "Announcements",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _announcements.isEmpty
          ? Center(
              child: Text(
                "No announcements yet.",
                style: GoogleFonts.inter(color: AppTheme.subtleText),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(CupertinoIcons.speaker_2_fill, color: AppTheme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    announcement['title']!,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textColor),
                                  ),
                                  Text(
                                    "${announcement['date']} • By ${announcement['author']}",
                                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          announcement['content']!,
                          style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textColor, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text("New Post", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _CreateAnnouncementDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const _CreateAnnouncementDialog({required this.onSubmit});

  @override
  State<_CreateAnnouncementDialog> createState() => _CreateAnnouncementDialogState();
}

class _CreateAnnouncementDialogState extends State<_CreateAnnouncementDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedTarget = 'OVERALL';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _submit() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    final dateStr = "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}";
    final timeStr = _selectedTime!.format(context);

    widget.onSubmit({
      'title': _titleController.text,
      'target': _selectedTarget,
      'date': dateStr,
      'time': timeStr,
      'description': _descriptionController.text,
    });
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.speaker_2_fill, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Publish Event",
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              Text("EVENT TITLE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Enter event title...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Target Audience
              Text("TARGET AUDIENCE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTarget,
                    isExpanded: true,
                    icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                    items: ['OVERALL', 'STUDENT ONLY', 'TEACHER ONLY'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: GoogleFonts.inter(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTarget = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("DATE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.calendar, size: 16, color: AppTheme.subtleText),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null 
                                        ? "Select Date" 
                                        : "${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}",
                                    style: GoogleFonts.inter(fontSize: 13, color: _selectedDate == null ? AppTheme.subtleText : AppTheme.textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("TIME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.clock, size: 16, color: AppTheme.subtleText),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedTime == null 
                                        ? "Select Time" 
                                        : _selectedTime!.format(context),
                                    style: GoogleFonts.inter(fontSize: 13, color: _selectedTime == null ? AppTheme.subtleText : AppTheme.textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              Text("DESCRIPTION", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Enter event description...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Publish Now", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

