import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/desk/desk_dashboard_shell.dart';
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
  ],
);
