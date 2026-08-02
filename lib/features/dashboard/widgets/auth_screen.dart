import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:gateletics/providers/providers.dart';
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
            backgroundColor: const Color(0xFF1F080A),
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
              backgroundColor: const Color(0xFF0D3320),
              content: Text(
                'Backup restored successfully! Welcome back.',
                style: GoogleFonts.outfit(color: const Color(0xFF34D399)),
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
            backgroundColor: const Color(0xFF1F080A),
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
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
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
                              border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
                              gradient: const LinearGradient(
                                colors: [Colors.cyanAccent, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.cloud_sync_rounded,
                                  color: Colors.black,
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
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose how you want to manage your data",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Option 1: Sign in with Google (Cloud sync)
                        _buildAuthOptionCard(
                          title: "Cloud Synchronization",
                          description: "Backup your progress securely in the cloud and sync automatically across all your devices.",
                          icon: Icons.backup_rounded,
                          accentColor: Colors.cyanAccent,
                          isLoading: _isGoogleLoading,
                          isDisabled: _isOfflineLoading,
                          buttonText: "SIGN IN WITH GOOGLE",
                          buttonIcon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            width: 18,
                            height: 18,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.login,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                          onTap: _handleGoogleSignIn,
                        ),
                        const SizedBox(height: 20),

                        // Option 2: Use locally
                        _buildAuthOptionCard(
                          title: "100% Local Storage",
                          description: "Store everything locally on this device. No accounts, no internet required. You can always sign in later from settings.",
                          icon: Icons.phonelink_setup_rounded,
                          accentColor: Colors.white70,
                          isLoading: _isOfflineLoading,
                          isDisabled: _isGoogleLoading || _isImportLoading,
                          buttonText: "USE LOCALLY",
                          buttonIcon: const Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                          onTap: _handleOfflineMode,
                        ),
                        const SizedBox(height: 20),

                        // Option 3: Import Backup (.json)
                        _buildAuthOptionCard(
                          title: "Restore Backup (.json)",
                          description: "Already have a backup file? Import your JSON data to restore all your study progress instantly.",
                          icon: Icons.unarchive_rounded,
                          accentColor: Colors.amberAccent,
                          isLoading: _isImportLoading,
                          isDisabled: _isGoogleLoading || _isOfflineLoading,
                          buttonText: "IMPORT BACKUP FILE",
                          buttonIcon: const Icon(
                            Icons.file_upload_rounded,
                            color: Colors.black,
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
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(12), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
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
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (isLoading || isDisabled) ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white30,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.black,
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
