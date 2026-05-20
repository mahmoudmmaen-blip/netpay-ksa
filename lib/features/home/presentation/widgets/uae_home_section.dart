import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_typography.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/home/providers/home_uae_notifier.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';
import 'package:intl/intl.dart';

/// قسم حاسبة الإمارات — GPSSA / DEWS.
class UaeHomeSection extends ConsumerWidget {
  const UaeHomeSection({
    super.key,
    required this.country,
    required this.currency,
  });

  final GulfCountry country;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uaeState = ref.watch(homeUaeProvider);
    final model = uaeState.model;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'مدخلات الحاسبة',
          icon: Icons.account_balance_wallet_outlined,
        ),
        HomeSalaryField(
          key: const ValueKey('uae-basic'),
          label: 'الراتب الأساسي',
          value: uaeState.basicSalary,
          currencySymbol: currency.currencySymbol,
          countryFlag: '🇦🇪',
          onChanged: (v) => ref.read(homeUaeProvider.notifier).setBasic(v),
        ),
        HomeSalaryField(
          key: const ValueKey('uae-housing'),
          label: 'بدل السكن',
          value: uaeState.housingAllowance,
          currencySymbol: currency.currencySymbol,
          countryFlag: '🇦🇪',
          onChanged: (v) => ref.read(homeUaeProvider.notifier).setHousing(v),
        ),
        Text(
          'سنوات الخدمة: ${uaeState.yearsOfService}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: uaeState.yearsOfService.toDouble(),
          min: 0,
          max: 30,
          divisions: 30,
          label: '${uaeState.yearsOfService}',
          activeColor: AppColors.emerald,
          onChanged: (v) =>
              ref.read(homeUaeProvider.notifier).setYears(v.round()),
        ),
        const SizedBox(height: 8),
        Text(
          'الجنسية',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<UAENationalityType>(
          segments: const [
            ButtonSegment(value: UAENationalityType.citizen, label: Text('مواطن')),
            ButtonSegment(value: UAENationalityType.expat, label: Text('وافد')),
          ],
          selected: {uaeState.nationality},
          onSelectionChanged: (s) => ref
              .read(homeUaeProvider.notifier)
              .setNationality(s.first),
        ),
        const SizedBox(height: 20),
        GlassSurface(
          highlighted: true,
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Text(
                      model.schemeLabel,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Row('الإجمالي', currency.format(model.totalGross)),
                _Row(
                  model.isCitizen
                      ? 'خصم شهري (5%)'
                      : 'خصم شهري (${model.dewsMonthlyPercent.toStringAsFixed(2)}%)',
                  currency.format(model.monthlyContribution),
                  bold: true,
                ),
                _Row('مستحق سنوي', currency.format(model.annualGratuity)),
                _Row(
                  'إجازة (${model.annualVacationDays} يوم)',
                  currency.format(model.annualVacationValue),
                ),
              ],
            ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.icon});
  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.emerald),
            const SizedBox(width: 8),
          ],
          Text(title, style: AppTypography.sectionTitle()),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: GoogleFonts.cairo(fontSize: 13)),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
