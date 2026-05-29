import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شبكة اختيار الدولة في معالج EOSB — كل قيم [GulfCountry] (٦ دول خليجية).
class EosbCountryGrid extends StatelessWidget {
  const EosbCountryGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GulfCountry selected;
  final ValueChanged<GulfCountry> onSelected;

  @override
  Widget build(BuildContext context) {
    assert(
      GulfCountry.values.length == 6,
      'EOSB country grid expects exactly 6 GCC enum values',
    );

    final flagSize = MediaQuery.sizeOf(context).width < 360 ? 38.0 : 42.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: GulfCountry.values.length,
      itemBuilder: (context, index) {
        final country = GulfCountry.values[index];
        return _EosbCountryTile(
          key: ValueKey('eosb_country_${country.name}'),
          country: country,
          isSelected: country == selected,
          flagSize: flagSize,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(country);
          },
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                            .withValues(alpha: isDark ? 0.4 : 0.22),
                        AppColors.emeraldDark
                            .withValues(alpha: isDark ? 0.2 : 0.1),
                      ],
                    )
                  : null,
              color: isSelected
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: isDark ? 0.5 : 0.85),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.38),
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
                    const SizedBox(height: 3),
                    Text(
                      country.nameAr,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
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
                        fontSize: 9.5,
                        height: 1.1,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.emerald.withValues(alpha: 0.95)
                            : muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isSelected ? AppColors.emerald : muted)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (isSelected ? AppColors.emerald : muted)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        country.eosPensionSchemeLabel,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 8,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.emerald : muted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  const PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald,
                      size: 20,
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
