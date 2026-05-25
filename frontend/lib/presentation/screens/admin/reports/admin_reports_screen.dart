import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scimathix/core/theme/app_theme.dart';
import 'package:scimathix/logic/auth_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  String _selectedAcademicYear = '2025-2026';
  final List<String> _academicYears = ['2025-2026', '2024-2025', '2023-2024'];
  final List<Map<String, dynamic>> _recentDownloads = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    final apiService = ref.read(apiServiceProvider);
    final data = await apiService.getAdminReports();
    if (mounted) {
      setState(() {
        _reportData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Reports & Analytics",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, color: AppTheme.textColor),
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _fetchReports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Academic Year Selector + Download PDF
                    _buildAcademicYearSelector(),
                    const SizedBox(height: 24),

                    // Academic Performance Section
                    _buildSectionLabel("Academic Performance"),
                    const SizedBox(height: 12),
                    _buildAcademicPerformanceCards(),
                    const SizedBox(height: 24),

                    // User Activity Section (Chart)
                    _buildSectionLabel("User Activity (Last 7 Days)"),
                    const SizedBox(height: 12),
                    _buildUserActivityChart(),
                    const SizedBox(height: 24),

                    // Quiz & Assessment Section
                    _buildSectionLabel("Quiz & Assessment — Top Sections"),
                    const SizedBox(height: 12),
                    _buildTopSections(),
                    const SizedBox(height: 24),

                    // Recent Downloads Section
                    _buildSectionLabel("Recent Downloads"),
                    const SizedBox(height: 12),
                    _buildRecentDownloads(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Academic Year Selector ────────────────────────────────────────
  Widget _buildAcademicYearSelector() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Academic Year",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.subtleText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAcademicYear,
                        isExpanded: true,
                        icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                        dropdownColor: AppTheme.surfaceColor,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                        items: _academicYears.map((year) {
                          return DropdownMenuItem(value: year, child: Text(year));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedAcademicYear = val!);
                          _fetchReports();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _generateAndDownloadPDF,
                  icon: const Icon(CupertinoIcons.arrow_down_doc_fill, size: 18),
                  label: Text("Download PDF", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Academic Performance Cards ────────────────────────────────────
  Widget _buildAcademicPerformanceCards() {
    final perf = _reportData?['academicPerformance'];
    final avgScore = perf?['averageScore'] ?? 0;
    final passingRate = perf?['passingRate'] ?? 0;
    final totalAttempts = perf?['totalAttempts'] ?? 0;

    return FadeInUp(
      child: Row(
        children: [
          Expanded(child: _buildStatCard("Avg Score", "$avgScore%", CupertinoIcons.chart_bar_alt_fill, const Color(0xFF6C63FF))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard("Pass Rate", "$passingRate%", CupertinoIcons.checkmark_seal_fill, const Color(0xFF00C896))),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard("Attempts", "$totalAttempts", CupertinoIcons.pencil_outline, const Color(0xFFFF6B6B))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── User Activity Chart ──────────────────────────────────────────
  Widget _buildUserActivityChart() {
    final activity = _reportData?['userActivity'];
    final labels = (activity?['labels'] as List?)?.cast<String>() ?? [];
    final data = (activity?['data'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
    final totalActions = activity?['totalActions'] ?? 0;
    final maxVal = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 1.0;

    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Activity Trend",
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$totalActions actions",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 140,
              child: labels.isEmpty
                  ? Center(
                      child: Text("No activity data yet",
                          style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13)),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(labels.length, (i) {
                        final barHeight = maxVal > 0 ? (data[i] / maxVal) * 110 : 0.0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "${data[i].toInt()}",
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textColor),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 600 + i * 100),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: barHeight < 4 && data[i] > 0 ? 4 : barHeight,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        AppTheme.primaryColor,
                                        AppTheme.primaryColor.withOpacity(0.5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  labels[i],
                                  style: GoogleFonts.inter(fontSize: 10, color: AppTheme.subtleText, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Sections (Quiz & Assessment) ─────────────────────────────
  Widget _buildTopSections() {
    final topSections = (_reportData?['topSections'] as List?) ?? [];

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: topSections.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    "No quiz data available yet.\nQuiz & Assessment results will appear here once students take quizzes.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13),
                  ),
                ),
              )
            : Column(
                children: List.generate(topSections.length, (i) {
                  final section = topSections[i];
                  final avg = section['average'] ?? 0;
                  final colors = [
                    const Color(0xFFFFD700),
                    const Color(0xFFC0C0C0),
                    const Color(0xFFCD7F32),
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                  ];
                  final color = colors[i % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "#${i + 1}",
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section['name'] ?? 'Unknown Section',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: avg / 100,
                                  minHeight: 6,
                                  backgroundColor: AppTheme.borderColor,
                                  valueColor: AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "$avg%",
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: color),
                        ),
                      ],
                    ),
                  );
                }),
              ),
      ),
    );
  }

  // ─── Recent Downloads ─────────────────────────────────────────────
  Widget _buildRecentDownloads() {
    if (_recentDownloads.isEmpty) {
      return FadeInUp(
        delay: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(CupertinoIcons.tray, color: AppTheme.subtleText.withOpacity(0.4), size: 40),
                const SizedBox(height: 12),
                Text(
                  "No downloads yet",
                  style: GoogleFonts.inter(color: AppTheme.subtleText, fontSize: 13),
                ),
                Text(
                  "Downloaded reports will appear here",
                  style: GoogleFonts.inter(color: AppTheme.subtleText.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _recentDownloads.map((dl) {
        return FadeInUp(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(CupertinoIcons.doc_fill, color: Colors.red, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dl['name'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                      Text(dl['date'], style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText)),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green.withOpacity(0.7), size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Section Label ────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return FadeInUp(
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textColor,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  // ─── PDF Generation ───────────────────────────────────────────────
  Future<void> _generateAndDownloadPDF() async {
    final perf = _reportData?['academicPerformance'];
    final activity = _reportData?['userActivity'];
    final topSections = (_reportData?['topSections'] as List?) ?? [];

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#6C63FF'),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SCIMATHIX', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Reports & Analytics', style: pw.TextStyle(color: PdfColors.white, fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Academic Year', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                    pw.Text(_selectedAcademicYear, style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Academic Performance
          pw.Text('Academic Performance', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _pdfStatBox('Average Score', '${perf?['averageScore'] ?? 0}%'),
              _pdfStatBox('Passing Rate', '${perf?['passingRate'] ?? 0}%'),
              _pdfStatBox('Total Attempts', '${perf?['totalAttempts'] ?? 0}'),
            ],
          ),
          pw.SizedBox(height: 24),

          // User Activity
          pw.Text('User Activity (Last 7 Days)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Total Actions: ${activity?['totalActions'] ?? 0}', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 8),
          _pdfActivityTable(activity),
          pw.SizedBox(height: 24),

          // Top Sections
          pw.Text('Quiz & Assessment — Top Sections', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          if (topSections.isEmpty)
            pw.Text('No quiz data available yet.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey))
          else
            _pdfSectionsTable(topSections),

          pw.SizedBox(height: 30),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated on ${DateTime.now().toLocal().toString().split('.')[0]}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );

    final fileName = 'SCIMATHIX_Report_$_selectedAcademicYear.pdf';

    // Show the PDF preview / share dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: fileName,
    );

    // Track in Recent Downloads
    if (mounted) {
      setState(() {
        _recentDownloads.insert(0, {
          'name': fileName,
          'date': '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        });
      });
    }
  }

  pw.Widget _pdfStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  pw.Widget _pdfActivityTable(Map<String, dynamic>? activity) {
    final labels = (activity?['labels'] as List?)?.cast<String>() ?? [];
    final data = (activity?['data'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [];

    if (labels.isEmpty) {
      return pw.Text('No activity data', style: const pw.TextStyle(color: PdfColors.grey));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: labels.map((l) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(l, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          )).toList(),
        ),
        pw.TableRow(
          children: data.map((d) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text('$d', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
          )).toList(),
        ),
      ],
    );
  }

  pw.Widget _pdfSectionsTable(List<dynamic> sections) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rank', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Section', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Average', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
          ],
        ),
        ...List.generate(sections.length, (i) {
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('#${i + 1}', style: const pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(sections[i]['name'] ?? '', style: const pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${sections[i]['average']}%', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        }),
      ],
    );
  }
}
