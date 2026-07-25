import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../providers/glow_strength_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/disable_countdown_provider.dart';
import '../../../../providers/disable_home_screen_widget_provider.dart';
import '../../../../providers/disable_graph_glow_provider.dart';
import '../../../../providers/show_projected_completion_provider.dart';
import '../../../../providers/swap_chart_lines_provider.dart';
import '../../../../providers/enable_share_progress_card_provider.dart';

class AdvancedSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const AdvancedSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeGlowStrength = ref.watch(homeGlowStrengthProvider);
    final focusGlowStrength = ref.watch(focusGlowStrengthProvider);
    final profilePhotoSize = ref.watch(profileProvider).profilePhotoSize;
    final disableCountdown = ref.watch(disableCountdownProvider);
    final disableWidgets = ref.watch(disableHomeScreenWidgetProvider);
    final disableChartGlow = ref.watch(disableGraphGlowProvider);
    final swapChartLines = ref.watch(swapChartLinesProvider);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.tune_rounded, color: accentColor, size: 20),
        iconColor: accentColor,
        collapsedIconColor: Colors.white30,
        title: Text(
          'Advanced Options',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Visual customization, glow intensity, avatar sizing, and dashboard UI layout toggles',
          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
        ),
        children: [
          const Divider(color: Colors.white10, height: 1),
          // Home Screen Glow Intensity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Home Screen Glow Intensity', style: titleStyle),
                      Text('Controls the pulsing radial background glow on the home dashboard', style: subtitleStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(homeGlowStrength * 50).round()}%',
                  style: GoogleFonts.outfit(color: accentColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accentColor,
                thumbColor: accentColor,
                inactiveTrackColor: Colors.white12,
                overlayColor: accentColor.withValues(alpha: 0.15),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: homeGlowStrength.clamp(0.0, 4.0),
                min: 0.0,
                max: 4.0,
                divisions: 8,
                onChanged: (val) {
                  ref.read(homeGlowStrengthProvider.notifier).setStrength(val);
                },
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Focusing Screen Glow Intensity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.blur_on_rounded, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Focusing Screen Glow Intensity', style: titleStyle),
                      Text('Controls the active background glow animation during focus sessions', style: subtitleStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(focusGlowStrength * 50).round()}%',
                  style: GoogleFonts.outfit(color: accentColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accentColor,
                thumbColor: accentColor,
                inactiveTrackColor: Colors.white12,
                overlayColor: accentColor.withValues(alpha: 0.15),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: focusGlowStrength.clamp(0.0, 4.0),
                min: 0.0,
                max: 4.0,
                divisions: 8,
                onChanged: (val) {
                  ref.read(focusGlowStrengthProvider.notifier).setStrength(val);
                },
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Avatar Circle Size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.account_circle_outlined, color: accentColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avatar Circle Size', style: titleStyle),
                      Text('Adjust profile photo size on home screen', style: subtitleStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${profilePhotoSize.round()}px',
                  style: GoogleFonts.outfit(color: accentColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: accentColor,
                thumbColor: accentColor,
                inactiveTrackColor: Colors.white12,
                overlayColor: accentColor.withValues(alpha: 0.15),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: profilePhotoSize.clamp(24.0, 80.0),
                min: 24.0,
                max: 80.0,
                divisions: 7,
                onChanged: (val) {
                  ref.read(profileProvider.notifier).setProfilePhotoSize(val);
                },
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Disable Countdown
          SwitchListTile(
            secondary: Icon(Icons.timer_off_outlined, color: disableCountdown ? Colors.white30 : accentColor, size: 20),
            title: Text('Disable Countdown Timer', style: titleStyle),
            subtitle: Text('Hide the main days countdown on the home screen', style: subtitleStyle),
            value: disableCountdown,
            activeThumbColor: accentColor,
            onChanged: (val) {
              ref.read(disableCountdownProvider.notifier).setEnabled(val);
            },
          ),

          const Divider(color: Colors.white10, height: 1),

          // Disable Home Screen Widgets
          SwitchListTile(
            secondary: Icon(Icons.widgets_outlined, color: disableWidgets ? Colors.white30 : accentColor, size: 20),
            title: Text('Disable Home Screen Widgets', style: titleStyle),
            subtitle: Text('Hide the swipeable stats carousel on home screen', style: subtitleStyle),
            value: disableWidgets,
            activeThumbColor: accentColor,
            onChanged: (val) {
              ref.read(disableHomeScreenWidgetProvider.notifier).setEnabled(val);
            },
          ),

          const Divider(color: Colors.white10, height: 1),

          // Disable Chart Glow
          SwitchListTile(
            secondary: Icon(Icons.show_chart_rounded, color: disableChartGlow ? Colors.white30 : accentColor, size: 20),
            title: Text('Disable Chart Glow', style: titleStyle),
            subtitle: Text('Remove neon glow effect from Stats chart lines', style: subtitleStyle),
            value: disableChartGlow,
            activeThumbColor: accentColor,
            onChanged: (val) {
              ref.read(disableGraphGlowProvider.notifier).setEnabled(val);
            },
          ),

          const Divider(color: Colors.white10, height: 1),

          // Swap Chart Lines
          SwitchListTile(
            secondary: Icon(Icons.swap_calls_rounded, color: swapChartLines ? accentColor : Colors.white30, size: 20),
            title: Text('Prioritize Progress in Chart', style: titleStyle),
            subtitle: Text('Show daily syllabus completion progress as the solid primary line and study hours as dashed line', style: subtitleStyle),
            value: swapChartLines,
            activeThumbColor: accentColor,
            onChanged: (val) {
              ref.read(swapChartLinesProvider.notifier).setEnabled(val);
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class BetaSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const BetaSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showProjected = ref.watch(showProjectedCompletionProvider);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.science_outlined, color: Colors.amber, size: 20),
        iconColor: Colors.amber,
        collapsedIconColor: Colors.amber.withValues(alpha: 0.4),
        title: Text(
          'Beta',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Experimental features, may change',
          style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
        ),
        children: [
          const Divider(color: Colors.white10, height: 1),
          // Beta info banner
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These features are experimental and may change or be removed in future releases.',
                    style: GoogleFonts.outfit(color: Colors.amber.withValues(alpha: 0.8), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Projected Completion toggle
          SwitchListTile(
            secondary: Icon(Icons.trending_up_rounded, color: showProjected ? accentColor : Colors.white30, size: 20),
            title: Text('Projected Completion', style: titleStyle),
            subtitle: Text('Show estimated syllabus completion date in Stats (experimental accuracy)', style: subtitleStyle),
            value: showProjected,
            activeThumbColor: accentColor,
            onChanged: (val) {
              ref.read(showProjectedCompletionProvider.notifier).setEnabled(val);
            },
          ),

          const Divider(color: Colors.white10, height: 1),

          // Enable Share Progress Card toggle
          SwitchListTile(
            secondary: Icon(Icons.share_rounded, color: ref.watch(enableShareProgressCardProvider) ? accentColor : Colors.white30, size: 20),
            title: Text('Share Progress Card', style: titleStyle),
            subtitle: Text('Enable daily progress sharing widget on home screen', style: subtitleStyle),
            value: ref.watch(enableShareProgressCardProvider),
            activeThumbColor: accentColor,
            onChanged: (val) {
              ref.read(enableShareProgressCardProvider.notifier).setEnabled(val);
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
