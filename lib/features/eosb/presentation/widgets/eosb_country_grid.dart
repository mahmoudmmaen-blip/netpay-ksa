import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شبكة اختيار الدولة في معالج EOSB — الدول الست في مجلس التعاون الخليجي.
class EosbCountryGrid extends StatelessWidget {
  const EosbCountryGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GulfCountry selected;
  final ValueChanged<GulfCountry> onSelected;

  /// ترتيب العرض الثابت (٦ دول).
  static const List<GulfCountry> countries = [
    GulfCountry.saudiArabia,
    GulfCountry.uae,
    GulfCountry.oman,
    GulfCountry.qatar,
    GulfCountry.bahrain,
    GulfCountry.kuwait,
  ];

  /// عمودان على الجوال، ٣ على الأجهزة المتوسطة، ٦ على الشاشات العريضة.
  static int crossAxisCount(double width) {
    if (width >= 1000) return 6;
    if (width >= 560) return 3;
    return 2;
  }

  static double tileHeight(double width, int columns) {
    if (columns >= 6) return 104;
    if (columns == 2) return 118;
    return 112;
  }

  static double flagSize(double width) {
    if (width < 360) return 36;
    if (width >= 1000) return 32;
    return 38;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = crossAxisCount(width);
        final tileH = tileHeight(width, columns);
        final flagSz = flagSize(width);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: tileH,
          ),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final country = countries[index];
            return _EosbCountryTile(
              country: country,
              isSelected: country == selected,
              flagSize: flagSz,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(country);
              },
            );
          },
        );
      },
    );
  }
}

class _EosbCountryTile extends StatelessWidget {
  const _EosbCountryTile({
    required this.country,
    required this.isSelected,
    required this.flagSize,
    required this.onTap,
  });

  final GulfCountry country;
  final bool isSelected;
  final double flagSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedScale(
          scale: isSelected ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.emerald
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.28),
                width: isSelected ? 2.5 : 1,
              ),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.emerald
                            .withValues(alpha: isDark ? 0.36 : 0.18),
                        AppColors.emeraldDark
                            .withValues(alpha: isDark ? 0.16 : 0.06),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: isDark ? 0.45 : 0.75),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.flag,
                        style: TextStyle(fontSize: flagSize),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          country.nameAr,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            height: 1.1,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? AppColors.emerald
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          country.nameEn,
                          maxLines: 1,
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: 0.35),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.emerald,
                        size: 20,
                      ),
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
