import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شبكة اختيار الدولة في معالج EOSB — يعرض الدول الست دائماً (بدون فلترة).
class EosbCountryGrid extends StatelessWidget {
  const EosbCountryGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GulfCountry selected;
  final ValueChanged<GulfCountry> onSelected;

  /// القائمة الثابتة — كل دول الخليج الست (لا تستخدم [GulfCountry.values]).
  static const List<GulfCountry> allCountries = [
    GulfCountry.saudiArabia,
    GulfCountry.uae,
    GulfCountry.oman,
    GulfCountry.qatar,
    GulfCountry.bahrain,
    GulfCountry.kuwait,
  ];

  /// @deprecated Use [allCountries]
  static const List<GulfCountry> countries = allCountries;

  static const double _spacing = 10;
  static const double _tileHeight = 152;

  static int _crossAxisCount(double width) {
    if (width >= 720) return 3;
    return 2;
  }

  static double _gridHeight(int itemCount, int columns) {
    final rows = (itemCount / columns).ceil();
    return rows * _tileHeight + (rows - 1) * _spacing;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = _crossAxisCount(width);
        final flagSize = width < 360 ? 40.0 : 44.0;

        return SizedBox(
          height: _gridHeight(allCountries.length, columns),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: _spacing,
              crossAxisSpacing: _spacing,
              mainAxisExtent: _tileHeight,
            ),
            itemCount: allCountries.length,
            itemBuilder: (context, index) {
              final country = allCountries[index];
              return _EosbCountryTile(
                key: ValueKey(country),
                country: country,
                isSelected: country == selected,
                flagSize: flagSize,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(country);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _EosbCountryTile extends StatelessWidget {
  const _EosbCountryTile({
    super.key,
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      label:
          '${country.flag} ${country.nameAr} ${country.nameEn} · ${country.eosPensionSchemeLabel}',
      selected: isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
                            .withValues(alpha: isDark ? 0.38 : 0.2),
                        AppColors.emeraldDark
                            .withValues(alpha: isDark ? 0.18 : 0.08),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: isDark ? 0.5 : 0.8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      country.flag,
                      style: TextStyle(fontSize: flagSize),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      country.nameAr,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? AppColors.emerald
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      country.nameEn,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.emerald.withValues(alpha: 0.9)
                            : muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isSelected ? AppColors.emerald : muted)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (isSelected ? AppColors.emerald : muted)
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        country.eosPensionSchemeLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 8.5,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.emerald : muted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  const PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald,
                      size: 22,
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
