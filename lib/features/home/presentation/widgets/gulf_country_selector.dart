import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/core/theme/country_themes.dart';

/// شريط دول مضغوط — تمرير أفقي.
class CompactGulfCountryBar extends StatelessWidget {
  const CompactGulfCountryBar({
    super.key,
    required this.selected,
    required this.theme,
    required this.onSelected,
  });

  final GulfCountry selected;
  final CountryTheme theme;
  final ValueChanged<GulfCountry> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: homeCountryDisplayOrder.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final country = homeCountryDisplayOrder[index];
          final countryTheme = CountryThemes.forCountry(country);
          final isSelected = country == selected;
          return _CountryChip(
            country: country,
            countryTheme: countryTheme,
            isSelected: isSelected,
            activePrimary: theme.primary,
            onTap: () {
              if (isSelected) return;
              HapticFeedback.selectionClick();
              onSelected(country);
            },
          );
        },
      ),
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.countryTheme,
    required this.isSelected,
    required this.activePrimary,
    required this.onTap,
  });

  final GulfCountry country;
  final CountryTheme countryTheme;
  final bool isSelected;
  final Color activePrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnimatedContainer(
      duration: CountryThemes.themeTransition,
      curve: CountryThemes.themeCurve,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: CountryThemes.themeTransition,
            curve: CountryThemes.themeCurve,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? activePrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? activePrimary
                    : onSurface.withValues(alpha: 0.25),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(countryTheme.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  countryTheme.name,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? _chipLabelColor(activePrimary, countryTheme.accent)
                        : onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _chipLabelColor(Color primary, Color accent) {
    final luminance = primary.computeLuminance();
    if (luminance < 0.45) return Colors.white;
    if (accent.computeLuminance() > 0.85) return primary;
    return accent;
  }
}

/// زر العلم في AppBar — يفتح قائمة الدول.
class HomeCountryFlagButton extends ConsumerWidget {
  const HomeCountryFlagButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(countryThemeProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Tooltip(
        message: 'تغيير الدولة',
        child: Material(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => showGulfCountryPickerSheet(context, ref),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(theme.flag, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet — بطاقات الدول الست.
Future<void> showGulfCountryPickerSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(gulfCountryProvider);
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'اختر الدولة',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                ...homeCountryDisplayOrder.map((country) {
                  final theme = CountryThemes.forCountry(country);
                  final isSelected = country == current;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PickerCountryCard(
                      country: country,
                      theme: theme,
                      isSelected: isSelected,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await ref
                            .read(gulfCountryProvider.notifier)
                            .setCountry(country);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );
    },
  );

}

class _PickerCountryCard extends StatelessWidget {
  const _PickerCountryCard({
    required this.country,
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final GulfCountry country;
  final CountryTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: CountryThemes.themeTransition,
          curve: CountryThemes.themeCurve,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.primary : theme.primary.withValues(alpha: 0.2),
              width: isSelected ? 2.5 : 1,
            ),
            color: isSelected
                ? theme.primary.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              Text(theme.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      country.currencyLabel,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      country.schemeShort,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: theme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
