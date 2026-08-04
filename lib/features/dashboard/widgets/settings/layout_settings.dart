import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../../core/theme/theme_context_ext.dart';

class LayoutSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;

  const LayoutSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        GoRouterState.of(context).uri.path.startsWith('/desk')
            ? Icons.phone_android_rounded
            : Icons.desktop_windows_rounded,
        color: context.appColors.primaryAccent,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            GoRouterState.of(context).uri.path.startsWith('/desk')
                ? 'Switch to Mobile UI'
                : 'Switch to Desktop UI',
            style: titleStyle,
          ),
          if (!GoRouterState.of(context).uri.path.startsWith('/desk')) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.appColors.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: context.appColors.primaryAccent.withValues(alpha: 0.4), width: 1),
              ),
              child: Text(
                'BETA',
                style: GoogleFonts.outfit(
                  color: context.appColors.primaryAccent,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        GoRouterState.of(context).uri.path.startsWith('/desk')
            ? 'Return to the mobile-optimized layout'
            : 'Experience the desktop layout on your device',
        style: subtitleStyle,
      ),
      onTap: () async {
        final prefs = ref.read(sharedPreferencesProvider);
        if (context.mounted) {
          if (GoRouterState.of(context).uri.path.startsWith('/desk')) {
            await prefs.setBool('user_wants_desktop_ui', false);
            if (context.mounted) context.go('/');
          } else {
            await prefs.setBool('user_wants_desktop_ui', true);
            if (context.mounted) context.go('/desk');
          }
        }
      },
    );
  }
}
