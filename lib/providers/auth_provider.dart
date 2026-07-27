import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sync_provider.dart';
import 'setup_provider.dart';
import 'syllabus_provider.dart';
import 'windows_auth_helper.dart';

// Check if Firebase is supported on the current platform
bool isFirebaseSupported() {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}

class AuthState {
  final User? user;
  final bool isOfflineMode;
  final bool isLoading;

  AuthState({
    this.user,
    required this.isOfflineMode,
    required this.isLoading,
  });

  AuthState copyWith({
    User? user,
    bool? isOfflineMode,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late SharedPreferences _prefs;

  @override
  Future<AuthState> build() async {
    _prefs = await SharedPreferences.getInstance();
    final hasChosenOffline = _prefs.getBool('has_chosen_offline') ?? false;

    if (!isFirebaseSupported()) {
      // Force offline mode for unsupported platforms (e.g. desktop)
      return AuthState(user: null, isOfflineMode: true, isLoading: false);
    }

    // Return the initial state matching current FirebaseAuth user
    final auth = FirebaseAuth.instance;
    return AuthState(
      user: auth.currentUser,
      isOfflineMode: hasChosenOffline,
      isLoading: false,
    );
  }

  // Set the offline choice
  Future<void> chooseOfflineMode() async {
    state = const AsyncValue.loading();
    await _prefs.setBool('has_chosen_offline', true);
    state = AsyncValue.data(AuthState(
      user: null,
      isOfflineMode: true,
      isLoading: false,
    ));
  }

  // Handle Google Sign-In
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      if (!isFirebaseSupported()) {
        throw UnsupportedError('Firebase is not supported on this platform.');
      }

      final UserCredential userCredential;

      if (kIsWeb) {
        // Use Firebase Auth's native signInWithPopup for Web. This runs inside Firebase's
        // auth handler domain, bypassing GIS (Google Identity Services) iframe restrictions
        // and resolving the common 'popup_closed' error in Firefox/Safari.
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        // Windows Desktop OAuth 2.0 Loopback flow
        userCredential = await signInWithGoogleWindows();
      } else {
        // Mobile platform (Android/iOS) uses the GoogleSignIn package flow
        final GoogleSignInAccount googleUser;
        try {
          googleUser = await GoogleSignIn.instance.authenticate();
        } catch (e) {
          // User cancelled the sign-in flow or initialization/auth failed
          final currentOffline = _prefs.getBool('has_chosen_offline') ?? false;
          state = AsyncValue.data(AuthState(
            user: null,
            isOfflineMode: currentOffline,
            isLoading: false,
          ));
          return;
        }

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // Disable offline mode on successful login
      await _prefs.setBool('has_chosen_offline', false);

      state = AsyncValue.data(AuthState(
        user: userCredential.user,
        isOfflineMode: false,
        isLoading: false,
      ));
    } catch (e, stack) {
      final currentOffline = _prefs.getBool('has_chosen_offline') ?? false;
      state = AsyncValue.error(e, stack);
      // Fallback to previous state
      state = AsyncValue.data(AuthState(
        user: FirebaseAuth.instance.currentUser,
        isOfflineMode: currentOffline,
        isLoading: false,
      ));
      rethrow;
    }
  }

  Future<void> _wipeLocalUserData() async {
    // 1. Wipe the local database completely
    try {
      final db = ref.read(appDatabaseProvider);
      await db.wipeDatabaseData();
    } catch (e) {
      debugPrint("Error wiping database: $e");
    }

    // 2. Reset setup/onboarding completion status
    try {
      await ref.read(setupCompletedProvider.notifier).resetSetup(forceOnboarding: true);
    } catch (e) {
      debugPrint("Error resetting setup: $e");
    }

    // 3. Clear all user-session-specific shared preferences keys
    try {
      const keysToRemove = [
        'selected_branch',
        'daily_focus_goal',
        'check_in_goal_minutes',
        'weak_category_ids',
        'weak_topic_ids',
        'overall_progress_color',
        'stats_is_heatmap_mode',
        'accent_color_mode',
        'frozen_accent_color',
        'custom_nav_bar_slots_ids',
        'profile_photo_mode',
        'custom_display_name',
        'custom_profile_photo_path',
        'category_font_size',
        'topic_font_size',
        'task_font_size',
        'overall_ui_scale',
        'focus_selected_method_index',
        'focus_custom_timer_minutes',
        'target_date',
        'disable_countdown',
        'disable_graph_glow',
        'disable_home_screen_widget',
        // Notification read state — cleared so 30-day window applies on next sign-in
        'read_community_notification_ids',
        'cached_community_notifications_json',
      ];
      for (final key in keysToRemove) {
        await _prefs.remove(key);
      }
    } catch (e) {
      debugPrint("Error resetting prefs: $e");
    }
  }

  // Handle Sign-Out
  Future<void> signOut({bool keepLocalData = false}) async {
    state = const AsyncValue.loading();
    try {
      if (isFirebaseSupported()) {
        if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          await GoogleSignIn.instance.signOut();
        }
        await FirebaseAuth.instance.signOut();
      }
      if (keepLocalData) {
        await _prefs.setBool('has_chosen_offline', true);
      } else {
        await _prefs.setBool('has_chosen_offline', false);
        await _wipeLocalUserData();
      }
      try {
        await ref.read(syncProvider.notifier).clearSyncState();
      } catch (e) {
        debugPrint("Error clearing sync state: $e");
      }
      state = AsyncValue.data(AuthState(
        user: null,
        isOfflineMode: keepLocalData,
        isLoading: false,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Reset the onboarding choice (e.g. to configure again)
  Future<void> resetAuthChoice() async {
    state = const AsyncValue.loading();
    await _prefs.remove('has_chosen_offline');
    if (isFirebaseSupported()) {
      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        await GoogleSignIn.instance.signOut();
      }
      await FirebaseAuth.instance.signOut();
    }
    await _wipeLocalUserData();
    try {
      await ref.read(syncProvider.notifier).clearSyncState();
    } catch (e) {
      debugPrint("Error clearing sync state: $e");
    }
    state = AsyncValue.data(AuthState(
      user: null,
      isOfflineMode: false,
      isLoading: false,
    ));
  }

  // Delete user account and all Firestore backups
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete Firestore document first
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        } catch (e) {
          debugPrint("Error deleting user Firestore data: $e");
        }
        // Delete FirebaseAuth user
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            if (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) {
              final googleUser = await GoogleSignIn.instance.authenticate();
              final googleAuth = googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                idToken: googleAuth.idToken,
              );
              await user.reauthenticateWithCredential(credential);
              await user.delete();
            } else {
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      }
      if (isFirebaseSupported()) {
        if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          await GoogleSignIn.instance.signOut();
        }
      }
      await _prefs.setBool('has_chosen_offline', false);
      await _prefs.remove('account_creation_date');
      await _wipeLocalUserData();
      try {
        await ref.read(syncProvider.notifier).clearSyncState();
      } catch (e) {
        debugPrint("Error clearing sync state: $e");
      }
      state = AsyncValue.data(AuthState(
        user: null,
        isOfflineMode: false,
        isLoading: false,
      ));
    } catch (e) {
      final currentOffline = _prefs.getBool('has_chosen_offline') ?? false;
      state = AsyncValue.data(AuthState(
        user: FirebaseAuth.instance.currentUser,
        isOfflineMode: currentOffline,
        isLoading: false,
      ));
      rethrow;
    }
  }

  // Delete user account data on Firebase/Firestore server only
  Future<void> deleteServerAccountOnly() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Delete Firestore document first
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      } catch (e) {
        debugPrint("Error deleting user Firestore data: $e");
      }
      // Delete FirebaseAuth user
      await user.delete();
    }
    await _prefs.remove('account_creation_date');
  }

  // Complete local sign out after confirming server deletion
  Future<void> completeLocalSignOut() async {
    state = const AsyncValue.loading();
    try {
      if (isFirebaseSupported()) {
        if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          await GoogleSignIn.instance.signOut();
        }
        await FirebaseAuth.instance.signOut();
      }
      await _prefs.setBool('has_chosen_offline', false);
      await _prefs.remove('account_creation_date');
      try {
        await ref.read(syncProvider.notifier).clearSyncState();
      } catch (e) {
        debugPrint("Error clearing sync state: $e");
      }
      state = AsyncValue.data(AuthState(
        user: null,
        isOfflineMode: false,
        isLoading: false,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Switch to local offline mode after server account deletion (preserving local data)
  Future<void> switchToOfflineAfterAccountDeletion() async {
    state = const AsyncValue.loading();
    try {
      if (isFirebaseSupported()) {
        if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          await GoogleSignIn.instance.signOut();
        }
        await FirebaseAuth.instance.signOut();
      }
      await _prefs.setBool('has_chosen_offline', true);
      try {
        await ref.read(syncProvider.notifier).clearSyncState();
      } catch (e) {
        debugPrint("Error clearing sync state: $e");
      }
      state = AsyncValue.data(AuthState(
        user: null,
        isOfflineMode: true,
        isLoading: false,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final accountCreationDateProvider = FutureProvider<DateTime>((ref) async {
  final authState = ref.watch(authProvider).value;
  final firebaseUser = authState?.user;
  if (firebaseUser != null && firebaseUser.metadata.creationTime != null) {
    return firebaseUser.metadata.creationTime!;
  }
  final prefs = await SharedPreferences.getInstance();
  final localStr = prefs.getString('account_creation_date');
  if (localStr != null) {
    final date = DateTime.tryParse(localStr);
    if (date != null) return date;
  }
  final now = DateTime.now();
  await prefs.setString('account_creation_date', now.toIso8601String());
  return now;
});
