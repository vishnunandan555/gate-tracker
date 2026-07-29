import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardEmptyState extends StatelessWidget {
  final VoidCallback? onSetupTap;

  const DashboardEmptyState({
    super.key,
    this.onSetupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.cyanAccent.withAlpha(80)),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: Colors.cyanAccent,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No Syllabus Topics Found",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Complete initial setup or select a GATE branch to initialize syllabus progress tracking.",
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSetupTap ?? () => context.go('/setup'),
              icon: const Icon(Icons.rocket_launch_rounded, size: 16),
              label: Text(
                "Start Setup",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
