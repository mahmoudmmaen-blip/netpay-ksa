import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_typography.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netgulf/features/gosi/domain/enums/nationality_type.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';
import 'package:intl/intl.dart';

/// قسم مدخلات السعودية — GOSI.
class SaudiHomeSection extends ConsumerWidget {
  const SaudiHomeSection({
    super.key,
    required this.country,
    required this.currency,
  });

  final GulfCountry country;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salary = ref.watch(salaryNotifierProvider);
    final gosi = salary.gosi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: 'مدخلات الحاسبة', icon: Icons.edit_note_rounded),
        HomeSalaryField(
          key: const ValueKey('sa-basic'),
          label: 'الراتب الأساسي',
          value: salary.basicSalary,
          currencySymbol: currency.currencySymbol,
          countryFlag: '🇸🇦',
          onChanged: (v) =>
              ref.read(salaryNotifierProvider.notifier).setBasic(v),
        ),
        HomeSalaryField(
          key: const ValueKey('sa-housing'),
          label: 'بدل السكن',
          value: salary.housingAllowance,
          currencySymbol: currency.currencySymbol,
          countryFlag: '🇸🇦',
          onChanged: (v) =>
              ref.read(salaryNotifierProvider.notifier).setHousing(v),
        ),
        HomeSalaryField(
          key: const ValueKey('sa-other'),
          label: 'بدلات أخرى',
          value: salary.otherAllowances,
          currencySymbol: currency.currencySymbol,
          countryFlag: '🇸🇦',
          onChanged: (v) =>
              ref.read(salaryNotifierProvider.notifier).setOther(v),
        ),
        const SizedBox(height: 8),
        Text(
          'نظام GOSI',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<GosiRegime>(
          style: _segmentStyle(context),
          segments: const [
            ButtonSegment(
              value: GosiRegime.legacy,
              label: Text('قديم'),
              icon: Icon(Icons.history_rounded, size: 18),
            ),
            ButtonSegment(
              value: GosiRegime.newLawPhased,
              label: Text('جديد 2026'),
              icon: Icon(Icons.new_releases_rounded, size: 18),
            ),
          ],
          selected: {salary.regime},
          onSelectionChanged: (s) =>
              ref.read(salaryNotifierProvider.notifier).setRegime(s.first),
        ),
        const SizedBox(height: 14),
        _GosiBaseSwitch(
          value: salary.includeOtherInGosiBase,
          onChanged: (v) => ref
              .read(salaryNotifierProvider.notifier)
              .setIncludeOtherInGosi(v),
        ),
        const SizedBox(height: 16),
        Text(
          'الجنسية',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<NationalityType>(
          style: _segmentStyle(context),
          segments: const [
            ButtonSegment(
              value: NationalityType.saudi,
              label: Text('سعودي'),
            ),
            ButtonSegment(
              value: NationalityType.nonSaudi,
              label: Text('غير سعودي'),
            ),
          ],
          selected: {salary.nationality},
          onSelectionChanged: (s) => ref
              .read(salaryNotifierProvider.notifier)
              .setNationality(s.first),
        ),
        if (gosi != null) ...[
          const SizedBox(height: 20),
          _GosiBreakdownCard(gosi: gosi, currency: currency),
        ],
      ],
    );
  }

  ButtonStyle _segmentStyle(BuildContext context) {
    return ButtonStyle(
      visualDensity: VisualDensity.compact,
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
      ),
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
      padding: const EdgeInsets.only(bottom: 14, top: 4),
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

class _GosiBaseSwitch extends StatelessWidget {
  const _GosiBaseSwitch({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          'إدراج البدلات الأخرى في أجر الاشتراك',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        value: value,
        activeThumbColor: AppColors.emerald,
        onChanged: onChanged,
      ),
    );
  }
}

class _GosiBreakdownCard extends StatelessWidget {
  const _GosiBreakdownCard({required this.gosi, required this.currency});
  final GosiModel gosi;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      highlighted: true,
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تفصيل GOSI',
            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Row('خصم الموظف', currency.format(gosi.employeeGosi), bold: true),
          _Row('اشتراك صاحب العمل', currency.format(gosi.employerGosi)),
          _Row('أجر الاشتراك', currency.format(gosi.contributableWage)),
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
          Text(label, style: GoogleFonts.cairo(fontSize: 13)),
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
