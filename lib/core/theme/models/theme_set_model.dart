import 'package:flutter/material.dart';

/// Immutable ThemeSet specification defining visual tokens for all app UI surface layers.
class ThemeSetModel {
  final String id;
  final String name;
  final String description;
  final bool isDark;

  // Surface Tiers
  final int scaffoldBackground; // Base Canvas
  final int cardBackground;     // L1 Surface
  final int surfaceColor;       // L2 Input & Interactive Surface
  final int dialogBackground;   // L3 Floating Overlay & Sheet Surface

  // Typography Tokens
  final int textPrimary;
  final int textSecondary;
  final int textMuted;

  // Structural Dividers & Borders
  final int borderColor;
  final int dividerColor;
  final int? onSurface;

  // Design Modifiers
  final double borderRadius;
  final bool enableGlassmorphism;

  // Optional: ThemeSet can choose to force its own fixed accent color if desired
  final int? fixedAccentOverride;

  const ThemeSetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isDark,
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.surfaceColor,
    required this.dialogBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderColor,
    required this.dividerColor,
    this.onSurface,
    this.borderRadius = 16.0,
    this.enableGlassmorphism = false,
    this.fixedAccentOverride,
  });

  Color get scaffoldBackgroundColor => Color(scaffoldBackground);
  Color get cardBackgroundColor => Color(cardBackground);
  Color get surfaceColorValue => Color(surfaceColor);
  Color get dialogBackgroundColor => Color(dialogBackground);

  Color get textPrimaryColor => Color(textPrimary);
  Color get textSecondaryColor => Color(textSecondary);
  Color get textMutedColor => Color(textMuted);

  Color get borderColorValue => Color(borderColor);
  Color get dividerColorValue => Color(dividerColor);
  Color? get onSurfaceColor => onSurface != null ? Color(onSurface!) : null;
  Color? get fixedAccentColor => fixedAccentOverride != null ? Color(fixedAccentOverride!) : null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isDark': isDark,
      'scaffoldBackground': scaffoldBackground,
      'cardBackground': cardBackground,
      'surfaceColor': surfaceColor,
      'dialogBackground': dialogBackground,
      'textPrimary': textPrimary,
      'textSecondary': textSecondary,
      'textMuted': textMuted,
      'borderColor': borderColor,
      'dividerColor': dividerColor,
      'onSurface': onSurface,
      'borderRadius': borderRadius,
      'enableGlassmorphism': enableGlassmorphism,
      'fixedAccentOverride': fixedAccentOverride,
    };
  }

  factory ThemeSetModel.fromMap(Map<String, dynamic> map) {
    return ThemeSetModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isDark: map['isDark'] ?? true,
      scaffoldBackground: map['scaffoldBackground'] ?? 0xFF09090B,
      cardBackground: map['cardBackground'] ?? 0xFF131316,
      surfaceColor: map['surfaceColor'] ?? 0xFF18181B,
      dialogBackground: map['dialogBackground'] ?? 0xFF131316,
      textPrimary: map['textPrimary'] ?? 0xFFF1F5F9,
      textSecondary: map['textSecondary'] ?? 0xFF94A3B8,
      textMuted: map['textMuted'] ?? 0xFF64748B,
      borderColor: map['borderColor'] ?? 0x1AFFFFFF,
      dividerColor: map['dividerColor'] ?? 0x1AFFFFFF,
      onSurface: map['onSurface'],
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 16.0,
      enableGlassmorphism: map['enableGlassmorphism'] ?? false,
      fixedAccentOverride: map['fixedAccentOverride'],
    );
  }
}
