import 'package:flutter/material.dart';
import 'app_theme_colors.dart';
import 'presets/handcrafted_presets.dart';

extension ThemeContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  
  AppThemeColors get appColors {
    final ext = Theme.of(this).extension<AppThemeColors>();
    if (ext != null) return ext;
    // Fallback default zinc dark colors if extension is somehow missing
    return AppThemeColors.fromModel(HandcraftedPresets.zincDark);
  }
}
