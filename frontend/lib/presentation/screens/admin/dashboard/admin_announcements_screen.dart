import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/data/services/api_service.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    final notifications = await _apiService.getNotifications('ADMIN');
    final announcements =
        notifications.where((n) => n['type'] == 'announcement').toList();
    if (mounted) {
      setState(() {
        _announcements = announcements;
        _isLoading = false;
      });
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _AnnouncementFormDialog(
        onSubmit: (data) async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Publishing…"),
                backgroundColor: AppTheme.primaryColor),
          );
          final success = await _apiService.createNotification(
            title: data['title'],
            message:
                "${data['description']}\n\nWhen: ${data['date']} at ${data['time']}",
            target: data['target'],
            type: 'announcement',
          );
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Event Published!"),
                  backgroundColor: Colors.green),
            );
            _fetchAnnouncements();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Failed to publish event"),
                  backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => _EditAnnouncementDialog(
        announcement: announcement,
        onSubmit: (data) async {
          final success = await _apiService.updateNotification(
            announcement['_id'],
            title: data['title'],
            message: data['message'],
            target: data['target'],
          );
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Updated successfully"),
                  backgroundColor: Colors.green),
            );
            _fetchAnnouncements();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Failed to update"),
                  backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Announcement",
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppTheme.textColor)),
        content: Text(
          'Are you sure you want to delete "${announcement['title'] ?? 'this announcement'}"?',
          style:
              GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 14),
        ),
        actions: [
          // Side-by-side buttons using Row + two Expanded
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side:
                          BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel",
                        style: GoogleFonts.inter(
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await _apiService
                          .deleteNotification(announcement['_id']);
                      if (!mounted) return;
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Deleted"),
                              backgroundColor: Colors.green),
                        );
                        _fetchAnnouncements();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Failed to delete"),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Text("Delete",
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        iconTheme: IconThemeData(color: AppTheme.textColor),
        title: Text(
          "Announcements",
          style: GoogleFonts.inter(
              color: AppTheme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.speaker_slash,
                          color: AppTheme.subtleText, size: 48),
                      const SizedBox(height: 12),
                      Text("No announcements yet.",
                          style: GoogleFonts.inter(
                              color: AppTheme.subtleText)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAnnouncements,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final a = _announcements[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 80),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppTheme.borderColor),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        CupertinoIcons
                                            .speaker_2_fill,
                                        color: AppTheme.primaryColor,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a['title'] ?? 'Announcement',
                                          style: GoogleFonts.inter(
                                              fontWeight:
                                                  FontWeight.w700,
                                              fontSize: 16,
                                              color:
                                                  AppTheme.textColor),
                                        ),
                                        Text(
                                          a['target'] ?? 'OVERALL',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color:
                                                  AppTheme.subtleText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ⋮ popup menu
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                        CupertinoIcons.ellipsis_vertical,
                                        color: AppTheme.subtleText,
                                        size: 20),
                                    color: AppTheme.surfaceColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditDialog(a);
                                      } else if (value == 'delete') {
                                        _showDeleteDialog(a);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [
                                          Icon(
                                              CupertinoIcons.pencil,
                                              size: 18,
                                              color: AppTheme.textColor),
                                          const SizedBox(width: 8),
                                          Text("Edit",
                                              style: GoogleFonts.inter(
                                                  color: AppTheme
                                                      .textColor)),
                                        ]),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          const Icon(CupertinoIcons.trash,
                                              size: 18,
                                              color: Colors.redAccent),
                                          const SizedBox(width: 8),
                                          Text("Delete",
                                              style: GoogleFonts.inter(
                                                  color:
                                                      Colors.redAccent)),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                a['message'] ?? '',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.textColor,
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(CupertinoIcons.add, color: Colors.white),
        label: const Text("New Post",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─── Create dialog ───────────────────────────────────────────────────────────

class _AnnouncementFormDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  const _AnnouncementFormDialog({required this.onSubmit});

  @override
  State<_AnnouncementFormDialog> createState() =>
      _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState
    extends State<_AnnouncementFormDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _target = 'OVERALL';
  DateTime? _date;
  TimeOfDay? _time;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => _time = t);
  }

  void _submit() {
    if (_titleCtrl.text.isEmpty ||
        _descCtrl.text.isEmpty ||
        _date == null ||
        _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please fill all fields"),
            backgroundColor: Colors.red),
      );
      return;
    }
    final dateStr =
        "${_date!.month}/${_date!.day}/${_date!.year}";
    final timeStr = _time!.format(context);
    widget.onSubmit({
      'title': _titleCtrl.text.trim(),
      'target': _target,
      'date': dateStr,
      'time': timeStr,
      'description': _descCtrl.text.trim(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _buildDialog(
      title: "Publish Event",
      titleCtrl: _titleCtrl,
      messageCtrl: _descCtrl,
      target: _target,
      onTargetChanged: (v) => setState(() => _target = v!),
      date: _date,
      time: _time,
      onPickDate: _pickDate,
      onPickTime: _pickTime,
      onSubmit: _submit,
      submitLabel: "Publish Now",
    );
  }
}

// ─── Edit dialog ─────────────────────────────────────────────────────────────

class _EditAnnouncementDialog extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final Function(Map<String, dynamic>) onSubmit;
  const _EditAnnouncementDialog(
      {required this.announcement, required this.onSubmit});

  @override
  State<_EditAnnouncementDialog> createState() =>
      _EditAnnouncementDialogState();
}

