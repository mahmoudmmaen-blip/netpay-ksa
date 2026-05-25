import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';

/// بطاقتا اختيار الدولة — بارزتان في أعلى الشاشة مع شريحة العملة.
class GulfCountrySelector extends StatelessWidget {
  const GulfCountrySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final GulfCountry selected;
  final ValueChanged<GulfCountry> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emerald.withValues(alpha: isDark ? 0.22 : 0.12),
            AppColors.gold.withValues(alpha: isDark ? 0.14 : 0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: GlassSurface(
        borderRadius: 28,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose Country · اختر الدولة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: AppColors.emeraldLight,
              ),
            ),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CountryCard(
                      country: GulfCountry.saudiArabia,
                      isSelected: selected == GulfCountry.saudiArabia,
                      onTap: () => onSelected(GulfCountry.saudiArabia),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountryCard(
                      country: GulfCountry.uae,
                      isSelected: selected == GulfCountry.uae,
                      onTap: () => onSelected(GulfCountry.uae),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: _CurrencyChip(
                key: ValueKey(selected),
                country: selected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({super.key, required this.country});

  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              country.currencyLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.goldBright,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              country.currencySymbol,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.emeraldLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatefulWidget {
  const _CountryCard({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  final GulfCountry country;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 1,
      upperBound: 1.06,
    );
    if (widget.isSelected) _pulse.value = 1.03;
  }

  @override
  void didUpdateWidget(covariant _CountryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulse.forward(from: 1).then((_) => _pulse.reverse());
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final c = widget.country;

    return ScaleTransition(
      scale: _pulse,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              )
            : null,
        child: GlassSurface(
          highlighted: isSelected,
          borderRadius: 22,
          onTap: widget.onTap,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(c.flag, style: const TextStyle(fontSize: 46)),
              const SizedBox(height: 10),
              Text(
                c.nameAr,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppColors.emeraldLight
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                c.nameEn,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                c.schemeShort,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.goldBright
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.goldBright,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
