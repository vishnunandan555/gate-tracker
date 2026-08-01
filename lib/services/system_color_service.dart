import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemColorService {
  static const _channel = MethodChannel('com.vishnunandan.gateletics/system_color');

  static Future<Color?> getSystemAccentColor() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final int? colorInt = await _channel.invokeMethod<int>('getSystemAccentColor');
      if (colorInt != null) {
        return Color(colorInt);
      }
    } catch (e) {
      debugPrint('Failed to fetch native system accent color: $e');
    }
    return null;
  }
}
