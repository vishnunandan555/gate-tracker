import 'dart:convert';
import 'package:flutter/material.dart';

class AppThemeDataModel {
  final String id;
  final String name;
  final String description;
  final bool isCustom;
  final bool isPreset;
  final int scaffoldBackground;
  final int cardBackground;
  final int surfaceColor;
  final int primaryAccent;
  final int secondaryAccent;
  final int textPrimary;
  final int textSecondary;
  final int textMuted;
  final int borderColor;
  final int? onSurface;
  final int? dividerColor;
  final int? onAccent;
  final double borderRadius;
  final bool enableGlassmorphism;

  const AppThemeDataModel({
    required this.id,
    required this.name,
    required this.description,
    this.isCustom = false,
    this.isPreset = false,
    required this.scaffoldBackground,
    required this.cardBackground,
    required this.surfaceColor,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderColor,
    this.onSurface,
    this.dividerColor,
    this.onAccent,
    this.borderRadius = 16.0,
    this.enableGlassmorphism = false,
  });

  Color get scaffoldBackgroundColor => Color(scaffoldBackground);
  Color get cardBackgroundColor => Color(cardBackground);
  Color get surfaceColorValue => Color(surfaceColor);
  Color get primaryAccentColor => Color(primaryAccent);
  Color get secondaryAccentColor => Color(secondaryAccent);
  Color get textPrimaryColor => Color(textPrimary);
  Color get textSecondaryColor => Color(textSecondary);
  Color get textMutedColor => Color(textMuted);
  Color get borderColorValue => Color(borderColor);
  Color? get onSurfaceColor => onSurface != null ? Color(onSurface!) : null;
  Color? get dividerColorValue => dividerColor != null ? Color(dividerColor!) : null;
  Color? get onAccentColor => onAccent != null ? Color(onAccent!) : null;

  bool get isLight => ThemeData.estimateBrightnessForColor(scaffoldBackgroundColor) == Brightness.light;

  AppThemeDataModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isCustom,
    bool? isPreset,
    int? scaffoldBackground,
    int? cardBackground,
    int? surfaceColor,
    int? primaryAccent,
    int? secondaryAccent,
    int? textPrimary,
    int? textSecondary,
    int? textMuted,
    int? borderColor,
    int? onSurface,
    int? dividerColor,
    int? onAccent,
    double? borderRadius,
    bool? enableGlassmorphism,
  }) {
    return AppThemeDataModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      isPreset: isPreset ?? this.isPreset,
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      primaryAccent: primaryAccent ?? this.primaryAccent,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      borderColor: borderColor ?? this.borderColor,
      onSurface: onSurface ?? this.onSurface,
      dividerColor: dividerColor ?? this.dividerColor,
      onAccent: onAccent ?? this.onAccent,
      borderRadius: borderRadius ?? this.borderRadius,
      enableGlassmorphism: enableGlassmorphism ?? this.enableGlassmorphism,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCustom': isCustom,
      'isPreset': isPreset,
      'scaffoldBackground': scaffoldBackground,
      'cardBackground': cardBackground,
      'surfaceColor': surfaceColor,
      'primaryAccent': primaryAccent,
      'secondaryAccent': secondaryAccent,
      'textPrimary': textPrimary,
      'textSecondary': textSecondary,
      'textMuted': textMuted,
      'borderColor': borderColor,
      'onSurface': onSurface,
      'dividerColor': dividerColor,
      'onAccent': onAccent,
      'borderRadius': borderRadius,
      'enableGlassmorphism': enableGlassmorphism,
    };
  }

  factory AppThemeDataModel.fromMap(Map<String, dynamic> map) {
    return AppThemeDataModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isCustom: map['isCustom'] ?? true,
      isPreset: map['isPreset'] ?? false,
      scaffoldBackground: map['scaffoldBackground'] ?? 0xFF09090B,
      cardBackground: map['cardBackground'] ?? 0xFF131316,
      surfaceColor: map['surfaceColor'] ?? 0xFF18181B,
      primaryAccent: map['primaryAccent'] ?? 0xFF00F0FF,
      secondaryAccent: map['secondaryAccent'] ?? 0xFF00B0FF,
      textPrimary: map['textPrimary'] ?? 0xFFFFFFFF,
      textSecondary: map['textSecondary'] ?? 0xFF8E8E93,
      textMuted: map['textMuted'] ?? 0xFF505055,
      borderColor: map['borderColor'] ?? 0x1AFFFFFF,
      onSurface: map['onSurface'],
      dividerColor: map['dividerColor'],
      onAccent: map['onAccent'],
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 16.0,
      enableGlassmorphism: map['enableGlassmorphism'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppThemeDataModel.fromJson(String source) =>
      AppThemeDataModel.fromMap(json.decode(source));
}
