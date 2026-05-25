import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';

class AdminSectionDetailsScreen extends ConsumerStatefulWidget {
  final String levelName;
  final String sectionName;
  final String sectionId;

  const AdminSectionDetailsScreen({
    super.key,
    required this.levelName,
    required this.sectionName,
    required this.sectionId,
  });

  @override
  ConsumerState<AdminSectionDetailsScreen> createState() => _AdminSectionDetailsScreenState();
}

class _AdminSectionDetailsScreenState extends ConsumerState<AdminSectionDetailsScreen> {
  List<dynamic> _students = [];
  Map<String, dynamic>? _teacher;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      // We can use getSectionStudents but let's fetch full details
      final response = await apiService.getSectionStudents(widget.sectionId);
      // Wait, getSectionStudents returns a list of students in my ApiService implementation
      
      // Let's re-fetch the section to get teacher too if needed, 
      // or just trust the student list for now.
      
      if (mounted) {
        setState(() {
          _students = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fetch Section Details Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.sectionName,
              style: GoogleFonts.inter(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              widget.levelName,
              style: GoogleFonts.inter(
                color: AppTheme.subtleText,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.person_add, color: AppTheme.primaryColor),
            onPressed: () => _showAddStudentDialog(),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildSectionHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchDetails,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      return _buildStudentCard(_students[index], index);
                    },
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Enrolled Students",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          Text(
            "${_students.length} Total",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student, int index) {
    return FadeInUp(
      delay: Duration(milliseconds: index * 100),
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
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                (student['name'] ?? "S")[0],
                style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] ?? "Unknown",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor),
                  ),
                  Text(
                    student['email'] ?? "",
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.minus_circle, color: Colors.redAccent, size: 18),
              onPressed: () => _confirmRemoveStudent(index),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog() async {
    setState(() => _isLoading = true);
    final apiService = ref.read(apiServiceProvider);
    final allStudents = await apiService.getStudents();
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Filter to only unassigned students
    final unassignedStudents = allStudents.where((s) => s['section'] == null).toList();

    String searchQuery = '';
    Set<String> selectedIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredStudents = unassignedStudents.where((s) {
            final name = (s['name'] ?? '').toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Enroll Students",
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.clear_circled, color: AppTheme.subtleText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  "Select students to add to this section. Students already in a section are not shown.",
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.subtleText),
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                CupertinoSearchTextField(
                  placeholder: "Search unassigned students...",
                  onChanged: (val) {
                    setModalState(() => searchQuery = val);
                  },
                  style: GoogleFonts.inter(color: AppTheme.textColor, fontSize: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 16),

                // Student List
                Expanded(
                  child: filteredStudents.isEmpty
                      ? Center(
                          child: Text("No students found.", style: GoogleFonts.inter(color: AppTheme.subtleText)),
                        )
                      : ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            final isSelected = selectedIds.contains(student['_id']);
                            
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedIds.remove(student['_id']);
                                  } else {
                                    selectedIds.add(student['_id']);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
                                      color: isSelected ? AppTheme.primaryColor : AppTheme.subtleText,
                                    ),
                                    const SizedBox(width: 12),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                      child: Text(
                                        (student['name'] ?? "S")[0],
                                        style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name'] ?? "Unknown",
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textColor),
                                          ),
                                          Text(
                                            student['email'] ?? "",
                                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedIds.isEmpty ? null : () async {
                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      final success = await apiService.enrollStudents(selectedIds.toList(), widget.sectionId);
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Students enrolled successfully")));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to enroll students")));
                      }
                      _fetchDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "Enroll Selected (${selectedIds.length})", 
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmRemoveStudent(int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Remove Student"),
        content: Text("Are you sure you want to remove ${_students[index]['name']} from this section?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final apiService = ref.read(apiServiceProvider);
              final success = await apiService.removeStudentFromSection(_students[index]['_id'], widget.sectionId);
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Student removed from section")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to remove student")));
                }
                _fetchDetails();
              }
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
  }
}
