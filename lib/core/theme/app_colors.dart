import 'package:flutter/material.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// ألوان NetGulf — زمردي + كحلي + ذهبي + تدرجات جاهزة.
class AppColors {
  AppColors._();

  // ── زمردي ──────────────────────────────────────────────────────────────────

  static const Color emerald = Color(AppPalette.emerald);
  static const Color emeraldDark = Color(AppPalette.emeraldDark);
  static const Color emeraldLight = Color(AppPalette.emeraldLight);
  static const Color emeraldMuted = Color(AppPalette.emeraldMuted);

  // ── كحلي ───────────────────────────────────────────────────────────────────

  static const Color navy = Color(AppPalette.navy);
  static const Color navyMid = Color(AppPalette.navyMid);
  static const Color navyLight = Color(AppPalette.navyLight);
  static const Color navyDeepGreen = Color(AppPalette.navyDeepGreen);

  // ── ذهبي ───────────────────────────────────────────────────────────────────

  static const Color gold = Color(AppPalette.gold);
  static const Color goldBright = Color(AppPalette.goldBright);

  static const Color primary = emerald;
  static const Color primaryDark = emeraldDark;
  static const Color accent = gold;

  // ── أوضاع العرض ──────────────────────────────────────────────────────────

  static const Color lightBackground = Color(AppPalette.lightBackground);
  static const Color lightSurface = Color(AppPalette.lightSurface);
  static const Color lightOnSurface = Color(AppPalette.lightOnSurface);
  static const Color lightMuted = Color(AppPalette.lightMuted);

  static const Color darkBackground = navy;
  static const Color darkSurface = navyMid;
  static const Color darkOnSurface = Color(0xFFE2E8F0);
  static const Color darkMuted = Color(0xFF94A3B8);

  static const Color success = Color(AppPalette.success);
  static const Color error = Color(AppPalette.error);
  static const Color warning = Color(AppPalette.warning);
  static const Color info = Color(AppPalette.info);

  // ── تدرجات ─────────────────────────────────────────────────────────────────

  /// العلامة — بطاقة الراتب والأزرار البارزة.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [emerald, emeraldDark, navyMid],
    stops: [0.0, 0.55, 1.0],
  );

  /// ذهبي — أرقام الراتب والعناوين المميزة.
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldBright, gold],
  );

  /// Splash — وضع فاتح.
  static const LinearGradient splashLightGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [lightBackground, emeraldMuted, lightBackground],
    stops: [0.0, 0.5, 1.0],
  );

  /// Splash — وضع داكن.
  static const LinearGradient splashDarkGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [navy, navyDeepGreen, navy],
    stops: [0.0, 0.45, 1.0],
  );

  /// خلفية الشاشة الرئيسية — فاتح.
  static const LinearGradient homeLightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBackground, Color(0xFFECFDF5)],
  );

  /// خلفية الشاشة الرئيسية — داكن.
  static const LinearGradient homeDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navy, navyMid],
  );

  /// تدرج خفيف لانتقال الصفحات (overlay).
  static LinearGradient routeFadeOverlay({required bool isDark}) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        (isDark ? navy : lightBackground).withValues(alpha: 0),
        (isDark ? navy : lightBackground).withValues(alpha: 0.04),
      ],
    );
  }

  /// ظل البطاقات.
  static List<BoxShadow> cardShadow({bool isDark = false}) => [
        BoxShadow(
          color: (isDark ? Colors.black : navy).withValues(alpha: 0.08),
          blurRadius: isDark ? 8 : 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// خلفية Splash حسب السطوع.
  static LinearGradient splashGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? splashDarkGradient
          : splashLightGradient;

  /// خلفية Home حسب السطوع.
  static LinearGradient homeGradient(Brightness brightness) =>
      brightness == Brightness.dark ? homeDarkGradient : homeLightGradient;
}
