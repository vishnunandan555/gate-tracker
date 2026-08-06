import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/desk/desk_dashboard_shell.dart';
import '../../features/dashboard/settings_screen.dart';
import '../../features/dashboard/progress_history_screen.dart';
import '../../features/more/screens/accounts_screen.dart';
import '../../features/more/screens/about_screen.dart';
import '../../features/more/screens/contribute_screen.dart';
import '../../features/more/screens/customize_ui_screen.dart';
import '../../features/more/screens/customize_nav_bar_screen.dart';
import '../../features/dashboard/widgets/setup_screen.dart';
import '../../features/dashboard/widgets/agreement_screen.dart';
import '../../features/dashboard/widgets/auth_screen.dart';
import '../../features/resources/resource_explorer_screen.dart';
import 'route_resolver.dart';

import '../theme/theme_context_ext.dart';

final appRouter = GoRouter(
  initialLocation: resolveInitialRoute(),
  redirect: (context, state) {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS)) {
      if (state.uri.path.startsWith('/desk')) {
        return '/';
      }
    }
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
         defaultTargetPlatform == TargetPlatform.linux ||
         defaultTargetPlatform == TargetPlatform.macOS)) {
      if (state.uri.path == '/') {
        return '/desk';
      }
    }
    if (kIsWeb) {
      double? logicalWidth;
      try {
        final view = PlatformDispatcher.instance.views.first;
        logicalWidth = view.physicalSize.width / view.devicePixelRatio;
      } catch (_) {}

      final isDesktopWidth = (logicalWidth ?? 0) >= 768;
      final prefersDesktop = persistedUserWantsDesktopUI == true;

      if (state.uri.path.startsWith('/desk')) {
        if (!isDesktopWidth && !prefersDesktop) {
          return '/';
        }
      }

      if (state.uri.path == '/') {
        if (prefersDesktop || isDesktopWidth) {
          return '/desk';
        }
      }
    }
    return null;
  },
  errorBuilder: (context, state) {
    final primaryColor = context.appColors.primaryAccent;
    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: primaryColor, size: 48),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: TextStyle(color: context.appColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'No route found for ${state.uri.path}',
              style: TextStyle(color: context.appColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardShell()),
    GoRoute(path: '/desk', builder: (context, state) => const DeskDashboardShell()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/history', builder: (context, state) => const ProgressHistoryScreen()),
    GoRoute(path: '/accounts', builder: (context, state) => const AccountsScreen()),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(path: '/contribute', builder: (context, state) => const ContributeScreen()),
    GoRoute(path: '/customize-ui', builder: (context, state) => const CustomizeUiScreen()),
    GoRoute(path: '/customize-navbar', builder: (context, state) => const CustomizeNavBarScreen()),
    GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
    GoRoute(path: '/agreement', builder: (context, state) => const AgreementScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/resources',
      builder: (context, state) => const ResourceExplorerScreen(),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) => const NavBarComingSoonScreen(
        title: 'Revision Planner',
        description: 'Spaced-repetition revision schedules and exam countdowns are coming in the next update!',
        icon: Icons.edit_calendar_rounded,
      ),
    ),
    GoRoute(
      path: '/socials',
      builder: (context, state) => const NavBarComingSoonScreen(
        title: 'Friends & Socials',
        description: 'Study groups, accountability partners, and friend leaderboards will be available in an upcoming release!',
        icon: Icons.group_rounded,
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NavBarComingSoonScreen(
        title: 'Notifications & Reminders',
        description: 'Custom study reminders and alerts will be configurable in an upcoming update!',
        icon: Icons.notifications_active_rounded,
      ),
    ),
  ],
);
