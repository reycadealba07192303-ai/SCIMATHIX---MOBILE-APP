import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:scimathix/core/theme/app_theme.dart';

class AdminSystemMonitoringScreen extends StatelessWidget {
  const AdminSystemMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "System Monitoring",
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHealthStatus(),
            const SizedBox(height: 32),
            _buildSectionLabel("Real-Time Metrics"),
            const SizedBox(height: 16),
            _buildMetricsGrid(),
            const SizedBox(height: 32),
            _buildSectionLabel("Resource Monitoring"),
            const SizedBox(height: 16),
            _buildMonitoringCard("AI Token Usage", "Current usage: 4.2k / 10k", CupertinoIcons.sparkles, AppTheme.primaryColor, 0.42),
            _buildMonitoringCard("Storage Capacity", "Current usage: 1.2GB / 5GB", CupertinoIcons.cloud, AppTheme.secondaryColor, 0.24),
            _buildMonitoringCard("Active Connections", "Currently active: 84 users", CupertinoIcons.person_3, AppTheme.accentColor, 0.68),
            const SizedBox(height: 32),
            _buildSectionLabel("Recent System Logs"),
            const SizedBox(height: 16),
            _buildSystemLogs(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatus() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.checkmark_shield_fill, color: Colors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("System Health", style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                  Text("All systems are operational", style: GoogleFonts.inter(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Text("99.9% Uptime", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.subtleText)),
          ],
        ),
      ),
    );
  }

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

  Widget _buildMetricsGrid() {
    return FadeInUp(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildMetricTile("CPU Load", "12%", CupertinoIcons.gauge, Colors.blue),
          _buildMetricTile("Memory", "1.4 GB", CupertinoIcons.device_desktop, Colors.purple),
          _buildMetricTile("Latency", "42 ms", CupertinoIcons.speedometer, Colors.orange),
          _buildMetricTile("Threads", "142", CupertinoIcons.list_bullet, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textColor)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringCard(String title, String subtitle, IconData icon, Color color, double progress) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textColor)),
                      Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.subtleText)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemLogs() {
    return FadeInUp(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            _buildLogItem("Database backup initiated", "12:00 PM", Colors.blue),
            _buildLogItem("New teacher account verified", "11:45 AM", Colors.green),
            _buildLogItem("Security patch applied", "10:30 AM", AppTheme.accentColor),
            _buildLogItem("Failed login attempt detected", "09:15 AM", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(String message, String time, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textColor))),
          Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.subtleText)),
        ],
      ),
    );
  }
}
