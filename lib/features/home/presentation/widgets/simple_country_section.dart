import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/home/providers/home_salary_provider.dart';

/// قسم الحاسبة للدول البسيطة (عمان، قطر، البحرين، الكويت).
/// لا اقتطاع تأمين مباشر — الصافي = الإجمالي.
class SimpleCountrySection extends ConsumerWidget {
  const SimpleCountrySection({
    super.key,
    required this.country,
    required this.currency,
  });

  final GulfCountry country;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simpleCountrySalaryProvider);
    final notifier = ref.read(simpleCountrySalaryProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14, top: 4),
          child: Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: AppColors.emerald,
              ),
              const SizedBox(width: 8),
              Text(
                'مدخلات الحاسبة',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        HomeSalaryField(
          key: ValueKey('${country.name}-basic'),
          label: 'الراتب الأساسي',
          value: state.basicSalary,
          currencySymbol: currency.currencySymbol,
          countryFlag: country.flag,
          onChanged: notifier.setBasic,
        ),
        HomeSalaryField(
          key: ValueKey('${country.name}-housing'),
          label: 'بدل السكن',
          value: state.housingAllowance,
          currencySymbol: currency.currencySymbol,
          countryFlag: country.flag,
          onChanged: notifier.setHousing,
        ),
        HomeSalaryField(
          key: ValueKey('${country.name}-other'),
          label: 'بدلات أخرى',
          value: state.otherAllowances,
          currencySymbol: currency.currencySymbol,
          countryFlag: country.flag,
          onChanged: notifier.setOther,
        ),
        const SizedBox(height: 16),
        GlassSurface(
          highlighted: true,
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.emerald,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${country.nameAr} — ${country.schemeShort}',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SummaryRow('إجمالي الراتب', currency.format(state.totalGross)),
              _SummaryRow('اقتطاع التأمين', currency.format(0)),
              const Divider(height: 20),
              _SummaryRow(
                'الراتب الصافي',
                currency.format(state.totalGross),
                bold: true,
                highlight: true,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ملاحظة: ${country.nameAr} لا تطبق اقتطاع تأمينات على المقيمين الأجانب. الراتب الصافي = الإجمالي.',
                  style: GoogleFonts.cairo(fontSize: 11, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.label,
    this.value, {
    this.bold = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool highlight;

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
              color: highlight ? AppColors.emerald : null,
            ),
          ),
        ],
      ),
    );
  }
}
