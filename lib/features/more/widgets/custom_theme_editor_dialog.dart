import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/models/app_theme_model.dart';
import '../../../core/theme/theme_context_ext.dart';
import '../../../providers/providers.dart';

class CustomThemeEditorDialog extends ConsumerStatefulWidget {
  final AppThemeDataModel? initialThemeToEdit;

  const CustomThemeEditorDialog({
    super.key,
    this.initialThemeToEdit,
  });

  @override
  ConsumerState<CustomThemeEditorDialog> createState() => _CustomThemeEditorDialogState();
}

class _CustomThemeEditorDialogState extends ConsumerState<CustomThemeEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  late Color _scaffoldBg;
  late Color _cardBg;
  late Color _surfaceColor;
  late Color _primaryAccent;
  late Color _secondaryAccent;
  late Color _textPrimary;
  late Color _textSecondary;
  late Color _borderColor;
  late double _borderRadius;
  late bool _enableGlassmorphism;

  @override
  void initState() {
    super.initState();

    final activeModel = ref.read(themeEngineProvider.notifier).getActiveThemeModel(
          ref.read(overallProgressColorProvider),
        );

    final model = widget.initialThemeToEdit ?? activeModel;

    _nameController = TextEditingController(
      text: widget.initialThemeToEdit != null ? model.name : 'My Custom Theme',
    );
    _descController = TextEditingController(
      text: widget.initialThemeToEdit != null ? model.description : 'Personalized theme setup',
    );

    _scaffoldBg = model.scaffoldBackgroundColor;
    _cardBg = model.cardBackgroundColor;
    _surfaceColor = model.surfaceColorValue;
    _primaryAccent = model.primaryAccentColor;
    _secondaryAccent = model.secondaryAccentColor;
    _textPrimary = model.textPrimaryColor;
    _textSecondary = model.textSecondaryColor;
    _borderColor = model.borderColorValue;
    _borderRadius = model.borderRadius;
    _enableGlassmorphism = model.enableGlassmorphism;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _pickColor(String label, Color currentColor, ValueChanged<Color> onColorChanged) async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => _ModernColorPickerDialog(
        label: label,
        initialColor: currentColor,
      ),
    );
    if (selectedColor != null) {
      onColorChanged(selectedColor);
    }
  }

  Widget _buildColorTile(String label, Color color, ValueChanged<Color> onChanged) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
      trailing: InkWell(
        onTap: () => _pickColor(label, color, onChanged),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: context.appColors.textSecondary.withValues(alpha: 0.3), width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: context.appColors.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: context.appColors.borderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.initialThemeToEdit != null ? 'Edit Custom Theme' : 'Create Custom Theme',
                    style: GoogleFonts.outfit(
                      color: context.appColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Live Preview Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _scaffoldBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Live Preview', style: GoogleFonts.outfit(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(_borderRadius),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(backgroundColor: _primaryAccent, radius: 14),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Sample Card Title', style: GoogleFonts.outfit(color: _textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text('Secondary details line', style: GoogleFonts.outfit(color: _textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _secondaryAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Badge', style: TextStyle(color: _secondaryAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: context.appColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Theme Name',
                      labelStyle: TextStyle(color: context.appColors.textSecondary, fontSize: 13),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.appColors.borderColor), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.appColors.primaryAccent), borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    style: TextStyle(color: context.appColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: context.appColors.textSecondary, fontSize: 13),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: context.appColors.borderColor), borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.appColors.primaryAccent), borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('Color Palette', style: GoogleFonts.outfit(color: context.appColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  _buildColorTile('Scaffold Background', _scaffoldBg, (c) => setState(() => _scaffoldBg = c)),
                  _buildColorTile('Card Background', _cardBg, (c) => setState(() => _cardBg = c)),
                  _buildColorTile('Surface Color', _surfaceColor, (c) => setState(() => _surfaceColor = c)),
                  _buildColorTile('Primary Accent', _primaryAccent, (c) => setState(() => _primaryAccent = c)),
                  _buildColorTile('Secondary Accent', _secondaryAccent, (c) => setState(() => _secondaryAccent = c)),
                  _buildColorTile('Text Primary', _textPrimary, (c) => setState(() => _textPrimary = c)),
                  _buildColorTile('Text Secondary', _textSecondary, (c) => setState(() => _textSecondary = c)),
                  _buildColorTile('Border Color', _borderColor, (c) => setState(() => _borderColor = c)),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Card Radius (${_borderRadius.toInt()}px)',
                          style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _borderRadius,
                          min: 8,
                          max: 28,
                          activeColor: _primaryAccent,
                          onChanged: (v) => setState(() => _borderRadius = v),
                        ),
                      ),
                    ],
                  ),

                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('Glassmorphism Effect', style: GoogleFonts.outfit(color: context.appColors.textPrimary, fontSize: 13)),
                    value: _enableGlassmorphism,
                    activeThumbColor: _primaryAccent,
                    onChanged: (v) => setState(() => _enableGlassmorphism = v),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: context.appColors.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final name = _nameController.text.trim().isEmpty ? 'Custom Theme' : _nameController.text.trim();
                          final desc = _descController.text.trim().isEmpty ? 'Personalized theme' : _descController.text.trim();

                          final themeModel = AppThemeDataModel(
                            id: widget.initialThemeToEdit?.id ?? '',
                            name: name,
                            description: desc,
                            isCustom: true,
                            isPreset: false,
                            scaffoldBackground: _scaffoldBg.toARGB32(),
                            cardBackground: _cardBg.toARGB32(),
                            surfaceColor: _surfaceColor.toARGB32(),
                            primaryAccent: _primaryAccent.toARGB32(),
                            secondaryAccent: _secondaryAccent.toARGB32(),
                            textPrimary: _textPrimary.toARGB32(),
                            textSecondary: _textSecondary.toARGB32(),
                            textMuted: _textSecondary.withValues(alpha: 0.5).toARGB32(),
                            borderColor: _borderColor.toARGB32(),
                            borderRadius: _borderRadius,
                            enableGlassmorphism: _enableGlassmorphism,
                          );

                          final notifier = ref.read(themeEngineProvider.notifier);
                          bool success;
                          if (widget.initialThemeToEdit != null) {
                            success = notifier.updateCustomTheme(themeModel);
                          } else {
                            success = notifier.createCustomTheme(themeModel);
                          }

                          if (success) {
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to save custom theme.')),
                            );
                          }
                        },
                        child: Text(
                          widget.initialThemeToEdit != null ? 'Save Changes' : 'Create Theme',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernColorPickerDialog extends StatefulWidget {
  final String label;
  final Color initialColor;

  const _ModernColorPickerDialog({
    required this.label,
    required this.initialColor,
  });

  @override
  State<_ModernColorPickerDialog> createState() => _ModernColorPickerDialogState();
}

class _ModernColorPickerDialogState extends State<_ModernColorPickerDialog> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;
  bool _updatingText = false;

  static const List<Color> _quickSwatches = [
    Color(0xFF00F0FF), // Neon Cyan
    Color(0xFF15CBD6), // Cyan Light
    Color(0xFF39FF14), // Neon Green
    Color(0xFF2EBD14), // Green Light
    Color(0xFFFF0000), // Scarlet Red
    Color(0xFFFFAD00), // Amber
    Color(0xFFE040FB), // Magenta
    Color(0xFF9D5AFF), // Purple
    Color(0xFF4C73FF), // Electric Blue
    Color(0xFF00B0FF), // Blue
    Color(0xFF27D1AF), // Teal Light
    Color(0xFF99D152), // Lime Light
    Color(0xFF09090B), // Dark Scaffold
    Color(0xFF18181B), // Dark Surface
    Color(0xFFF3F4F6), // Light Scaffold
    Color(0xFFFFFFFF), // White
  ];

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _formatHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _formatHex(Color color) {
    final argb = color.toARGB32();
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _onHexChanged(String input) {
    if (_updatingText) return;
    var clean = input.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final val = int.tryParse('FF$clean', radix: 16);
      if (val != null) {
        final newColor = Color(val);
        setState(() {
          _hsvColor = HSVColor.fromColor(newColor);
        });
      }
    }
  }

  void _updateColor(HSVColor newHsv) {
    setState(() {
      _hsvColor = newHsv;
      _updatingText = true;
      _hexController.text = _formatHex(newHsv.toColor());
      _updatingText = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();

    return AlertDialog(
      backgroundColor: context.appColors.dialogBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: context.appColors.borderColor),
      ),
      title: Text(
        'Adjust ${widget.label}',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: context.appColors.textPrimary,
          fontSize: 18,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview & Hex Input Row
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: currentColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.appColors.borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      onChanged: _onHexChanged,
                      style: GoogleFonts.firaCode(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Hex Color Code',
                        labelStyle: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: context.appColors.surfaceColor,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.appColors.primaryAccent),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Rainbow Hue Slider
              Text(
                'Color Hue',
                style: GoogleFonts.outfit(
                  color: context.appColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF0000),
                      Color(0xFFFFFF00),
                      Color(0xFF00FF00),
                      Color(0xFF00FFFF),
                      Color(0xFF0000FF),
                      Color(0xFFFF00FF),
                      Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: SliderTheme(
                  data: SliderThemeData(
                    trackShape: const RectangularSliderTrackShape(),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackHeight: 20,
                  ),
                  child: Slider(
                    value: _hsvColor.hue,
                    min: 0.0,
                    max: 360.0,
                    onChanged: (newHue) {
                      _updateColor(_hsvColor.withHue(newHue));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Saturation / Brightness Sliders
              Text(
                'Saturation & Brightness',
                style: GoogleFonts.outfit(
                  color: context.appColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('Sat', style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11)),
                  ),
                  Expanded(
                    child: Slider(
                      value: _hsvColor.saturation,
                      min: 0.0,
                      max: 1.0,
                      activeColor: currentColor,
                      onChanged: (s) => _updateColor(_hsvColor.withSaturation(s)),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text('Val', style: GoogleFonts.outfit(color: context.appColors.textMuted, fontSize: 11)),
                  ),
                  Expanded(
                    child: Slider(
                      value: _hsvColor.value,
                      min: 0.0,
                      max: 1.0,
                      activeColor: currentColor,
                      onChanged: (v) => _updateColor(_hsvColor.withValue(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Swatches
              Text(
                'Quick Palette Presets',
                style: GoogleFonts.outfit(
                  color: context.appColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSwatches.map((color) {
                  final isSelected = currentColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => _updateColor(HSVColor.fromColor(color)),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? context.appColors.textPrimary : context.appColors.borderColor,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.outfit(color: context.appColors.textMuted)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, currentColor),
          style: FilledButton.styleFrom(
            backgroundColor: context.appColors.primaryAccent,
            foregroundColor: context.appColors.onAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Apply', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
