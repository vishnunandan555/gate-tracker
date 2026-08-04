import '../models/theme_set_model.dart';

/// Base Fail-Safe Standard Dark Theme Specification
/// Preserves exact perfected surface layer values:
/// Scaffold Canvas: 0xFF09090B
/// L1 Card Surface: 0xFF131316
/// L2 Input & Interactive Surface: 0xFF18181B
/// L3 Floating Dialog Surface: 0xFF131316
const ThemeSetModel standardDarkTheme = ThemeSetModel(
  id: 'zinc_dark',
  name: 'Standard Dark',
  description: 'Default Dark Mode.',
  isDark: true,

  // Surface Tiers
  scaffoldBackground: 0xFF09090B, // Page Canvas
  cardBackground:     0xFF131316, // L1 Card Surface
  surfaceColor:       0xFF18181B, // L2 Input & Interactive Surface
  dialogBackground:   0xFF131316, // L3 Floating Overlays

  // Typography Tokens
  textPrimary:        0xFFF1F5F9,
  textSecondary:      0xFF94A3B8,
  textMuted:          0xFF64748B,

  // Structural Lines
  borderColor:        0x1AFFFFFF,
  dividerColor:       0x1AFFFFFF,
  onSurface:          0xFFF1F5F9,

  // Modifiers
  borderRadius:       16.0,
  enableGlassmorphism: false,
);
