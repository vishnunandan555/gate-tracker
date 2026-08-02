import '../models/theme_set_model.dart';

/// Developer Custom Theme Bundle Template (Dual-Mode Specification)
///
/// Use this template file to group a Dark Mode ThemeSet and a Light Mode ThemeSet
/// together into a single modular Theme File.
///
/// How developers create a custom theme bundle:
/// 1. Define the Dark Mode specification (`darkSpec`).
/// 2. Define the Light Mode specification (`lightSpec`).
/// 3. Instantiate `CustomThemeBundle`.
class CustomThemeBundle {
  final String id;
  final String name;
  final String description;
  final ThemeSetModel darkTheme;
  final ThemeSetModel lightTheme;

  const CustomThemeBundle({
    required this.id,
    required this.name,
    required this.description,
    required this.darkTheme,
    required this.lightTheme,
  });
}

/// Template Example: Custom Theme Bundle
const CustomThemeBundle exampleCustomThemeBundle = CustomThemeBundle(
  id: 'custom_example_theme',
  name: 'Example Custom Theme',
  description: 'Developer template demonstrating paired dark and light theme specifications.',
  darkTheme: ThemeSetModel(
    id: 'custom_example_dark',
    name: 'Example Custom (Dark)',
    description: 'Dark mode variant of example custom theme.',
    isDark: true,
    scaffoldBackground: 0xFF0A0F1D, // Dark Canvas
    cardBackground:     0xFF111827, // L1 Card
    surfaceColor:       0xFF1F2937, // L2 Input / Chips
    dialogBackground:   0xFF111827, // L3 Floating Overlays
    textPrimary:        0xFFF9FAFB,
    textSecondary:      0xFF9CA3AF,
    textMuted:          0xFF6B7280,
    borderColor:        0x1AF9FAFB,
    dividerColor:       0x1AF9FAFB,
    borderRadius:       16.0,
    enableGlassmorphism: false,
  ),
  lightTheme: ThemeSetModel(
    id: 'custom_example_light',
    name: 'Example Custom (Light)',
    description: 'Light mode variant of example custom theme.',
    isDark: false,
    scaffoldBackground: 0xFFF3F4F6, // Light Canvas
    cardBackground:     0xFFFFFFFF, // L1 Card
    surfaceColor:       0xFFE5E7EB, // L2 Input / Chips
    dialogBackground:   0xFFFFFFFF, // L3 Floating Overlays
    textPrimary:        0xFF111827,
    textSecondary:      0xFF4B5563,
    textMuted:          0xFF6B7280,
    borderColor:        0x1F000000,
    dividerColor:       0x1A000000,
    borderRadius:       16.0,
    enableGlassmorphism: false,
  ),
);