class _EditAnnouncementDialogState
    extends State<_EditAnnouncementDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _messageCtrl;
  late String _target;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
        text: widget.announcement['title'] ?? '');
    _messageCtrl = TextEditingController(
        text: widget.announcement['message'] ?? '');
    _target = widget.announcement['target'] ?? 'OVERALL';
  }

  void _submit() {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Title and message are required"),
            backgroundColor: Colors.red),
      );
      return;
    }
    widget.onSubmit({
      'title': _titleCtrl.text.trim(),
      'message': _messageCtrl.text.trim(),
      'target': _target,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _buildDialog(
      title: "Edit Announcement",
      titleCtrl: _titleCtrl,
      messageCtrl: _messageCtrl,
      target: _target,
      onTargetChanged: (v) => setState(() => _target = v!),
      onSubmit: _submit,
      submitLabel: "Save Changes",
    );
  }
}

// ─── Shared dialog builder ────────────────────────────────────────────────────

Widget _buildDialog({
  required String title,
  required TextEditingController titleCtrl,
  required TextEditingController messageCtrl,
  required String target,
  required ValueChanged<String?> onTargetChanged,
  required VoidCallback onSubmit,
  required String submitLabel,
  DateTime? date,
  TimeOfDay? time,
  VoidCallback? onPickDate,
  VoidCallback? onPickTime,
}) {
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: AppTheme.borderColor),
  );
  final focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppTheme.primaryColor),
  );

  return Dialog(
    backgroundColor: AppTheme.backgroundColor,
    shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 400),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.speaker_2_fill,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor)),
            ]),
            const SizedBox(height: 24),
            Text("TITLE",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtleText)),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                hintText: "Enter title…",
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: focusedBorder,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Text("TARGET AUDIENCE",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtleText)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: target,
                  isExpanded: true,
                  icon: const Icon(CupertinoIcons.chevron_down,
                      size: 16),
                  items: ['OVERALL', 'STUDENT ONLY', 'TEACHER ONLY']
                      .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(v,
                              style: GoogleFonts.inter(fontSize: 14))))
                      .toList(),
                  onChanged: onTargetChanged,
                ),
              ),
            ),
            if (onPickDate != null && onPickTime != null) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DATE",
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.subtleText)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onPickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.borderColor),
                          ),
                          child: Row(children: [
                            Icon(CupertinoIcons.calendar,
                                size: 16, color: AppTheme.subtleText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                date == null
                                    ? "Select Date"
                                    : "${date.month}/${date.day}/${date.year}",
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: date == null
                                        ? AppTheme.subtleText
                                        : AppTheme.textColor),
                              ),
                            ),
                          ]),
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
                      Text("TIME",
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.subtleText)),
                      const SizedBox(height: 8),
                      Builder(builder: (ctx) {
                        return InkWell(
                          onTap: onPickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.borderColor),
                            ),
                            child: Row(children: [
                              Icon(CupertinoIcons.clock,
                                  size: 16,
                                  color: AppTheme.subtleText),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  time == null
                                      ? "Select Time"
                                      : time.format(ctx),
                                  style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: time == null
                                          ? AppTheme.subtleText
                                          : AppTheme.textColor),
                                ),
                              ),
                            ]),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            Text("MESSAGE",
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.subtleText)),
            const SizedBox(height: 8),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Enter message…",
                border: inputBorder,
                enabledBorder: inputBorder,
                focusedBorder: focusedBorder,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 28),
            Builder(builder: (ctx) {
              return Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text("Cancel",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.subtleText)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(submitLabel,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
              ]);
            }),
          ],
        ),
      ),
    ),
  );
}
