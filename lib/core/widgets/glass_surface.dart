import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// سطح زجاجي (glassmorphism) — فاتح/داكن.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.highlighted = false,
    this.blur = 12,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool highlighted;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? Colors.white.withValues(alpha: highlighted ? 0.14 : 0.08)
        : Colors.white.withValues(alpha: highlighted ? 0.92 : 0.75);
    final borderColor = highlighted
        ? AppColors.emerald.withValues(alpha: isDark ? 0.65 : 0.45)
        : (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.9));

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: fill,
            border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1),
            boxShadow: [
              if (highlighted)
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.navy)
                    .withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: isDark ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: content);
    }
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }
    return content;
  }
}
