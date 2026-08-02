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

  void _pickColor(String label, Color currentColor, ValueChanged<Color> onColorChanged) {
    int r = (currentColor.r * 255).round().clamp(0, 255);
    int g = (currentColor.g * 255).round().clamp(0, 255);
    int b = (currentColor.b * 255).round().clamp(0, 255);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          final preview = Color.fromARGB(255, r, g, b);
          return AlertDialog(
            title: Text('Adjust $label', style: const TextStyle(fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: preview,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 24, child: Text('R', style: TextStyle(color: Colors.redAccent))),
                      Expanded(
                        child: Slider(
                          value: r.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.redAccent,
                          onChanged: (v) => setPickerState(() => r = v.round()),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 24, child: Text('G', style: TextStyle(color: Colors.greenAccent))),
                      Expanded(
                        child: Slider(
                          value: g.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.greenAccent,
                          onChanged: (v) => setPickerState(() => g = v.round()),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 24, child: Text('B', style: TextStyle(color: Colors.blueAccent))),
                      Expanded(
                        child: Slider(
                          value: b.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.blueAccent,
                          onChanged: (v) => setPickerState(() => b = v.round()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  onColorChanged(Color.fromARGB(255, r, g, b));
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
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
