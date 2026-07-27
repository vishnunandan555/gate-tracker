import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../utils/ui_scaling.dart';
import '../../../utils/page_transitions.dart';
import '../../dashboard/widgets/auth_screen.dart';
import '../../dashboard/widgets/settings/profile_settings.dart';
import '../../dashboard/widgets/settings/sync_settings.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(overallProgressColorProvider);
    final authAsync = ref.watch(authProvider);
    final user = authAsync.value?.user;
    final isSignedIn = user != null;

    final titleStyle = GoogleFonts.outfit(
      color: Colors.white,
      fontSize: context.s(14),
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = GoogleFonts.outfit(
      color: Colors.white54,
      fontSize: context.s(11.5),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Accounts & Cloud Sync',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(context.s(16)),
          children: [
            // User Profile Card
            Container(
              padding: EdgeInsets.all(context.s(16)),
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: context.s(24),
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    child: Text(
                      user?.email?.isNotEmpty == true
                          ? user!.email![0].toUpperCase()
                          : 'G',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: context.s(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? 'Guest Scholar',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: context.s(14.5),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSignedIn ? 'Signed In via Google' : 'Offline / Local Storage Mode',
                          style: GoogleFonts.outfit(
                            color: isSignedIn ? Colors.greenAccent.withValues(alpha: 0.8) : Colors.amberAccent.withValues(alpha: 0.8),
                            fontSize: context.s(11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.s(16)),

            // Action Button (Sign In / Sign Out)
            if (!isSignedIn) ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    AppPageRoute(page: const AuthScreen()),
                  );
                },
                icon: const Icon(Icons.login_rounded, color: Colors.black),
                label: Text(
                  'Sign In to Sync Progress',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => showSignOutConfirmationDialog(context, ref),
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: Text(
                  'Sign Out',
                  style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            SizedBox(height: context.s(20)),
            // Profile Settings Section
            Text(
              'PROFILE CUSTOMIZATION',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ProfileSettingsSection(
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
                accentColor: accentColor,
              ),
            ),

            SizedBox(height: context.s(20)),
            // Cloud Sync Section
            Text(
              'CLOUD SYNC PREFERENCES',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SyncSettingsSection(
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
                accentColor: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
