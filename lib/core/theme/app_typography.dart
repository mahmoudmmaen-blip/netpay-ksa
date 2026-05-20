import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// تسلسل هرمي للخط — Cairo مع تمييز الأرقام.
abstract final class AppTypography {
  AppTypography._();

  static TextStyle displayNumber({
    double size = 44,
    Color? color,
  }) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle statNumber({
    double size = 14,
    Color? color,
  }) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle sectionTitle({Color? color, bool isDark = true}) =>
      GoogleFonts.cairo(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: color ?? (isDark ? AppColors.emeraldLight : AppColors.emeraldDark),
      );

  static TextStyle labelMuted(BuildContext context) => GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  static TextStyle chipLabel({Color color = Colors.white}) => GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
      );
}
