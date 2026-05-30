import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شريط دول أفقي مضغوط.
class LegalQaCountryStrip extends StatelessWidget {
  const LegalQaCountryStrip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GulfCountry selected;
  final ValueChanged<GulfCountry> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: GulfCountry.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final country = GulfCountry.values[index];
          final isSelected = country == selected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(country);
              },
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isSelected
                      ? AppColors.emerald.withValues(alpha: 0.2)
                      : Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.emerald
                        : AppColors.glassBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(country.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      country.nameAr,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
