import 'package:flutter/material.dart';
import 'package:netgulf/core/domain/gulf_country.dart';

/// ألوان وثيم كل دولة خليجية.
class CountryTheme {
  const CountryTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
    required this.flag,
    required this.name,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> gradient;
  final String flag;
  final String name;
}

/// ترتيب الدول في الشريط الرئيسي.
const List<GulfCountry> homeCountryDisplayOrder = [
  GulfCountry.saudiArabia,
  GulfCountry.uae,
  GulfCountry.kuwait,
  GulfCountry.qatar,
  GulfCountry.bahrain,
  GulfCountry.oman,
];

const Map<String, CountryTheme> countryThemes = {
  'SA': CountryTheme(
    primary: Color(0xFF1B5E20),
    secondary: Color(0xFF4CAF50),
    accent: Color(0xFFFFD700),
    gradient: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
    flag: '🇸🇦',
    name: 'السعودية',
  ),
  'AE': CountryTheme(
    primary: Color(0xFF006400),
    secondary: Color(0xFFCC0000),
    accent: Color(0xFFFFFFFF),
    gradient: [Color(0xFF006400), Color(0xFF1B5E20)],
    flag: '🇦🇪',
    name: 'الإمارات',
  ),
  'KW': CountryTheme(
    primary: Color(0xFF1A237E),
    secondary: Color(0xFF009000),
    accent: Color(0xFFFF0000),
    gradient: [Color(0xFF1A237E), Color(0xFF283593)],
    flag: '🇰🇼',
    name: 'الكويت',
  ),
  'QA': CountryTheme(
    primary: Color(0xFF6D0021),
    secondary: Color(0xFF8B0000),
    accent: Color(0xFFFFFFFF),
    gradient: [Color(0xFF6D0021), Color(0xFF880E4F)],
    flag: '🇶🇦',
    name: 'قطر',
  ),
  'BH': CountryTheme(
    primary: Color(0xFFB71C1C),
    secondary: Color(0xFFFFFFFF),
    accent: Color(0xFFFFD700),
    gradient: [Color(0xFFB71C1C), Color(0xFFC62828)],
    flag: '🇧🇭',
    name: 'البحرين',
  ),
  'OM': CountryTheme(
    primary: Color(0xFF880000),
    secondary: Color(0xFF006400),
    accent: Color(0xFFFFFFFF),
    gradient: [Color(0xFF880000), Color(0xFFAD1457)],
    flag: '🇴🇲',
    name: 'عُمان',
  ),
};

extension GulfCountryThemeCode on GulfCountry {
  String get countryCode => switch (this) {
        GulfCountry.saudiArabia => 'SA',
        GulfCountry.uae => 'AE',
        GulfCountry.kuwait => 'KW',
        GulfCountry.qatar => 'QA',
        GulfCountry.bahrain => 'BH',
        GulfCountry.oman => 'OM',
      };
}

abstract final class CountryThemes {
  CountryThemes._();

  static const themeTransition = Duration(milliseconds: 400);
  static const themeCurve = Curves.easeInOut;

  static GulfCountry? fromCountryCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return switch (code.toUpperCase()) {
      'SA' => GulfCountry.saudiArabia,
      'AE' => GulfCountry.uae,
      'KW' => GulfCountry.kuwait,
      'QA' => GulfCountry.qatar,
      'BH' => GulfCountry.bahrain,
      'OM' => GulfCountry.oman,
      _ => null,
    };
  }

  static CountryTheme forCountry(GulfCountry country) {
    return countryThemes[country.countryCode] ?? countryThemes['SA']!;
  }

  static LinearGradient gradientFor(GulfCountry country) {
    final theme = forCountry(country);
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: theme.gradient,
    );
  }
}
