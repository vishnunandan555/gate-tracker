import '../models/app_theme_model.dart';

class HandcraftedPresets {
  static const AppThemeDataModel zincDark = AppThemeDataModel(
    id: 'zinc_dark',
    name: 'Zinc Dark (Default)',
    description: 'Classic deep zinc dark theme for GATEletics.',
    isPreset: true,
    scaffoldBackground: 0xFF09090B,
    cardBackground: 0xFF131316,
    surfaceColor: 0xFF18181B,
    primaryAccent: 0xFF00F0FF,
    secondaryAccent: 0xFF00B0FF,
    textPrimary: 0xFFFFFFFF,
    textSecondary: 0xFF8E8E93,
    textMuted: 0xFF505055,
    borderColor: 0x1AFFFFFF,
    borderRadius: 16.0,
    enableGlassmorphism: false,
  );

  static const AppThemeDataModel paperLight = AppThemeDataModel(
    id: 'paper_light',
    name: 'Paper Light',
    description: 'Clean, warm paper white surface with crisp dark typography.',
    isPreset: true,
    scaffoldBackground: 0xFFF8F9FA,
    cardBackground: 0xFFFFFFFF,
    surfaceColor: 0xFFF1F3F5,
    primaryAccent: 0xFF0284C7,
    secondaryAccent: 0xFF0EA5E9,
    textPrimary: 0xFF111827,
    textSecondary: 0xFF4B5563,
    textMuted: 0xFF9CA3AF,
    borderColor: 0x1F000000,
    borderRadius: 16.0,
    enableGlassmorphism: false,
  );

  static const AppThemeDataModel cyberpunkNeon = AppThemeDataModel(
    id: 'preset_cyberpunk',
    name: 'Cyberpunk Neon',
    description: 'Pitch night dark with electric cyan and magenta glowing accents.',
    isPreset: true,
    scaffoldBackground: 0xFF050508,
    cardBackground: 0xFF0D0D14,
    surfaceColor: 0xFF141420,
    primaryAccent: 0xFF00F0FF,
    secondaryAccent: 0xFFE040FB,
    textPrimary: 0xFFFFFFFF,
    textSecondary: 0xFFA0A0C0,
    textMuted: 0xFF505070,
    borderColor: 0x4000F0FF,
    borderRadius: 16.0,
    enableGlassmorphism: true,
  );

  static const AppThemeDataModel oledBlack = AppThemeDataModel(
    id: 'preset_oled',
    name: 'OLED Pitch Black',
    description: 'Pure pitch black background optimized for AMOLED energy saving.',
    isPreset: true,
    scaffoldBackground: 0xFF000000,
    cardBackground: 0xFF080808,
    surfaceColor: 0xFF101010,
    primaryAccent: 0xFF39FF14,
    secondaryAccent: 0xFF00F0FF,
    textPrimary: 0xFFFFFFFF,
    textSecondary: 0xFF999999,
    textMuted: 0xFF555555,
    borderColor: 0x26FFFFFF,
    borderRadius: 16.0,
    enableGlassmorphism: false,
  );

  static const AppThemeDataModel nordicSlate = AppThemeDataModel(
    id: 'preset_nordic',
    name: 'Nordic Slate',
    description: 'Cool slate navy background with ice blue and mint highlights.',
    isPreset: true,
    scaffoldBackground: 0xFF0F172A,
    cardBackground: 0xFF1E293B,
    surfaceColor: 0xFF334155,
    primaryAccent: 0xFF38BDF8,
    secondaryAccent: 0xFF34D399,
    textPrimary: 0xFFF8FAFC,
    textSecondary: 0xFF94A3B8,
    textMuted: 0xFF64748B,
    borderColor: 0x1AF8FAFC,
    borderRadius: 16.0,
    enableGlassmorphism: true,
  );

  static const AppThemeDataModel sunsetAmber = AppThemeDataModel(
    id: 'preset_sunset',
    name: 'Sunset Amber',
    description: 'Deep warm charcoal with terracotta rose and golden amber accents.',
    isPreset: true,
    scaffoldBackground: 0xFF181216,
    cardBackground: 0xFF241A21,
    surfaceColor: 0xFF30232C,
    primaryAccent: 0xFFF43F5E,
    secondaryAccent: 0xFFF59E0B,
    textPrimary: 0xFFFFF1F2,
    textSecondary: 0xFFFDA4AF,
    textMuted: 0xFF9F1239,
    borderColor: 0x26F43F5E,
    borderRadius: 16.0,
    enableGlassmorphism: false,
  );

  static List<AppThemeDataModel> get allPresets => [
        zincDark,
        paperLight,
        cyberpunkNeon,
        oledBlack,
        nordicSlate,
        sunsetAmber,
      ];
}
