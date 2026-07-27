import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/subject_provider.dart';
import '../../../utils/ui_scaling.dart';

class ContributeScreen extends ConsumerWidget {
  const ContributeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(overallProgressColorProvider);

    final cards = [
      _ContributeCardData(
        icon: Icons.code_rounded,
        title: 'GitHub Repository',
        description: 'Explore the open source codebase, star the repo, or build custom features.',
        color: const Color(0xFF00F0FF),
        actionLabel: 'Open GitHub',
        onTap: () => _launch('https://github.com/vishnunandan555/gateletics'),
      ),
      _ContributeCardData(
        icon: Icons.bug_report_rounded,
        title: 'Report an Issue or Bug',
        description: 'Found a problem or unexpected behavior? Submit an issue report directly.',
        color: const Color(0xFFFF5E00),
        actionLabel: 'Report Bug',
        onTap: () => _launch('https://github.com/vishnunandan555/gateletics/issues'),
      ),
      _ContributeCardData(
        icon: Icons.school_rounded,
        title: 'Request Your Exam / Branch',
        description: 'Need GATE EE, ECE, ME, Civil, or another branch added to GATEletics?',
        color: const Color(0xFFE040FB),
        actionLabel: 'Request Exam',
        isPlaceholder: true,
        onTap: () => _showPlaceholderDialog(
          context,
          'Request Exam / Branch',
          'Exam stream requests will be available soon! You can also request branches on our GitHub Issues page.',
          accentColor,
        ),
      ),
      _ContributeCardData(
        icon: Icons.library_add_rounded,
        title: 'Add Your Own Resource',
        description: 'Share notes, formulas, test series recommendations, or study resources with peers.',
        color: const Color(0xFF00FFCC),
        actionLabel: 'Submit Resource',
        isPlaceholder: true,
        onTap: () => _showPlaceholderDialog(
          context,
          'Submit Study Resource',
          'Community resource submissions will be live in an upcoming release!',
          accentColor,
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Contribute to Community',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(context.s(16)),
          children: [
            // Header Banner
            Container(
              padding: EdgeInsets.all(context.s(20)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    const Color(0xFF131316),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.volunteer_activism_rounded, color: accentColor, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Built by Students, for Students',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: context.s(15),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'GATEletics is completely open-source. Help us expand exam coverage, improve progress tracking, and build community resources.',
                    style: GoogleFonts.outfit(
                      color: Colors.white60,
                      fontSize: context.s(12),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: context.s(20)),

            Text(
              'COMMUNITY ACTIONS',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            ...cards.map((data) => _buildCard(context, data, accentColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _ContributeCardData data, Color accentColor) {
    return Container(
      margin: EdgeInsets.only(bottom: context.s(12)),
      padding: EdgeInsets.all(context.s(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: data.color.withValues(alpha: 0.35)),
                ),
                child: Center(
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        data.title,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: context.s(14),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (data.isPlaceholder) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: data.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: data.color.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'SOON',
                          style: GoogleFonts.outfit(
                            color: data.color,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.description,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: context.s(11.5),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: data.onTap,
              icon: Icon(
                data.isPlaceholder ? Icons.schedule_rounded : Icons.open_in_new_rounded,
                size: 14,
                color: Colors.black,
              ),
              label: Text(
                data.actionLabel,
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: data.color,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showPlaceholderDialog(BuildContext context, String title, String message, Color accentColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Got it', style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ContributeCardData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String actionLabel;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _ContributeCardData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.actionLabel,
    this.isPlaceholder = false,
    required this.onTap,
  });
}
