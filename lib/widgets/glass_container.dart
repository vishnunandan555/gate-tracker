import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../core/theme/theme_context_ext.dart';

/// Premium Frosted Glass Container that honors `AppThemeColors.enableGlassmorphism`.
///
/// When glassmorphism is enabled:
/// - Renders a blurred backdrop (`ImageFilter.blur`).
/// - Applies a translucent surface tint and subtle border gradient.
///
/// When glassmorphism is disabled (default):
/// - Falls back directly to a lightweight standard solid card surface.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? surfaceColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;
  final bool? forceGlassmorphism;
  final BoxShape shape;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.surfaceColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blurSigma = 12.0,
    this.forceGlassmorphism,
    this.shape = BoxShape.rectangle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isGlass = forceGlassmorphism ?? colors.enableGlassmorphism;
    final radius = borderRadius ?? colors.borderRadius;
    final effectiveBorderRadius = shape == BoxShape.circle ? null : BorderRadius.circular(radius);

    final effectiveSurface = surfaceColor ??
        (isGlass
            ? colors.surfaceColor.withValues(alpha: colors.isLight ? 0.65 : 0.45)
            : colors.cardBackground);

    final effectiveBorder = borderColor ??
        (isGlass
            ? (colors.isLight ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.12))
            : colors.borderColor);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveSurface,
        shape: shape,
        borderRadius: effectiveBorderRadius,
        border: Border.all(color: effectiveBorder, width: borderWidth),
      ),
      child: child,
    );

    if (isGlass) {
      content = ClipRRect(
        borderRadius: effectiveBorderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          borderRadius: effectiveBorderRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
