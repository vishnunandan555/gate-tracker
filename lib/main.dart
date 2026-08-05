import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/brand_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_context_ext.dart';
import 'database/app_database.dart';
import 'package:gateletics/providers/providers.dart';
import 'features/dashboard/widgets/agreement_screen.dart';
import 'features/dashboard/widgets/auth_screen.dart';
import 'features/dashboard/widgets/setup_screen.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/route_resolver.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  if (isFirebaseSupported()) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAuth.instance.setLanguageCode('en');
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        await GoogleSignIn.instance.initialize();
      }
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android
              || defaultTargetPlatform == TargetPlatform.iOS
              || defaultTargetPlatform == TargetPlatform.macOS)) {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        if (kDebugMode) {
          await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
        }
      }
    } catch (e) {
      debugPrint("Firebase/GoogleSignIn initialization failed: $e");
    }
  }

  final prefs = await SharedPreferences.getInstance();
  persistedUserWantsDesktopUI = prefs.getBool('user_wants_desktop_ui');

  final packageInfo = await PackageInfo.fromPlatform();
  final appDb = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
        packageInfoProvider.overrideWithValue(packageInfo),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const GateTrackerApp(),
    ),
  );
}

class GateTrackerApp extends ConsumerWidget {
  const GateTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start listening and saving daily stats snapshots
    ref.watch(dailyHistoryManagerProvider);

    final lightTheme = ref.watch(lightAppThemeProvider);
    final darkTheme = ref.watch(darkAppThemeProvider);
    final themeMode = ref.watch(activeThemeModeProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final systemColor = darkDynamic?.primary ?? lightDynamic?.primary;
        if (systemColor != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(systemAccentColorProvider.notifier).setSystemAccent(systemColor);
          });
        }

        return MaterialApp(
          title: BrandConfig.appName,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 250),
          themeAnimationCurve: Curves.easeInOut,
          debugShowCheckedModeBanner: false,
          home: const AppContentResolver(),
        );
      },
    );
  }
}

class AppContentResolver extends ConsumerWidget {
  const AppContentResolver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(overallProgressColorProvider);
    final agreementAsync = ref.watch(agreementProvider);
    final authAsync = ref.watch(authProvider);
    final setupAsync = ref.watch(setupCompletedProvider);
    final activeThemeData = ref.watch(activeAppThemeProvider);

    if (agreementAsync.isLoading || authAsync.isLoading || setupAsync.isLoading) {
      return Scaffold(
        key: const ValueKey('loading_screen'),
        backgroundColor: activeThemeData.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    if (agreementAsync.hasError || authAsync.hasError || setupAsync.hasError) {
      return Scaffold(
        key: const ValueKey('error_screen'),
        backgroundColor: activeThemeData.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong on startup',
                  style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please restart the app. If the issue persists, try reinstalling.',
                  style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasAgreed = agreementAsync.value ?? false;
    final authState = authAsync.value;
    final hasSetup = setupAsync.value ?? false;

    Widget targetWidget;
    if (!hasAgreed) {
      targetWidget = const AgreementScreen(key: ValueKey('agreement_screen'));
    } else if (authState != null && !authState.isOfflineMode && authState.user == null) {
      targetWidget = const AuthScreen(key: ValueKey('auth_screen'));
    } else if (!hasSetup) {
      targetWidget = const SetupScreen(key: ValueKey('setup_screen'));
    } else {
      targetWidget = KeyedSubtree(
        key: const ValueKey('app_router'),
        child: Router.withConfig(config: appRouter),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: targetWidget,
    );
  }
}
