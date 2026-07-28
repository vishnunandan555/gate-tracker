import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'database/app_database.dart';
import 'providers/syllabus_provider.dart';
import 'providers/agreement_provider.dart';
import 'providers/setup_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/daily_history_provider.dart';
import 'features/dashboard/widgets/agreement_screen.dart';
import 'features/dashboard/widgets/auth_screen.dart';
import 'features/dashboard/widgets/setup_screen.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'providers/package_info_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/route_resolver.dart';

import 'package:firebase_core/firebase_core.dart';
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
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        await GoogleSignIn.instance.initialize();
      }
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)) {
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

    final agreementAsync = ref.watch(agreementProvider);
    final authAsync = ref.watch(authProvider);
    final setupAsync = ref.watch(setupCompletedProvider);

    if (agreementAsync.isLoading || authAsync.isLoading || setupAsync.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF09090B),
          body: Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
        ),
      );
    }

    if (agreementAsync.hasError || authAsync.hasError || setupAsync.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF09090B),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong on startup',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please restart the app. If the issue persists, try reinstalling.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final hasAgreed = agreementAsync.value ?? false;
    final authState = authAsync.value;
    final hasSetup = setupAsync.value ?? false;

    if (!hasAgreed) {
      return MaterialApp(
        title: 'GATEletics',
        theme: AppTheme.darkTheme,
        home: const AgreementScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    if (authState != null && !authState.isOfflineMode && authState.user == null) {
      return MaterialApp(
        title: 'GATEletics',
        theme: AppTheme.darkTheme,
        home: const AuthScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    if (!hasSetup) {
      return MaterialApp(
        title: 'GATEletics',
        theme: AppTheme.darkTheme,
        home: const SetupScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      title: 'GATEletics',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
