import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/config/brand_config.dart';
import 'package:gateletics/providers/providers.dart';
import '../../utils/ui_scaling.dart';

// Modular settings widgets imports
import 'widgets/settings/danger_zone_settings.dart';
import 'widgets/settings/timer_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final accentColor = ref.watch(overallProgressColorProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 900;

    final titleStyle = GoogleFonts.outfit(
      color: Colors.white,
      fontSize: isDesktop ? 13.0 : context.s(13),
      fontWeight: isDesktop ? FontWeight.w500 : FontWeight.bold,
    );

    final subtitleStyle = GoogleFonts.outfit(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: isDesktop ? 11.5 : context.s(11),
    );

    Widget buildHeader(String title, {Color? color}) {
      return Padding(
        padding: isDesktop
            ? const EdgeInsets.fromLTRB(16, 12, 16, 6)
            : EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: (color ?? accentColor).withValues(alpha: 0.85),
            fontWeight: isDesktop ? FontWeight.w600 : FontWeight.bold,
            fontSize: isDesktop ? 11.5 : context.s(12),
            letterSpacing: isDesktop ? 0.8 : context.s(0.8),
          ),
        ),
      );
    }

    Widget buildSettingsGroup(Widget child) {
      return Container(
        margin: isDesktop
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isDesktop ? 14 : context.s(16)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isDesktop ? 14 : context.s(16)),
          child: Material(
            color: const Color(0xFF131316),
            child: child,
          ),
        ),
      );
    }

    final appSettingsHeader = buildHeader('TIMER & SYSTEM PREFERENCES');
    final appSettingsContent = buildSettingsGroup(
      TimerSettingsSection(
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        accentColor: accentColor,
      ),
    );

    final localBackupsHeader = buildHeader('DATA BACKUP & RESTORE');
    final localBackupsContent = buildSettingsGroup(
      DangerZoneSettingsSection(
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        accentColor: accentColor,
      ),
    );

    final showSystemOptions = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);

    final systemOptionsHeader = showSystemOptions ? buildHeader('ADVANCED') : const SizedBox.shrink();
    final systemOptionsContent = showSystemOptions
        ? buildSettingsGroup(
            _DesktopUpdateSettingsTile(
              titleStyle: titleStyle,
              subtitleStyle: subtitleStyle,
              accentColor: accentColor,
            ),
          )
        : const SizedBox.shrink();

    final versionText = Center(
      child: Text(
        '${BrandConfig.appName} v${packageInfo.version}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
        ),
      ),
    );

    return Scaffold(
        appBar: AppBar(
          title: Text(
            'SETTINGS',
            style: GoogleFonts.outfit(
              fontSize: isDesktop ? 16.0 : context.s(18),
              fontWeight: isDesktop ? FontWeight.w600 : FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: isDesktop
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                appSettingsHeader,
                                appSettingsContent,
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                 localBackupsHeader,
                                 localBackupsContent,
                                 if (showSystemOptions) ...[
                                   const SizedBox(height: 12),
                                   systemOptionsHeader,
                                   systemOptionsContent,
                                 ],
                               ],
                             ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      versionText,
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
                  children: [
                    appSettingsHeader,
                    appSettingsContent,
                    localBackupsHeader,
                    localBackupsContent,
                    if (showSystemOptions) ...[
                      systemOptionsHeader,
                      systemOptionsContent,
                    ],
                    SizedBox(height: context.s(12)),
                    versionText,
                    SizedBox(height: context.s(16)),
                  ],
                ),
        ),
      );
    }
}

class _DesktopUpdateSettingsTile extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const _DesktopUpdateSettingsTile({
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(desktopUpdateProvider);

    Widget trailingWidget;
    String subtitleText = 'Check GitHub Releases for app updates';

    if (updateState.status == DesktopUpdateStatus.checking) {
      trailingWidget = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
      );
      subtitleText = 'Checking GitHub API for updates...';
    } else if (updateState.status == DesktopUpdateStatus.updateAvailable && updateState.releaseInfo != null) {
      trailingWidget = TextButton(
        onPressed: () async {
          final Uri url = Uri.parse(updateState.releaseInfo!.htmlUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'UPDATE NOW',
          style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
      subtitleText = '🔥 ${BrandConfig.appName} v${updateState.releaseInfo!.latestVersion} is available!';
    } else if (updateState.status == DesktopUpdateStatus.upToDate) {
      trailingWidget = Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20);
      subtitleText = 'You are using the latest version';
    } else if (updateState.status == DesktopUpdateStatus.error) {
      trailingWidget = Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20);
      subtitleText = updateState.errorMessage ?? 'Could not check for updates';
    } else {
      trailingWidget = TextButton(
        onPressed: () {
          ref.read(desktopUpdateProvider.notifier).checkManually();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'CHECK NOW',
          style: GoogleFonts.outfit(color: accentColor, fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
    }

    return ListTile(
      leading: Icon(Icons.system_update_rounded, color: accentColor),
      title: Text('Check for Updates', style: titleStyle),
      subtitle: Text(subtitleText, style: subtitleStyle),
      trailing: trailingWidget,
      onTap: () {
        ref.read(desktopUpdateProvider.notifier).checkManually();
      },
    );
  }
}
