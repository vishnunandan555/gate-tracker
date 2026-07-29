import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/profile_provider.dart';

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
          leading: const Icon(Icons.badge_rounded, color: Colors.white60),
          title: Text('Change Display Name', style: titleStyle),
          subtitle: Text(
            'Current: ${profile.customDisplayName != null ? profile.customDisplayName! : (displayName ?? 'Not set')}',
            style: subtitleStyle,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white60),
            onPressed: () async {
              final controller = TextEditingController(text: profile.customDisplayName ?? displayName ?? '');
              final result = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: const Text("Set Custom Name"),
                  content: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter name",
                      hintStyle: const TextStyle(color: Colors.white30),
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
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(profileProvider.notifier).setCustomDisplayName(null);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
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
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: displayImage,
              backgroundColor: Colors.white12,
              child: displayImage == null ? const Icon(Icons.person, size: 18, color: Colors.white54) : null,
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
            icon: const Icon(Icons.photo_camera_rounded, color: Colors.white60),
            color: const Color(0xFF1F1F23),
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
              const PopupMenuItem(
                value: 'pick',
                child: Row(
                  children: [
                    Icon(Icons.photo_library_rounded, size: 18, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Choose Custom Photo', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              if (isGoogleUser)
                const PopupMenuItem(
                  value: 'google',
                  child: Row(
                    children: [
                      Icon(Icons.account_circle_rounded, size: 18, color: Colors.white70),
                      SizedBox(width: 8),
                      Text('Use Google Photo', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'none',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Remove Photo', style: TextStyle(color: Colors.white)),
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
