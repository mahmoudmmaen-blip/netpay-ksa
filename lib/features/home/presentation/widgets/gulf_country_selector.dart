import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';

/// بطاقتا اختيار الدولة — بارزتان في أعلى الشاشة.
/// الترتيب البصري (LTR): يسار السعودية | يمين الإمارات.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'اختر الدولة',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.emeraldLight.withValues(alpha: 0.9),
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
              const SizedBox(width: 14),
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
      ],
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
      upperBound: 1.05,
    );
    if (widget.isSelected) _pulse.value = 1.02;
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              )
            : null,
        child: GlassSurface(
          highlighted: isSelected,
          borderRadius: 24,
          onTap: widget.onTap,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(c.flag, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
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
              const SizedBox(height: 6),
              Text(
                c.schemeShort,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.goldBright
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 10),
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
