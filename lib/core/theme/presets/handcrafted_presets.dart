import '../models/theme_set_model.dart';
import '../theme_sets/standard_dark_theme.dart';
import '../theme_sets/standard_light_theme.dart';

export '../theme_sets/standard_dark_theme.dart';
export '../theme_sets/standard_light_theme.dart';

/// Central ThemeRegistry containing the built-in Base Themes: Standard Dark and Standard Light.
class HandcraftedPresets {
  static const ThemeSetModel zincDark = standardDarkTheme;
  static const ThemeSetModel paperLight = standardLightTheme;

  static List<ThemeSetModel> get allPresets => [
        standardDarkTheme,
        standardLightTheme,
      ];
}
