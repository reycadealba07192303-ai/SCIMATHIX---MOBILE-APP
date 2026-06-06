import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/presentation/screens/admin/academic/admin_teacher_edit_profile_screen.dart';
import 'package:scimathix/data/services/socket_service.dart';
class AdminTeacherManagementScreen extends ConsumerStatefulWidget {
  const AdminTeacherManagementScreen({super.key});

  @override
  ConsumerState<AdminTeacherManagementScreen> createState() => _AdminTeacherManagementScreenState();
}

class _AdminTeacherManagementScreenState extends ConsumerState<AdminTeacherManagementScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _teachers = [];
  List<dynamic> _filteredTeachers = [];
  bool _isLoading = true;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _currentTab = "All"; // All, Science, Math
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) _currentTab = "All";
        if (_tabController.index == 1) _currentTab = "Science";
        if (_tabController.index == 2) _currentTab = "Math";
        _applyFilters();
      }
    });
    _searchController.addListener(_applyFilters);
    _setupSocket();
    _fetchTeachers();
  }

  void _setupSocket() {
    _socketService = ref.read(socketServiceProvider);
    _socketService.initSocket();
    _socketService.on('academic_updated', (_) => _fetchTeachers());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _socketService.off('academic_updated');
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoading = true);
    final apiService = ref.read(apiServiceProvider);
    final teachers = await apiService.getTeachers();
    if (mounted) {
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeachers = _teachers.where((teacher) {
        bool matchesSearch = (teacher['name'] ?? "").toLowerCase().contains(query);
        bool matchesTab = true;
        
        if (_currentTab != "All") {
          final role = teacher['subjectRole'];
          if (_currentTab == "Science" && role != "Science") {
            matchesTab = false;
          } else if (_currentTab == "Math" && role != "Mathematics") {
            matchesTab = false;
          }
        }
        
        return matchesSearch && matchesTab;
      }).toList();
    });
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
        title: Text(
          "Teacher Management",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.subtleText,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: "All Teachers"),
            Tab(text: "Science"),
            Tab(text: "Math"),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchTeachers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: _filteredTeachers.length,
                    itemBuilder: (context, index) {
                      return _buildTeacherCard(_filteredTeachers[index], index);
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: "Search teachers by name...",
        style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        itemColor: AppTheme.subtleText,
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher, int index) {
    final List<String> handles = (teacher['handles'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return FadeInUp(
      delay: Duration(milliseconds: index * 100),
      child: InkWell(
        onTap: () => _showTeacherActions(teacher),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      (teacher['name'] ?? "T")[0],
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                teacher['name'] ?? "Unknown",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.blue, size: 14),
                            ),
                          ],
                        ),
                        Text(
                          teacher['email'] ?? "",
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(true),
                ],
              ),
              if (handles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: AppTheme.borderColor),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "HANDLING LOADS",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.subtleText,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (teacher['totalStudents'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${teacher['totalStudents']} Students",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: handles.map((handle) => _buildHandleChip(handle)).toList(),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        verified ? "ACTIVE" : "PENDING",
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: verified ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildHandleChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textColor),
      ),
    );
  }

  void _showTeacherActions(Map<String, dynamic> teacher) {
    final List<String> handles = (teacher['handles'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final String? subjectRole = teacher['subjectRole'];
    final String roleText = subjectRole != null ? "Role: $subjectRole Teacher" : "No subject role assigned";
    final String sectionText = handles.isNotEmpty ? "\nSections: ${handles.join(', ')}" : "";
    final String designation = "$roleText$sectionText";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                teacher['name'] ?? "Unknown Teacher",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
              ),
              const SizedBox(height: 8),
              Text(
                designation,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildActionSheetButton(
                "Assign Subject Role",
                CupertinoIcons.briefcase,
                AppTheme.primaryColor,
                () {
                  Navigator.pop(context);
                  _showAssignRoleProcess(teacher);
                }
              ),
              _buildActionSheetButton(
                "Assign Section",
                CupertinoIcons.plus_rectangle,
                AppTheme.primaryColor,
                () {
                  Navigator.pop(context);
                  _showAssignProcess(teacher);
                }
              ),
              _buildActionSheetButton(
                "Handled Sections",
                CupertinoIcons.collections,
                const Color(0xFF6C63FF),
                () {
                  Navigator.pop(context);
                  _showHandledSections(teacher);
                }
              ),
              _buildActionSheetButton(
                "Edit Profile Details",
                CupertinoIcons.person,
                AppTheme.secondaryColor,
                () {
                  Navigator.pop(context);
                  _showEditProfileDialog(teacher);
                }
              ),
              _buildActionSheetButton(
                teacher['isActive'] == false ? "Unsuspend Account" : "Suspend Account",
                CupertinoIcons.nosign,
                Colors.orange,
                () {
                  Navigator.pop(context);
                  _toggleSuspendStatus(teacher);
                }
              ),
              _buildActionSheetButton(
                "Delete Account",
                CupertinoIcons.delete,
                Colors.red,
                () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(teacher);
                }
              ),
              const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }

  void _showHandledSections(Map<String, dynamic> teacher) {
    final List handledClasses = teacher['handledClassesPopulated'] ?? [];

    if (handledClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No handled sections found for this teacher.")),
      );
      return;
    }

    // Group by subject
    final Map<String, Map<String, dynamic>> subjectMap = {};
    for (var hc in handledClasses) {
      final subject = hc['subject'];
      final section = hc['section'];
      if (subject == null || section == null) continue;
      final subjectId = subject['_id'];
      if (!subjectMap.containsKey(subjectId)) {
        subjectMap[subjectId] = {
          'subject': subject,
          'sections': <Map<String, dynamic>>[],
        };
      }
      (subjectMap[subjectId]!['sections'] as List).add({
        ...Map<String, dynamic>.from(section),
        '_hcId': hc['_id'],
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.collections, color: Color(0xFF6C63FF), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Handled Sections",
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                      ),
                      Text(
                        teacher['name'] ?? '',
                        style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: subjectMap.length,
                itemBuilder: (context, index) {
                  final entry = subjectMap.values.elementAt(index);
                  final subject = entry['subject'] as Map<String, dynamic>;
                  final sections = entry['sections'] as List;
                  final isScience = subject['category'] == 'Science';
                  final color = isScience ? Colors.green : Colors.blue;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isScience ? CupertinoIcons.lab_flask : CupertinoIcons.function,
                            color: color, size: 20,
                          ),
                        ),
                        title: Text(
                          subject['name'] ?? 'Unknown Subject',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                        ),
                        subtitle: Text(
                          "${subject['code'] ?? ''} • ${sections.length} section${sections.length != 1 ? 's' : ''}",
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                        ),
                        children: sections.map<Widget>((sec) {
                          final levelName = sec['level'] != null ? sec['level']['name'] ?? '' : '';
                          final sectionName = sec['name'] ?? 'Unknown';
                          final studentCount = sec['studentCount'] ?? 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showSectionStudents(
                                teacher,
                                subject,
                                sec,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(CupertinoIcons.person_2, color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$levelName - $sectionName",
                                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor),
                                        ),
                                        Text(
                                          "$studentCount student${studentCount != 1 ? 's' : ''}",
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(CupertinoIcons.chevron_right, color: AppTheme.subtleText, size: 16),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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

  void _showSectionStudents(
    Map<String, dynamic> teacher,
    Map<String, dynamic> subject,
    Map<String, dynamic> section,
  ) async {
    final sectionId = section['_id'];
    if (sectionId == null) return;

    // Show loading
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SectionStudentsSheet(
        sectionId: sectionId,
        teacherName: teacher['name'] ?? '',
        subjectName: subject['name'] ?? '',
        sectionName: "${section['level'] != null ? section['level']['name'] ?? '' : ''} - ${section['name'] ?? ''}",
        subjectCategory: subject['category'] ?? '',
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> teacher) {
    String confirmationText = '';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) {
          final canDelete = confirmationText == 'DELETE';
          return AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              "Delete Account",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Are you sure you want to delete ${teacher['name']}'s account? This action cannot be undone.",
                  style: GoogleFonts.inter(color: AppTheme.subtleText, height: 1.4),
                ),
                const SizedBox(height: 16),
                Text("Type 'DELETE' to confirm:",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textColor, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) => setDialogState(() => confirmationText = value),
                  decoration: InputDecoration(
                    hintText: "DELETE",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text("Cancel",
                          style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canDelete ? Colors.redAccent : Colors.redAccent.withValues(alpha: 0.4),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: canDelete
                          ? () async {
                              Navigator.pop(dialogContext);
                              setState(() => _isLoading = true);
                              final errorMsg = await ref.read(apiServiceProvider).deleteUser(teacher['_id']);
                              if (!mounted) return;
                              if (errorMsg == null) {
                                _fetchTeachers();
                                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text("Teacher deleted.")));
                              } else {
                                setState(() => _isLoading = false);
                                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(errorMsg)));
                              }
                            }
                          : null,
                      child: Text("Delete",
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSuspendStatus(Map<String, dynamic> teacher) async {
    setState(() => _isLoading = true);
    final success = await ref.read(apiServiceProvider).suspendUser(teacher['_id']);
    if (success) {
      _fetchTeachers();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(teacher['isActive'] == false ? "Account unsuspended." : "Account suspended.")
      ));
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update suspend status.")));
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTeacherEditProfileScreen(
          teacher: teacher,
          onUpdated: () => _fetchTeachers(),
        ),
      ),
    );
  }

  Widget _buildActionSheetButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const Spacer(),
            Icon(CupertinoIcons.chevron_right, color: AppTheme.subtleText, size: 16),
          ],
        ),
      ),
    );
  }

  void _showAssignProcess(Map<String, dynamic> teacher) {
    if (teacher['subjectRole'] == null || teacher['subjectRole'].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please assign a subject role to the teacher first."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => _AssignProcessDialog(
        teacher: teacher,
        onAssigned: () => _fetchTeachers(),
      ),
    );
  }

  void _showAssignRoleProcess(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => _AssignRoleDialog(
        teacher: teacher,
        onAssigned: () => _fetchTeachers(),
      ),
    );
  }
}

