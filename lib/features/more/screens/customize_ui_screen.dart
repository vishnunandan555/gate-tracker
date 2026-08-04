import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_context_ext.dart';
import '../../../utils/ui_scaling.dart';
import '../../dashboard/widgets/settings/advanced_beta_settings.dart';
import '../../dashboard/widgets/settings/customization_settings.dart';
import '../../dashboard/widgets/settings/layout_settings.dart';
import 'customize_nav_bar_screen.dart';

class CustomizeUiScreen extends ConsumerWidget {
  const CustomizeUiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = context.appColors.primaryAccent;

    final titleStyle = GoogleFonts.outfit(
      color: context.appColors.textPrimary,
      fontSize: context.s(13.5),
      fontWeight: FontWeight.w600,
    );
    final subtitleStyle = GoogleFonts.outfit(
      color: context.appColors.textSecondary,
      fontSize: context.s(11),
      height: 1.35,
    );

    Widget buildHeader(String text) {
      return Padding(
        padding: EdgeInsets.only(
          left: context.s(4),
          top: context.s(16),
          bottom: context.s(8),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: context.appColors.textSecondary,
            fontSize: context.s(10),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    Widget buildSettingsGroup(Widget child) {
      return Container(
        decoration: BoxDecoration(
          color: context.appColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: context.appColors.cardBackground,
            child: Theme(
              data: Theme.of(context).copyWith(
                listTileTheme: ListTileThemeData(
                  dense: false,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.s(16),
                    vertical: context.s(2),
                  ),
                  titleTextStyle: titleStyle,
                  subtitleTextStyle: subtitleStyle,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.appColors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Customize UI & Theme',
          style: GoogleFonts.outfit(
            color: context.appColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
          children: [
            // ── Navigation Bar Customization Section ───────────────────────
            buildHeader('NAVIGATION'),
            buildSettingsGroup(
              ListTile(
                leading: Icon(Icons.tune_rounded, color: accentColor),
                title: Text('Customize Navigation Bar', style: titleStyle),
                subtitle: Text(
                  'Reorder tabs and personalize navigation bar layout',
                  style: subtitleStyle,
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: context.appColors.textSecondary),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CustomizeNavBarScreen()),
                  );
                },
              ),
            ),

            // ── Theme Mode Section ───────────────────────────────────────────
            buildHeader('THEME MODE'),
            buildSettingsGroup(
              const ThemeModeSelectorWidget(),
            ),

            // ── App Styling Section ────────────────────────────────────────
            buildHeader('THEME ENGINE & STYLING'),
            buildSettingsGroup(
              CustomizationSettingsSection(
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
                accentColor: accentColor,
              ),
            ),

            // ── Advanced Customizations ───────────────────────────────────
            buildHeader('ADVANCED VISUALS'),
            buildSettingsGroup(
              AdvancedSettingsSection(
                titleStyle: titleStyle,
                subtitleStyle: subtitleStyle,
                accentColor: accentColor,
              ),
            ),

            // ── Platform Layout Switcher (Web/Desktop specific) ───────────
            if ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
                defaultTargetPlatform != TargetPlatform.android &&
                defaultTargetPlatform != TargetPlatform.iOS) ...[
              buildHeader('PLATFORM LAYOUT'),
              buildSettingsGroup(
                LayoutSettingsSection(
                  titleStyle: titleStyle,
                  subtitleStyle: subtitleStyle,
                ),
              ),
            ],

            SizedBox(height: context.s(24)),
          ],
        ),
      ),
    );
  }
}
