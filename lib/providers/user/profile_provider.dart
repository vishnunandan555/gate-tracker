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
            final savedImage = await sourceFile.copy('${docsDir.path}/profile_avatar.png');
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
        if (profile.customProfilePhotoPath!.startsWith('data:image') ||
            !profile.customProfilePhotoPath!.contains('/')) {
          try {
            final cleanBase64 = profile.customProfilePhotoPath!.contains(',')
                ? profile.customProfilePhotoPath!.split(',')[1]
                : profile.customProfilePhotoPath!;
            return MemoryImage(base64Decode(cleanBase64));
          } catch (_) {}
        }
        return null;
      } else {
        final file = io.File(profile.customProfilePhotoPath!);
        if (file.existsSync() && file.lengthSync() > 0) {
          return FileImage(file);
        }
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
