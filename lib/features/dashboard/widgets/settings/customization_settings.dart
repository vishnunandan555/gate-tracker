import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/models/accent_pool_model.dart';
import '../../../../core/theme/theme_context_ext.dart';
import '../../../more/widgets/theme_gallery_sheet.dart';
import 'package:gateletics/providers/providers.dart';

class CustomizationSettingsSection extends ConsumerWidget {
  final TextStyle titleStyle;
  final TextStyle subtitleStyle;
  final Color accentColor;

  const CustomizationSettingsSection({
    super.key,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.accentColor,
  });

  void _showAccentColorDialog(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final colorNotifier = ref.read(overallProgressColorProvider.notifier);
    final currentColor = ref.read(overallProgressColorProvider);
    final isThemeDark = !context.appColors.isLight;

    int r = (currentColor.r * 255).round().clamp(0, 255);
    int g = (currentColor.g * 255).round().clamp(0, 255);
    int b = (currentColor.b * 255).round().clamp(0, 255);

    final hexController = TextEditingController(text: AppAccentPools.toHexString(currentColor));
    bool isViewingDarkPool = isThemeDark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (size.width * 0.85).clamp(280.0, 360.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131316),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
              ),
              padding: const EdgeInsets.all(24.0),
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  final isAuto = colorNotifier.mode == 'auto';
                  final isDevice = colorNotifier.mode == 'device';
                  final previewColor = Color.fromARGB(255, r, g, b);
                  final activePool = isViewingDarkPool ? colorNotifier.darkPool : colorNotifier.lightPool;

