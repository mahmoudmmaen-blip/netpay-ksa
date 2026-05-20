import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_typography.dart';
import 'package:netgulf/core/widgets/animated_currency_text.dart';
import 'package:netgulf/core/widgets/app_logo.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';

/// بطاقة الراتب الصافي — البطاقة الرئيسية (Hero).
class HomeNetSalaryCard extends StatelessWidget {
  const HomeNetSalaryCard({
    super.key,
    required this.country,
    required this.net,
    required this.gross,
    required this.deduction,
    required this.isDark,
    required this.formatValue,
  });

  final GulfCountry country;
  final double net;
  final double gross;
  final double deduction;
  final bool isDark;
  final String Function(double) formatValue;

  String get _deductionColumnLabel => 'خصم ${country.schemeShort}';

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppColors.premiumCardGlow(isDark: isDark),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: AppColors.premiumCardBorder,
          ),
          padding: const EdgeInsets.all(1.4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: AppColors.premiumCardGradient,
                    ),
                  ),
                ),
                // شعار خفيف في الخلفية
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 0.07,
                      child: AppLogo(size: 160, showShadow: false),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _FlagBadge(country: country),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'الراتب الصافي',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedCurrencyText(
                        key: ValueKey('${country.nameEn}-$net'),
                        value: net,
                        formatter: formatValue,
                        duration: const Duration(milliseconds: 750),
                        style: AppTypography.displayNumber(size: 56),
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatColumn(
                                      label: _deductionColumnLabel,
                                      value: deduction,
                                      formatValue: formatValue,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color:
                                        Colors.white.withValues(alpha: 0.22),
                                  ),
                                  Expanded(
                                    child: _StatColumn(
                                      label: 'الإجمالي',
                                      value: gross,
                                      formatValue: formatValue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.country});
  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 20,
      blur: 8,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Text(
            country.nameAr,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.formatValue,
  });

  final String label;
  final double value;
  final String Function(double) formatValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCurrencyText(
          value: value,
          formatter: formatValue,
          goldGradient: false,
          duration: const Duration(milliseconds: 750),
          style: AppTypography.statNumber(
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
