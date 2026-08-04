import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme/theme_context_ext.dart';
import 'package:gateletics/providers/providers.dart';

class ProfileSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const ProfileSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final displayName = ref.watch(displayNameProvider);
    final displayImage = ref.watch(displayProfileImageProvider);
    final authAsync = ref.watch(authProvider);
    final isGoogleUser = authAsync.value?.user != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.badge_rounded, color: context.appColors.textSecondary),
          title: Text('Change Display Name', style: titleStyle),
          subtitle: Text(
            'Current: ${profile.customDisplayName != null ? profile.customDisplayName! : (displayName ?? 'Not set')}',
            style: subtitleStyle,
          ),
          trailing: IconButton(
            icon: Icon(Icons.edit_rounded, color: context.appColors.textSecondary),
            onPressed: () async {
              final controller = TextEditingController(text: profile.customDisplayName ?? displayName ?? '');
              final result = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: context.appColors.surfaceColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: const Text("Set Custom Name"),
                  content: TextField(
                    controller: controller,
                    style: GoogleFonts.outfit(color: context.appColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: "Enter name",
                      hintStyle: GoogleFonts.outfit(color: context.appColors.textMuted),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: accentColor),
                      ),
                    ),
                    maxLength: 30,
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(profileProvider.notifier).setCustomDisplayName(null);
                        Navigator.pop(ctx);
                      },
                      child: Text('Reset', style: GoogleFonts.outfit(color: Colors.redAccent)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: context.appColors.onAccent,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (result != null) {
                await ref.read(profileProvider.notifier).setCustomDisplayName(result);
              }
            },
          ),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.appColors.borderColor, width: 1),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: displayImage,
              backgroundColor: context.appColors.surfaceColor,
              child: displayImage == null ? Icon(Icons.person, size: 18, color: context.appColors.textSecondary) : null,
            ),
          ),
          title: Text('Set Profile Photo', style: titleStyle),
          subtitle: Text(
            profile.profilePhotoMode == 'custom'
                ? 'Current: Custom Photo'
                : profile.profilePhotoMode == 'google'
                    ? 'Current: Google Avatar'
                    : 'No Profile Photo',
            style: subtitleStyle,
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.photo_camera_rounded, color: context.appColors.textSecondary),
            color: context.appColors.dialogBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'none') {
                await ref.read(profileProvider.notifier).setProfilePhotoMode('none');
              } else if (val == 'google') {
                await ref.read(profileProvider.notifier).setProfilePhotoMode('google');
              } else if (val == 'pick') {
                final result = await FilePicker.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  final bytes = await file.readAsBytes();
                  String savedPath;
                  if (file.path != null && !kIsWeb) {
                    savedPath = file.path!;
                  } else {
                    savedPath = 'data:image/png;base64,${base64Encode(bytes)}';
                  }

                  await ref.read(profileProvider.notifier).setCustomProfilePhotoPath(savedPath);
                  await ref.read(profileProvider.notifier).setProfilePhotoMode('custom');
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pick',
                child: Row(
                  children: [
                    Icon(Icons.photo_library_rounded, size: 18, color: context.appColors.textSecondary),
                    const SizedBox(width: 8),
                    Text('Choose Custom Photo', style: GoogleFonts.outfit(color: context.appColors.textPrimary)),
                  ],
                ),
              ),
              if (isGoogleUser)
                PopupMenuItem(
                  value: 'google',
                  child: Row(
                    children: [
                      Icon(Icons.account_circle_rounded, size: 18, color: context.appColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('Use Google Photo', style: GoogleFonts.outfit(color: context.appColors.textPrimary)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'none',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Text('Remove Photo', style: GoogleFonts.outfit(color: context.appColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