                  void syncFromRgb() {
                    hexController.text = AppAccentPools.toHexString(previewColor);
                  }

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Accent Color',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // ── Auto & Device Accent Buttons ─────────────────
                        InkWell(
                          onTap: () {
                            colorNotifier.setAutoMode();
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isAuto
                                  ? currentColor.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAuto ? currentColor : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.brightness_auto_rounded,
                                  color: isAuto ? currentColor : Colors.white70,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Auto-rotate accent on launch',
                                    style: GoogleFonts.outfit(
                                      color: isAuto ? Colors.white : Colors.white70,
                                      fontSize: 14,
                                      fontWeight: isAuto ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isAuto)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: currentColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final systemAccent = ref.watch(systemAccentColorProvider);
                            if (systemAccent == null) return const SizedBox.shrink();

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    colorNotifier.setDeviceMode(systemAccent);
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: isDevice
                                          ? currentColor.withValues(alpha: 0.2)
                                          : Colors.white10,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDevice ? currentColor : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.phonelink_setup_rounded,
                                          color: isDevice ? currentColor : Colors.white70,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            'Use Material You Device Accent',
                                            style: GoogleFonts.outfit(
                                              color: isDevice ? Colors.white : Colors.white70,
                                              fontSize: 14,
                                              fontWeight: isDevice ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (isDevice)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: currentColor,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Mode Accent Pool Switcher ───────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isViewingDarkPool ? 'DARK ACCENTS:' : 'LIGHT ACCENTS:',
                              style: GoogleFonts.outfit(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(value: true, label: Text('Dark', style: TextStyle(fontSize: 11))),
                                ButtonSegment(value: false, label: Text('Light', style: TextStyle(fontSize: 11))),
                              ],
                              selected: {isViewingDarkPool},
                              onSelectionChanged: (val) {
                                setDialogState(() {
                                  isViewingDarkPool = val.first;
                                });
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Accent Color Grid ────────────────────────────
                        Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: activePool.map((color) {
                              final isSelected = !isAuto && !isDevice &&
                                  colorNotifier.frozenColor?.toARGB32() == color.toARGB32();

                              return InkWell(
                                onTap: () {
                                  colorNotifier.setFrozenColor(color);
                                  Navigator.pop(context);
                                },
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.white24,
                                      width: isSelected ? 2.5 : 1.2,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.black,
                                          size: 18,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Custom Hex & RGB Picker ─────────────────────
                        Text(
                          'CUSTOM ACCENT PICKER:',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: previewColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: previewColor.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: hexController,
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Hex Code',
                                  labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                                  prefixText: '# ',
                                  prefixStyle: GoogleFonts.orbitron(color: Colors.white70, fontSize: 13),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                onChanged: (val) {
                                  final parsed = AppAccentPools.parseHexColor(val);
                                  if (parsed != null) {
                                    setDialogState(() {
                                      r = (parsed.r * 255).round();
                                      g = (parsed.g * 255).round();
                                      b = (parsed.b * 255).round();
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(width: 20, child: Text('R', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(
                              child: Slider(
                                value: r.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.redAccent,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  setDialogState(() {
                                    r = val.round();
                                    syncFromRgb();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 20, child: Text('G', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(
                              child: Slider(
                                value: g.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.greenAccent,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  setDialogState(() {
                                    g = val.round();
                                    syncFromRgb();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(width: 20, child: Text('B', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                            Expanded(
                              child: Slider(
                                value: b.toDouble(),
                                min: 0,
                                max: 255,
                                activeColor: Colors.blueAccent,
                                inactiveColor: Colors.white10,
                                onChanged: (val) {
                                  setDialogState(() {
                                    b = val.round();
                                    syncFromRgb();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            final chosenColor = Color.fromARGB(255, r, g, b);
                            colorNotifier.addCustomAccent(chosenColor, isDark: isViewingDarkPool);
                            Navigator.pop(context);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: previewColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Save & Apply Custom Accent', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesEnabled = ref.watch(focusQuotesEnabledProvider);
    final animType = ref.watch(focusAnimationProvider);
    final fillStyle = ref.watch(resumeFillStyleProvider);
    final colorNotifier = ref.watch(overallProgressColorProvider.notifier);
    final currentColor = ref.watch(overallProgressColorProvider);
    final isAuto = colorNotifier.mode == 'auto';
    final isDevice = colorNotifier.mode == 'device';

    final currentFont = ref.watch(progressFontProvider);
    final currentIconBoxStyle = ref.watch(iconBoxStyleProvider);
    final currentScale = ref.watch(overallUiScaleProvider);
    final currentCategorySize = ref.watch(categoryFontSizeProvider);
    final currentTopicSize = ref.watch(topicFontSizeProvider);
    final currentTaskSize = ref.watch(taskFontSizeProvider);

    final accentColorContent = ListTile(
      leading: Icon(
        isAuto
            ? Icons.brightness_auto_rounded
            : (isDevice ? Icons.phonelink_setup_rounded : Icons.color_lens_rounded),
        color: currentColor,
      ),
      title: Text('Theme Accent Color', style: titleStyle),
      subtitle: Text(
        isAuto
            ? 'Dynamic color auto-cycling'
            : (isDevice ? 'System device accent color' : 'Frozen custom color'),
        style: subtitleStyle,
      ),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: currentColor.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      onTap: () => _showAccentColorDialog(context, ref),
    );

    final fontSizeDirectContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.aspect_ratio_rounded, color: currentColor),
          title: Text('Global UI Scale', style: titleStyle),
          subtitle: Text('Resize margins, cards, and overall display elements', style: subtitleStyle),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<OverallUiScale>(
              value: currentScale,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              items: OverallUiScale.values.map((scale) {
                String name = '';
                switch (scale) {
                  case OverallUiScale.xs: name = 'XS (0.8x)'; break;
                  case OverallUiScale.s: name = 'S (0.9x)'; break;
                  case OverallUiScale.normal: name = 'Normal (1.0x)'; break;
                  case OverallUiScale.l: name = 'L (1.1x)'; break;
                  case OverallUiScale.xl: name = 'XL (1.2x)'; break;
                }
                return DropdownMenuItem(
                  value: scale,
                  child: Text(name, style: TextStyle(color: context.appColors.textPrimary, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(overallUiScaleProvider.notifier).setScale(val);
                }
              },
            ),
          ),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.text_fields_rounded, color: currentColor),
          title: Text('Category Header Font Size', style: titleStyle),
          subtitle: Text('Adjust font size of syllabus category headers', style: subtitleStyle),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<CategoryFontSize>(
              value: currentCategorySize,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              items: CategoryFontSize.values.map((size) {
                String name = '';
                switch (size) {
                  case CategoryFontSize.level1: name = 'XS'; break;
                  case CategoryFontSize.level2: name = 'S'; break;
                  case CategoryFontSize.level3: name = 'Normal'; break;
                  case CategoryFontSize.level4: name = 'L'; break;
                  case CategoryFontSize.level5: name = 'XL'; break;
                }
                return DropdownMenuItem(
                  value: size,
                  child: Text(name, style: TextStyle(color: context.appColors.textPrimary, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(categoryFontSizeProvider.notifier).setFontSize(val);
                }
              },
            ),
          ),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.topic_rounded, color: currentColor),
          title: Text('Subject Card Font Size', style: titleStyle),
          subtitle: Text('Adjust font size of subject card titles', style: subtitleStyle),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<TopicFontSize>(
              value: currentTopicSize,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              items: TopicFontSize.values.map((size) {
                String name = '';
                switch (size) {
                  case TopicFontSize.level1: name = 'XS'; break;
                  case TopicFontSize.level2: name = 'S'; break;
                  case TopicFontSize.level3: name = 'Normal'; break;
                  case TopicFontSize.level4: name = 'L'; break;
                  case TopicFontSize.level5: name = 'XL'; break;
                }
                return DropdownMenuItem(
                  value: size,
                  child: Text(name, style: TextStyle(color: context.appColors.textPrimary, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(topicFontSizeProvider.notifier).setFontSize(val);
                }
              },
            ),
          ),
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.checklist_rounded, color: currentColor),
          title: Text('Checklist Task Font Size', style: titleStyle),
          subtitle: Text('Adjust font size of checklist task checkboxes', style: subtitleStyle),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<TaskFontSize>(
              value: currentTaskSize,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              items: TaskFontSize.values.map((size) {
                String name = '';
                switch (size) {
                  case TaskFontSize.level1: name = 'XS'; break;
                  case TaskFontSize.level2: name = 'S'; break;
                  case TaskFontSize.level3: name = 'Normal'; break;
                  case TaskFontSize.level4: name = 'L'; break;
                  case TaskFontSize.level5: name = 'XL'; break;
                }
                return DropdownMenuItem(
                  value: size,
                  child: Text(name, style: TextStyle(color: context.appColors.textPrimary, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(taskFontSizeProvider.notifier).setFontSize(val);
                }
              },
            ),
          ),
        ),
      ],
    );

    final themePresetTile = ListTile(
      leading: Icon(Icons.palette_rounded, color: currentColor),
      title: Text('Theme Mode & Presets', style: titleStyle),
      subtitle: Text(
        'Light, Dark, Custom Presets & Theme Creator',
        style: subtitleStyle,
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: context.appColors.textSecondary),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          builder: (_) => Consumer(
            builder: (context, ref, child) {
              final activeThemeData = ref.watch(activeAppThemeProvider);

              return Theme(
                data: activeThemeData,
                child: Builder(
                  builder: (context) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: context.appColors.surfaceColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        border: Border.all(color: context.appColors.borderColor),
                      ),
                      child: DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.8,
                        maxChildSize: 0.95,
                        minChildSize: 0.5,
                        builder: (context, scrollController) => Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: const ThemeGallerySheet(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        themePresetTile,
        Divider(color: context.appColors.dividerColor, height: 1),
        SwitchListTile(
          activeThumbColor: currentColor,
          secondary: Icon(Icons.format_quote_rounded, color: currentColor),
          title: Text('Motivational Quotes', style: titleStyle),
          subtitle: Text(
            'Show inspirational study quotes during focus timer',
            style: subtitleStyle,
          ),
          value: quotesEnabled,
          onChanged: (val) {
            ref.read(focusQuotesEnabledProvider.notifier).setEnabled(val);
          },
        ),
        Divider(color: context.appColors.dividerColor, height: 1),
        ListTile(
          leading: Icon(Icons.animation_rounded, color: currentColor),
          title: Text('Focus Loop Animation', style: titleStyle),
          subtitle: Text(
            'Looping graphic shown during active focus countdowns',
            style: subtitleStyle,
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<FocusAnimationType>(
              value: animType,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              items: FocusAnimationType.values.map((type) {
                String name = '';
                switch (type) {
                  case FocusAnimationType.doubleWave:
                    name = 'Double Wave';
                    break;
                  case FocusAnimationType.singleWave:
                    name = 'Single Wave';
                    break;
                  case FocusAnimationType.pulseDots:
                    name = 'Pulsing Dots';
                    break;
                  case FocusAnimationType.sonicEqualizer:
                    name = 'Sonic Equalizer';
                    break;
                  case FocusAnimationType.heartbeatECG:
                    name = 'Heartbeat ECG';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(focusAnimationProvider.notifier).setFocusAnimationType(val);
                }
              },
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: Icon(Icons.smart_button_rounded, color: currentColor),
          title: Text('Resume Button Style', style: titleStyle),
          subtitle: Text(
            'Preparation progress filling style on home dashboard',
            style: subtitleStyle,
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<ResumeFillStyle>(
              value: fillStyle,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              items: ResumeFillStyle.values.map((type) {
                String name = '';
                switch (type) {
                  case ResumeFillStyle.rectangularFill:
                    name = 'Rectangular Fill';
                    break;
                  case ResumeFillStyle.neonGradient:
                    name = 'Neon Gradient';
                    break;
                  case ResumeFillStyle.bottomMicroIndicator:
                    name = 'Bottom Micro Line';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(resumeFillStyleProvider.notifier).setResumeFillStyle(val);
                }
              },
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: Icon(Icons.font_download_rounded, color: currentColor),
          title: Text('Checklist Typography', style: titleStyle),
          subtitle: Text(
            'Font style for progress headers and statistics',
            style: subtitleStyle,
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<ProgressFont>(
              value: currentFont,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              icon: Icon(Icons.arrow_drop_down, color: currentColor),
              style: TextStyle(color: currentColor),
              items: ProgressFont.values.map((font) {
                String label;
                switch (font) {
                  case ProgressFont.orbitron:
                    label = 'Orbitron';
                    break;
                  case ProgressFont.jersey15:
                    label = 'Jersey 15';
                    break;
                  case ProgressFont.jersey10:
                    label = 'Jersey 10';
                    break;
                  case ProgressFont.tektur:
                    label = 'Tektur';
                    break;
                  case ProgressFont.odibeeSans:
                    label = 'Odibee';
                    break;
                  case ProgressFont.pressStart2P:
                    label = 'Press Start';
                    break;
                  case ProgressFont.boldonse:
                    label = 'Boldonse';
                    break;
                }
                return DropdownMenuItem(
                  value: font,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(progressFontProvider.notifier).setProgressFont(val);
                }
              },
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: Icon(Icons.grid_view_rounded, color: currentColor),
          title: Text('More Menu Card Style', style: titleStyle),
          subtitle: Text(
            'Icon & box layout style for More Options screen',
            style: subtitleStyle,
          ),
          trailing: DropdownButtonHideUnderline(
            child: DropdownButton<IconBoxStyle>(
              value: currentIconBoxStyle,
              dropdownColor: context.appColors.surfaceColor,
              alignment: Alignment.centerRight,
              icon: Icon(Icons.arrow_drop_down, color: currentColor),
              style: TextStyle(color: currentColor),
              items: IconBoxStyle.values.map((style) {
                String label;
                switch (style) {
                  case IconBoxStyle.filled:
                    label = 'Integrated Box';
                    break;
                  case IconBoxStyle.separated:
                    label = 'Separated Icon';
                    break;
                  case IconBoxStyle.outlined:
                    label = 'Outlined Glass';
                    break;
                  case IconBoxStyle.minimal:
                    label = 'Minimal Icon';
                    break;
                }
                return DropdownMenuItem(
                  value: style,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(iconBoxStyleProvider.notifier).setStyle(val);
                }
              },
            ),
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        accentColorContent,
        const Divider(color: Colors.white10, height: 1),
        fontSizeDirectContent,
      ],
    );
  }
}
