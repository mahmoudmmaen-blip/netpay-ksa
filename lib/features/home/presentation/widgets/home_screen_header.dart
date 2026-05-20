import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_typography.dart';

/// عنوان الشاشة — حاسبة الراتب الصافي + العملة.
class HomeScreenHeader extends StatelessWidget {
  const HomeScreenHeader({super.key, required this.country});

  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Column(
        key: ValueKey(country),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'حاسبة الراتب الصافي',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                country.currencyNameAr,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldLight,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  country.currencySymbol,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            country.schemeShort,
            textAlign: TextAlign.center,
            style: AppTypography.labelMuted(context),
          ),
        ],
      ),
    );
  }
}
