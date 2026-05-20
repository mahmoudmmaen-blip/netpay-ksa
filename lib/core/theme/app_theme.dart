import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// Material 3 themes — Cairo، Emerald Premium، Light + Dark.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static TextTheme _cairoTextTheme(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? AppColors.darkOnSurface
        : AppColors.lightOnSurface;
    return GoogleFonts.cairoTextTheme().apply(
      bodyColor: color,
      displayColor: color,
    );
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.emerald,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? AppColors.emerald.withValues(alpha: 0.22)
          : AppColors.emerald.withValues(alpha: 0.14),
      onPrimaryContainer:
          isDark ? AppColors.emeraldLight : AppColors.emeraldDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.navy,
      secondaryContainer: AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.22),
      onSecondaryContainer: isDark ? AppColors.goldBright : AppColors.navy,
      tertiary: AppColors.emeraldLight,
      onTertiary: AppColors.navy,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSurface:
          isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface,
      surfaceContainerHighest: isDark
          ? AppColors.darkSurfaceElevated
          : const Color(0xFFECFDF5),
      error: AppColors.error,
      onError: Colors.white,
      outline: isDark
          ? AppColors.darkMuted.withValues(alpha: 0.4)
          : AppColors.lightMuted.withValues(alpha: 0.5),
    );

    final textTheme = _cairoTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      textTheme: textTheme,
      fontFamily: GoogleFonts.cairo().fontFamily,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: isDark ? AppColors.darkSurfaceElevated : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark
                ? AppColors.glassBorder
                : AppColors.emerald.withValues(alpha: 0.12),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.emerald,
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emerald;
          }
          return isDark ? AppColors.darkMuted : AppColors.lightMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.emerald.withValues(alpha: 0.35);
          }
          return isDark
              ? AppColors.navyLight.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.glassFillDark
            : Colors.white.withValues(alpha: 0.95),
        labelStyle: GoogleFonts.cairo(
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
        hintStyle: GoogleFonts.cairo(
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
        prefixIconColor: AppColors.emerald,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.glassBorder
                : AppColors.emerald.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.emeraldLight, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emerald,
          side: BorderSide(
            color: AppColors.emerald.withValues(alpha: isDark ? 0.7 : 1.0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        indicatorColor: AppColors.emerald.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.navyLight : const Color(0xFFE2E8F0),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isDark ? AppColors.navyLight : AppColors.emeraldDark,
        contentTextStyle: GoogleFonts.cairo(color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.emerald.withValues(alpha: isDark ? 0.15 : 0.1),
        labelStyle: GoogleFonts.cairo(
          color: isDark ? AppColors.emeraldLight : AppColors.emeraldDark,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.cairo(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurfaceElevated : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.emerald.withValues(alpha: isDark ? 0.25 : 0.15);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.emerald;
            }
            return colorScheme.onSurfaceVariant;
          }),
        ),
      ),
    );
  }
}