class _AssignRoleDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onAssigned;
  const _AssignRoleDialog({required this.teacher, required this.onAssigned});

  @override
  ConsumerState<_AssignRoleDialog> createState() => _AssignRoleDialogState();
}

class _AssignRoleDialogState extends ConsumerState<_AssignRoleDialog> {
  bool _isLoading = false;

  Future<void> _assignRole(String specialty) async {
    setState(() => _isLoading = true);
    
    final success = await ref.read(apiServiceProvider).updateUserRoleSubject(
      widget.teacher['_id'], 
      specialty
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully assigned subject role!")));
        widget.onAssigned();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to assign role.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assign Subject Role",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
            ),
            const SizedBox(height: 8),
            Text(
              "What subject will ${widget.teacher['name']} specialize in?",
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildOptionTile("Mathematics", () {
                        _assignRole("Mathematics");
                      }),
                      _buildOptionTile("Science", () {
                        _assignRole("Science");
                      }),
                    ]
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}

class _AssignProcessDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> teacher;
  final VoidCallback onAssigned;
  const _AssignProcessDialog({required this.teacher, required this.onAssigned});

  @override
  ConsumerState<_AssignProcessDialog> createState() => _AssignProcessDialogState();
}

class _AssignProcessDialogState extends ConsumerState<_AssignProcessDialog> {
  int _step = 1;
  List<dynamic> _levels = [];
  List<dynamic> _sections = [];

