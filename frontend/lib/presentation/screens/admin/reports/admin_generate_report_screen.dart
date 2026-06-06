import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:scimathix/core/utils/app_logger.dart';

class AdminGenerateReportScreen extends ConsumerStatefulWidget {
  final List<dynamic> logs;

  const AdminGenerateReportScreen({super.key, required this.logs});

  @override
  ConsumerState<AdminGenerateReportScreen> createState() => _AdminGenerateReportScreenState();
}

class _AdminGenerateReportScreenState extends ConsumerState<AdminGenerateReportScreen> {
  String? _selectedAcademicYear;
  List<dynamic> _academicYears = [];
  List<dynamic> _levels = [];
  Map<String, bool> _selectedLevels = {};
  List<dynamic> _sections = [];
  Map<String, bool> _selectedSections = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchoolYears();
  }

  Future<void> _fetchSchoolYears() async {
    final api = ref.read(apiServiceProvider);
    try {
      final years = await api.getSchoolYears();
      if (!mounted) return;
      setState(() {
        _academicYears = years;
        if (_academicYears.isNotEmpty) {
          _selectedAcademicYear = _academicYears.first['year'];
          _fetchLevelsForYear(_selectedAcademicYear!);
        }
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Fetch school years', e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLevelsForYear(String year) async {
    final api = ref.read(apiServiceProvider);
    try {
      final levels = await api.getLevels(year);
      if (mounted) {
        setState(() {
          _levels = levels;
          _selectedLevels = {
            for (var level in levels) level['_id'].toString(): false
          };
          _sections = [];
          _selectedSections = {};
        });
      }
    } catch (e) {
      AppLogger.error('Fetch levels', e);
    }
  }

  Future<void> _fetchSectionsForSelectedLevels() async {
    final api = ref.read(apiServiceProvider);
    List<dynamic> allSections = [];
    for (var level in _levels) {
      final id = level['_id'].toString();
      if (_selectedLevels[id] == true) {
        try {
          final secs = await api.getSections(id);
          for (var s in secs) {
            s['levelName'] = level['name'];
          }
          allSections.addAll(secs);
        } catch (e) {
          AppLogger.error('Fetch sections', e);
        }
      }
    }
    if (mounted) {
      setState(() {
        _sections = allSections;
        _selectedSections = {
          for (var s in allSections) s['_id'].toString(): true
        };
      });
    }
  }

  Future<void> _exportPdf() async {
    final logs = widget.logs;
    
    final selectedLevelNames = _levels
        .where((l) => _selectedLevels[l['_id'].toString()] == true)
        .map((l) => l['name'].toString())
        .toList();

    final selectedSectionNames = _sections
        .where((s) => _selectedSections[s['_id'].toString()] == true)
        .map((s) => s['name'].toString())
        .toList();

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('SCIMATHIX', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.Text('SYSTEM ACTIVITY REPORT', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ]
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Academic Year: $_selectedAcademicYear', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Grade Levels: ${selectedLevelNames.join(", ")}', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text('Sections: ${selectedSectionNames.join(", ")}', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text('Generated on: ${DateTime.now().toString().split(' ').first}', style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text('User Activity Logs', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 12),
          
          if (logs.isEmpty)
             pw.Text('No activity logs found for this period.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600))
          else
            pw.Table.fromTextArray(
              headers: ['Timestamp', 'User', 'Role', 'Action'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              data: logs.map((raw) {
                final log = raw as Map<String, dynamic>;
                final date = log['timestamp'] != null 
                    ? DateTime.parse(log['timestamp'].toString()).toLocal().toString().substring(0, 16) 
                    : 'N/A';
                return [
                  date,
                  log['user']?.toString() ?? 'Unknown',
                  log['role']?.toString().toUpperCase() ?? 'N/A',
                  log['action']?.toString() ?? 'Unknown Action',
                ];
              }).toList(),
            ),
        ],
      ),
    );

    final name = 'SCIMATHIX_Logs_$_selectedAcademicYear.pdf';
    await Printing.layoutPdf(onLayout: (_) => pdf.save(), name: name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Generate Report",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Icon(CupertinoIcons.back, color: AppTheme.textColor, size: 18),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildFormCard(),
            ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
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
                child: const Icon(CupertinoIcons.doc_text, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Generate Activity Report',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textColor),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('1. Select Academic Year', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
          const SizedBox(height: 8),
          if (_academicYears.isEmpty)
             Text("No academic years available.", style: GoogleFonts.inter(color: AppTheme.subtleText))
          else
            DropdownButtonFormField<String>(
              value: _selectedAcademicYear,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: AppTheme.backgroundColor,
              ),
              items: _academicYears
                  .map((y) => DropdownMenuItem<String>(
                        value: y['year']?.toString() ?? '',
                        child: Text(y['year']?.toString() ?? 'Unknown'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedAcademicYear = v);
                  _fetchLevelsForYear(v);
                }
              },
            ),
          
          const SizedBox(height: 20),
          Text('2. Select Grade Levels', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
          const SizedBox(height: 8),
          if (_levels.isEmpty)
             Text("No grade levels found for this year.", style: GoogleFonts.inter(color: AppTheme.subtleText))
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: _levels.map((level) {
                  final id = level['_id'].toString();
                  final name = level['name'].toString();
                  final isSelected = _selectedLevels[id] ?? false;
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        _selectedLevels[id] = val ?? false;
                      });
                      _fetchSectionsForSelectedLevels();
                    },
                    title: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textColor)),
                    activeColor: AppTheme.primaryColor,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 20),
          Text('3. Select Sections', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.subtleText)),
          const SizedBox(height: 8),
          if (!_selectedLevels.values.any((v) => v))
            Text("Select a grade level first.", style: GoogleFonts.inter(color: AppTheme.subtleText))
          else if (_sections.isEmpty)
            Text("No sections found for selected levels.", style: GoogleFonts.inter(color: AppTheme.subtleText))
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: _sections.map((section) {
                  final id = section['_id'].toString();
                  final name = section['name'].toString();
                  final levelName = section['levelName']?.toString() ?? '';
                  final isSelected = _selectedSections[id] ?? false;
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        _selectedSections[id] = val ?? false;
                      });
                    },
                    title: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textColor)),
                    subtitle: Text(levelName, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText)),
                    activeColor: AppTheme.primaryColor,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: widget.logs.isEmpty || _selectedLevels.values.every((v) => !v) ? null : _exportPdf,
              icon: const Icon(CupertinoIcons.arrow_down_doc, size: 20),
              label: Text('Download PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
