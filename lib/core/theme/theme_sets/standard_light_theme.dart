import '../models/theme_set_model.dart';

/// Base Fail-Safe Standard Light Theme Specification
const ThemeSetModel standardLightTheme = ThemeSetModel(
  id: 'paper_light',
  name: 'Standard Light',
  description: 'Default Light Mode.',
  isDark: false,

  // Surface Tiers
  scaffoldBackground: 0xFFF8FAFC, // Page Canvas
  cardBackground:     0xFFFFFFFF, // L1 Card Surface
  surfaceColor:       0xFFF1F5F9, // L2 Input & Interactive Surface
  dialogBackground:   0xFFFFFFFF, // L3 Floating Overlays

  // Typography Tokens
  textPrimary:        0xFF0F172A,
  textSecondary:      0xFF475569,
  textMuted:          0xFF64748B,

  // Structural Lines
  borderColor:        0x1F000000,
  dividerColor:       0x1A000000,
  onSurface:          0xFF0F172A,

  // Modifiers
  borderRadius:       16.0,
  enableGlassmorphism: false,
);