  // Store full objects so we can auto-generate subject name/code
  Map<String, dynamic>? _selectedLevel;
  Map<String, dynamic>? _selectedSection;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final api = ref.read(apiServiceProvider);
    final levels = await api.getLevels();
    if (mounted) {
      setState(() {
        _levels = levels;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSectionsForLevel(String levelId) async {
    setState(() => _isLoading = true);
    final sections = await ref.read(apiServiceProvider).getSections(levelId);
    if (mounted) {
      setState(() {
        _sections = sections;
        _isLoading = false;
      });
    }
  }

  /// Auto-generates Subject Name and Code, then assigns teacher
  Future<void> _submitAssignmentWithRole(String role) async {
    if (_selectedLevel == null || _selectedSection == null) return;

    setState(() => _isSubmitting = true);

    try {
      // Auto-generate subject name & code
      final levelName = _selectedLevel!['name'] as String; // e.g. "Grade 7"
      final sectionName = _selectedSection!['name'] as String; // e.g. "Section A"

      final gradeNumber = levelName.replaceAll(RegExp(r'[^0-9]'), '');
      final sectionLetter = sectionName.replaceAll(RegExp(r'(Section|Grade|\s)'), '');
      final prefix = role == 'Mathematics' ? 'MATH' : 'SCI';

      final generatedName = '$role ${gradeNumber.isNotEmpty ? gradeNumber : '1'}';
      final generatedCode = '$prefix${gradeNumber.isNotEmpty ? gradeNumber : '1'}-${sectionLetter.isNotEmpty ? sectionLetter : 'A'}';

      // 1. Create subject (auto-linked to section)
      final subject = await ref.read(apiServiceProvider).createSubject(
        generatedName,
        generatedCode,
        role,
        sectionId: _selectedSection!['_id'],
      );

      if (subject != null) {
        // 2. Assign teacher to section with this subject
        final success = await ref.read(apiServiceProvider).assignTeacherToSection(
          widget.teacher['_id'],
          _selectedSection!['_id'],
          subject['_id'],
        );

        if (mounted) {
          if (success) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("✅ $generatedName ($generatedCode) created & assigned!"),
              backgroundColor: Colors.green,
            ));
            widget.onAssigned();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to assign class. Please try again.")),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subject code already exists for this section.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (errMsg.startsWith("Exception: ")) {
          errMsg = errMsg.replaceFirst("Exception: ", "");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step indicator
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: _step > i ? AppTheme.primaryColor : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 20),
            Text(
              _getStepTitle(),
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor),
            ),
            const SizedBox(height: 6),
            Text(
              _getStepSubtitle(),
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: (_isLoading || _isSubmitting)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        if (_isSubmitting) ...
                          [const SizedBox(height: 12), Text("Creating & Assigning...", style: GoogleFonts.inter(color: AppTheme.subtleText))]
                      ],
                    ),
                  )
                : _buildStepContent(),
            ),
            if (_step > 1) ...
              [
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(() => _step--),
                  icon: const Icon(CupertinoIcons.back, size: 16),
                  label: Text("Back", style: GoogleFonts.inter(fontSize: 13)),
                )
              ]
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    if (_step == 1) return "Step 1: Select Level";
    if (_step == 2) return "Step 2: Select Section";
    return "Step 3: Select Role & Subject";
  }

  String _getStepSubtitle() {
    if (_step == 1) return "What year level will ${widget.teacher['name']} handle?";
    if (_step == 2) return "Which section under ${_selectedLevel?['name'] ?? ''}?";
    return "Choose Math or Science — the subject will be auto-created for ${_selectedSection?['name'] ?? 'this section'}.";
  }

  Widget _buildStepContent() {
    if (_step == 1) {
      if (_levels.isEmpty) {
        return const Center(child: Text("No levels found. Create one first."));
      }
      return ListView.builder(
        itemCount: _levels.length,
        itemBuilder: (context, index) {
          final lvl = _levels[index];
          return _buildOptionTile(lvl['name'], () {
            setState(() {
              _selectedLevel = Map<String, dynamic>.from(lvl);
              _step = 2;
            });
            _loadSectionsForLevel(lvl['_id']);
          });
        },
      );
    }

    if (_step == 2) {
      if (_sections.isEmpty) {
        return const Center(child: Text("No sections for this level. Create one first."));
      }
      return ListView.builder(
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final sec = _sections[index];
          return _buildOptionTile(sec['name'], () {
            setState(() {
              _selectedSection = Map<String, dynamic>.from(sec);
              _step = 3;
            });
          });
        },
      );
    }

    // Step 3: Select Role + auto-create subject
    if (_step == 3) {
      final levelName = _selectedLevel?['name'] ?? '';
      final sectionName = _selectedSection?['name'] ?? '';
      final gradeNum = levelName.replaceAll(RegExp(r'[^0-9]'), '');
      final sectionLetter = sectionName.replaceAll(RegExp(r'(Section|Grade|\s)'), '');

      // If teacher already has an assigned role, only show that role
      final existingRole = widget.teacher['subjectRole'] as String?;
      final showMath = existingRole == null || existingRole == 'Mathematics';
      final showScience = existingRole == null || existingRole == 'Science';

      return ListView(
        children: [
          if (existingRole != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.info_circle, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This teacher is assigned as a $existingRole teacher.",
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showMath) ...[
            _buildRoleTile(
              role: 'Mathematics',
              icon: CupertinoIcons.function,
              previewName: 'Mathematics ${gradeNum.isNotEmpty ? gradeNum : "1"}',
              previewCode: 'MATH${gradeNum.isNotEmpty ? gradeNum : "1"}-${sectionLetter.isNotEmpty ? sectionLetter : "A"}',
            ),
          ],
          if (showMath && showScience) const SizedBox(height: 12),
          if (showScience) ...[
            _buildRoleTile(
              role: 'Science',
              icon: CupertinoIcons.lab_flask,
              previewName: 'Science ${gradeNum.isNotEmpty ? gradeNum : "1"}',
              previewCode: 'SCI${gradeNum.isNotEmpty ? gradeNum : "1"}-${sectionLetter.isNotEmpty ? sectionLetter : "A"}',
            ),
          ],
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildOptionTile(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
            const Icon(CupertinoIcons.chevron_right, size: 16, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTile({
    required String role,
    required IconData icon,
    required String previewName,
    required String previewCode,
  }) {
    final color = role == 'Mathematics' ? Colors.blue : Colors.green;
    return GestureDetector(
      onTap: () => _submitAssignmentWithRole(role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
                  const SizedBox(height: 4),
                  Text(
                    "Will create: $previewName",
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                  ),
                  Text(
                    "Code: $previewCode",
                    style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(CupertinoIcons.arrow_right_circle_fill, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SectionStudentsSheet extends ConsumerStatefulWidget {
  final String sectionId;
  final String teacherName;
  final String subjectName;
  final String sectionName;
  final String subjectCategory;

  const _SectionStudentsSheet({
    required this.sectionId,
    required this.teacherName,
    required this.subjectName,
    required this.sectionName,
    required this.subjectCategory,
  });

  @override
  ConsumerState<_SectionStudentsSheet> createState() => _SectionStudentsSheetState();
}

class _SectionStudentsSheetState extends ConsumerState<_SectionStudentsSheet> {
  bool _isLoading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final details = await ref.read(apiServiceProvider).getSectionDetails(widget.sectionId);
    if (mounted) {
      setState(() {
        _students = details?['students'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScience = widget.subjectCategory == 'Science';
    final color = isScience ? Colors.green : Colors.blue;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(CupertinoIcons.person_2_fill, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sectionName,
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                    ),
                    Text(
                      "${widget.subjectName} • ${widget.teacherName}",
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                    ),
                  ],
                ),
              ),
              if (!_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${_students.length}",
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Student list
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.person_2, size: 48, color: AppTheme.subtleText.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          "No students enrolled",
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.subtleText),
                        ),
                        Text(
                          "Students will appear here once enrolled",
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: color.withOpacity(0.1),
                              child: Text(
                                (student['name'] ?? 'S')[0].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'] ?? 'Unknown',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor),
                                  ),
                                  Text(
                                    student['email'] ?? '',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "#${index + 1}",
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
