import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/syllabus_provider.dart';

// Convert To Counter Card Dialog
void showConvertToCounterCardDialog(BuildContext context, SyllabusTopic topic, Color accentColor, WidgetRef ref) {
  final countController = TextEditingController(text: topic.maxCount > 0 ? topic.maxCount.toString() : '10');

  String existingLabel = '';
  final rawUrl = topic.resourceUrl ?? '';
  if (rawUrl.trim().isNotEmpty) {
    final parts = rawUrl.trim().split('|');
    if (parts.length > 2) {
      existingLabel = parts[2].trim();
    }
  }

  final labelController = TextEditingController(text: existingLabel.isNotEmpty ? existingLabel : 'Subtasks');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'CONVERT TO COUNTER CARD',
        style: GoogleFonts.jersey15(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: accentColor,
          letterSpacing: 0.8,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Convert "${topic.name}" into a numeric counter (e.g. 0/10 Question Sets or 0/15 Lectures completed).',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Target Max Count (e.g., 10)',
              labelStyle: GoogleFonts.outfit(color: Colors.white60),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: labelController,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Unit Label (e.g., PYQ Sets / Modules / Hours)',
              labelStyle: GoogleFonts.outfit(color: Colors.white60),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (topic.isCounter)
          TextButton(
            onPressed: () {
              ref.read(syllabusControllerProvider.notifier).convertToCounterCard(topic.id, topic.name, 0, topic.resourceUrl);
              Navigator.pop(context);
            },
            child: Text('REVERT TO TASKS', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            final maxC = int.tryParse(countController.text.trim()) ?? 10;
            final label = labelController.text.trim();
            if (maxC > 0) {
              final formattedLink = label.isNotEmpty ? '||$label' : topic.resourceUrl;
              ref.read(syllabusControllerProvider.notifier).convertToCounterCard(
                topic.id,
                topic.name,
                maxC,
                formattedLink,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('CONVERT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// Edit Counter Card Dialog
void showEditCounterCardDialog(BuildContext context, SyllabusTopic topic, Color accentColor, WidgetRef ref) {
  final currentCountController = TextEditingController(text: topic.currentCount.toString());
  final maxCountController = TextEditingController(text: topic.maxCount.toString());

  String existingLabel = '';
  final rawUrl = topic.resourceUrl ?? '';
  if (rawUrl.trim().isNotEmpty) {
    final parts = rawUrl.trim().split('|');
    if (parts.length > 2) {
      existingLabel = parts[2].trim();
    }
  }

  final labelController = TextEditingController(text: existingLabel.isNotEmpty ? existingLabel : 'Subtasks');

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'EDIT COUNTER CARD',
        style: GoogleFonts.jersey15(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: accentColor,
          letterSpacing: 0.8,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: currentCountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Completed',
                    labelStyle: GoogleFonts.outfit(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF27272A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: maxCountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Target Max',
                    labelStyle: GoogleFonts.outfit(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF27272A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: labelController,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Unit Label (e.g., PYQs / Lectures)',
              labelStyle: GoogleFonts.outfit(color: Colors.white60),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(syllabusControllerProvider.notifier).convertToCounterCard(topic.id, topic.name, 0, topic.resourceUrl);
            Navigator.pop(context);
          },
          child: Text('REVERT TO TASKS', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            final cur = int.tryParse(currentCountController.text.trim()) ?? topic.currentCount;
            final maxC = int.tryParse(maxCountController.text.trim()) ?? topic.maxCount;
            final label = labelController.text.trim();
            if (maxC > 0) {
              final formattedLink = label.isNotEmpty ? '||$label' : topic.resourceUrl;
              ref.read(syllabusControllerProvider.notifier).updateCounterCard(
                topic.id,
                topic.name,
                cur.clamp(0, maxC),
                maxC,
                formattedLink,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
