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
import 'route_resolver.dart';

final appRouter = GoRouter(
  initialLocation: resolveInitialRoute(),
  redirect: (context, state) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      if (state.uri.path.startsWith('/desk')) {
        return '/';
      }
    }
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF09090B),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.cyanAccent, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Page Not Found',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No route found for ${state.uri.path}',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
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
  ),
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
      builder: (context, state) => const NavBarComingSoonScreen(
        title: 'Resource Explorer',
        description: 'Community-curated formulas, PYQ solutions, and recommended lecture notes will be released soon!',
        icon: Icons.library_books_rounded,
      ),
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
