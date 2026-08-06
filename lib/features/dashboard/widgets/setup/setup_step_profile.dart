import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/theme_context_ext.dart';
import '../../../../utils/ui_scaling.dart';
import 'package:gateletics/providers/providers.dart';
import 'setup_step_widgets.dart';

class SetupStepProfile extends ConsumerWidget {
  final Color accentColor;
  final TextEditingController nameController;
  final String displayName;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNext;

  const SetupStepProfile({
    super.key,
    required this.accentColor,
    required this.nameController,
    required this.displayName,
    required this.onNameChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileImage = ref.watch(displayProfileImageProvider);

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SetupStepHeader(
          title: "WELCOME TO GATELETICS",
          subtitle: "Let's personalize your exam preparation dashboard.",
        ),
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
              image: profileImage != null
                  ? DecorationImage(image: profileImage, fit: BoxFit.cover)
                  : null,
            ),
            child: profileImage == null
                ? Icon(Icons.person_rounded, size: 48, color: context.appColors.textSecondary)
                : null,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "YOUR DISPLAY NAME",
          style: GoogleFonts.orbitron(
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            color: context.appColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          onChanged: onNameChanged,
          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Enter your name",
            hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
            filled: true,
            fillColor: context.appColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.appColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 48),
        SetupNavigationRow(
          accentColor: accentColor,
          onNext: displayName.trim().isNotEmpty ? onNext : null,
          nextLabel: "CONTINUE",
        ),
      ],
    );
  }
}
