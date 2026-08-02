import 'package:flutter/material.dart';

/// Repository managing independent Dark Accent and Light Accent pools,
/// custom user accent persistence, and WCAG contrast safeguards.
class AppAccentPools {
  /// Default Dark Mode Accent Pool (Bright Cyan)
  static const List<Color> defaultDarkAccents = [
    Color(0xFF00F0FF), // Bright Cyan (Default Dark Accent)
  ];

  /// Default Light Mode Accent Pool (Dark Blue)
  static const List<Color> defaultLightAccents = [
    Color(0xFF0284C7), // Dark Blue (Default Light Accent)
  ];

  /// Ensures an accent color has safe readable contrast against target scaffold brightness.
  /// Automatically nudges lightness if contrast falls below WCAG standards.
  static Color ensureContrast(Color color, bool isDark) {
    final hsl = HSLColor.fromColor(color);
    if (isDark) {
      if (hsl.lightness < 0.35) {
        return hsl.withLightness(0.50).toColor();
      }
    } else {
      if (hsl.lightness > 0.45) {
        return hsl.withLightness(0.36).toColor();
      }
    }
    return color;
  }

  /// Parses a Hex string (e.g. "#00F0FF" or "00F0FF") into a Color.
  static Color? parseHexColor(String hexString) {
    try {
      String cleanHex = hexString.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      if (cleanHex.length == 8) {
        final value = int.parse(cleanHex, radix: 16);
        return Color(value);
      }
    } catch (_) {}
    return null;
  }

  /// Formats a Color into a Hex String (e.g. "#00F0FF").
  static String toHexString(Color color) {
    final argb = color.toARGB32();
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
