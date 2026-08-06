import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers.dart';
import 'dart:math' as math;

class ProfileState {
  final String? customDisplayName;
  final String profilePhotoMode; // 'google', 'custom', 'none'
  final String? customProfilePhotoPath;
  final double profilePhotoSize;

  ProfileState({
    this.customDisplayName,
    required this.profilePhotoMode,
    this.customProfilePhotoPath,
    required this.profilePhotoSize,
  });

  ProfileState copyWith({
    String? customDisplayName,
    String? profilePhotoMode,
    String? customProfilePhotoPath,
    double? profilePhotoSize,
    bool clearCustomDisplayName = false,
    bool clearCustomProfilePhotoPath = false,
  }) {
    return ProfileState(
      customDisplayName: clearCustomDisplayName ? null : (customDisplayName ?? this.customDisplayName),
      profilePhotoMode: profilePhotoMode ?? this.profilePhotoMode,
      customProfilePhotoPath: clearCustomProfilePhotoPath ? null : (customProfilePhotoPath ?? this.customProfilePhotoPath),
      profilePhotoSize: profilePhotoSize ?? this.profilePhotoSize,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    _load();
    return ProfileState(profilePhotoMode: 'google', profilePhotoSize: 40.0);
  }

  Future<void> _load() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final customName = prefs.getString('custom_display_name');
      final photoMode = prefs.getString('profile_photo_mode') ?? 'google';
      final photoPath = prefs.getString('custom_profile_photo_path');
      final photoSize = prefs.getDouble('profile_photo_size') ?? 40.0;
      state = ProfileState(
        customDisplayName: customName,
        profilePhotoMode: photoMode,
        customProfilePhotoPath: photoPath,
        profilePhotoSize: photoSize,
      );
    } catch (_) {}
  }

  Future<void> setCustomDisplayName(String? name) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (name == null || name.trim().isEmpty) {
      await prefs.remove('custom_display_name');
      state = state.copyWith(clearCustomDisplayName: true);
    } else {
      await prefs.setString('custom_display_name', name.trim());
      state = state.copyWith(customDisplayName: name.trim());
    }
  }

  Future<void> setProfilePhotoMode(String mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('profile_photo_mode', mode);
    state = state.copyWith(profilePhotoMode: mode);
  }

  Future<void> setCustomProfilePhotoPath(String? path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final oldPath = state.customProfilePhotoPath;

    // Evict old FileImage from memory cache if present
    if (oldPath != null && !kIsWeb && oldPath.startsWith('/')) {
      try {
        final oldFile = io.File(oldPath);
        PaintingBinding.instance.imageCache.evict(FileImage(oldFile));
      } catch (_) {}
    }

    if (path == null) {
      await prefs.remove('custom_profile_photo_path');
      state = state.copyWith(clearCustomProfilePhotoPath: true);
    } else {
      String persistentPath = path;
      if (!kIsWeb) {
        try {
          final sourceFile = io.File(path);
          if (await sourceFile.exists()) {
            final docsDir = await getApplicationDocumentsDirectory();
            // Clean up old custom profile photo files in documents directory
            try {
              final entities = docsDir.listSync();
              for (final entity in entities) {
                if (entity is io.File &&
                    (entity.path.contains('profile_avatar') ||
                        entity.path.contains('custom_profile_'))) {
                  if (entity.path != sourceFile.path) {
                    try {
                      entity.deleteSync();
                    } catch (_) {}
                  }
                }
              }
            } catch (_) {}

            // Save with unique timestamp to ensure fresh image caching
            final targetPath =
                '${docsDir.path}/custom_profile_${DateTime.now().millisecondsSinceEpoch}.png';
            final savedImage = await sourceFile.copy(targetPath);
            persistentPath = savedImage.path;
          }
        } catch (_) {}
      }
      await prefs.setString('custom_profile_photo_path', persistentPath);
      state = state.copyWith(customProfilePhotoPath: persistentPath);
    }
  }

  Future<void> setProfilePhotoSize(double size) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('profile_photo_size', size);
    state = state.copyWith(profilePhotoSize: size);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});

final displayNameProvider = Provider<String?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile.customDisplayName != null && profile.customDisplayName!.isNotEmpty) {
    return profile.customDisplayName;
  }
  final authAsync = ref.watch(authProvider);
  final authState = authAsync.value;
  if (authState != null && authState.user != null) {
    return authState.user!.displayName;
  }
  return null;
});

final displayProfileImageProvider = Provider<ImageProvider?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile.profilePhotoMode == 'custom') {
    if (profile.customProfilePhotoPath != null) {
      if (kIsWeb) {
        final path = profile.customProfilePhotoPath!;
        if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
          return NetworkImage(path);
        }
        try {
          final cleanBase64 = path.contains(',') ? path.split(',')[1] : path;
          return MemoryImage(base64Decode(cleanBase64.trim()));
        } catch (_) {}
        return null;
      } else {
        try {
          final file = io.File(profile.customProfilePhotoPath!);
          if (file.existsSync() && file.lengthSync() > 0) {
            return FileImage(file);
          }
        } catch (_) {}
      }
    }
    return null;
  } else if (profile.profilePhotoMode == 'google') {
    final authAsync = ref.watch(authProvider);
    final authState = authAsync.value;
    if (authState != null && authState.user != null && authState.user!.photoURL != null) {
      return NetworkImage(authState.user!.photoURL!);
    }
    return null;
  }
  return null;
});

class LaunchQuoteNotifier extends Notifier<String> {
  String? _selected;

  @override
  String build() {
    final quotes = ref.watch(quotesProvider);
    if (_selected == null && quotes.isNotEmpty) {
      _selected = quotes[math.Random().nextInt(quotes.length)];
    }
    return _selected ?? (quotes.isNotEmpty ? quotes.first : "Consistency is key.");
  }
}

final launchQuoteProvider = NotifierProvider<LaunchQuoteNotifier, String>(() {
  return LaunchQuoteNotifier();
});
