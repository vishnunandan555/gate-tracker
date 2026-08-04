import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:gateletics/providers/providers.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../database/backup_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isGoogleLoading = false;
  bool _isOfflineLoading = false;
  bool _isImportLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.appColors.dialogBackground,
            content: Text(
              'Sign in failed: $e',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleOfflineMode() async {
    setState(() => _isOfflineLoading = true);
    try {
      await ref.read(authProvider.notifier).chooseOfflineMode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set offline preference: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOfflineLoading = false);
    }
  }

  Future<void> _handleImportBackup() async {
    setState(() => _isImportLoading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = await result.files.first.readAsBytes();
        final jsonString = utf8.decode(bytes);
        final payload = jsonDecode(jsonString) as Map<String, dynamic>;
        final db = ref.read(appDatabaseProvider);
        await BackupService.restoreDatabase(db, payload);
        await ref.read(setupCompletedProvider.notifier).completeSetup();
        await ref.read(authProvider.notifier).chooseOfflineMode();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: context.appColors.dialogBackground,
              content: Text(
                'Backup restored successfully! Welcome back.',
                style: GoogleFonts.outfit(color: context.appColors.primaryAccent),
              ),
            ),
          );
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.appColors.dialogBackground,
            content: Text(
              'Failed to import backup: $e',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryAccent = context.appColors.primaryAccent;

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),
                        // App Branding Icon
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: context.appColors.borderColor,
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                colors: [primaryAccent, primaryAccent.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.cloud_sync_rounded,
                                  color: context.appColors.onAccent,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Title
                        Text(
                          "SYNC YOUR PROGRESS",
                          style: GoogleFonts.orbitron(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: context.appColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose how you want to manage your data",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: context.appColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Option 1: Sign in with Google (Cloud sync)
                        _buildAuthOptionCard(
                          title: "Cloud Synchronization",
                          description:
                              "Backup your progress securely in the cloud and sync automatically across all your devices.",
                          icon: Icons.backup_rounded,
                          accentColor: primaryAccent,
                          isLoading: _isGoogleLoading,
                          isDisabled: _isOfflineLoading,
                          buttonText: "SIGN IN WITH GOOGLE",
                          buttonIcon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            width: 18,
                            height: 18,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.login,
                              color: context.appColors.onAccent,
                              size: 18,
                            ),
                          ),
                          onTap: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 20),

                        // Option 2: Use locally
                        _buildAuthOptionCard(
                          title: "100% Local Storage",
                          description:
                              "Store everything locally on this device. No accounts, no internet required. You can always sign in later from settings.",
                          icon: Icons.phonelink_setup_rounded,
                          accentColor: context.appColors.textSecondary,
                          isLoading: _isOfflineLoading,
                          isDisabled: _isGoogleLoading || _isImportLoading,
                          buttonText: "USE LOCALLY",
                          buttonIcon: Icon(
                            Icons.cloud_off_rounded,
                            color: context.appColors.onAccent,
                            size: 18,
                          ),
                          onTap: _handleOfflineMode,
                        ),
                        const SizedBox(height: 20),

                        // Option 3: Import Backup (.json)
                        _buildAuthOptionCard(
                          title: "Restore Backup (.json)",
                          description:
                              "Already have a backup file? Import your JSON data to restore all your study progress instantly.",
                          icon: Icons.unarchive_rounded,
                          accentColor: Colors.amber.shade700,
                          isLoading: _isImportLoading,
                          isDisabled: _isGoogleLoading || _isOfflineLoading,
                          buttonText: "IMPORT BACKUP FILE",
                          buttonIcon: Icon(
                            Icons.file_upload_rounded,
                            color: context.appColors.onAccent,
                            size: 18,
                          ),
                          onTap: _handleImportBackup,
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isLoading,
    required bool isDisabled,
    required String buttonText,
    required Widget buttonIcon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.borderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.outfit(
              color: context.appColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (isLoading || isDisabled) ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: context.appColors.onAccent,
              disabledBackgroundColor: context.appColors.borderColor,
              disabledForegroundColor: context.appColors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: context.appColors.onAccent,
                      strokeWidth: 2,
                    ),
                  )
                : buttonIcon,
            label: Text(
              buttonText,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
