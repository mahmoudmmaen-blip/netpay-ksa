import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_typography.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/salary_calculator/models/uae_salary_model.dart';
import 'package:netgulf/features/salary_calculator/providers/uae_salary_provider.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

/// قسم حاسبة الإمارات — GPSSA / DEWS + EOS + إجازة + تذكرة.
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
    final uaeState = ref.watch(uaeSalaryNotifierProvider);
    final model = uaeState.model;
    final notifier = ref.read(uaeSalaryNotifierProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(label: UaeSalaryLabels.calculatorInputs),
        _BilingualField(
          label: UaeSalaryLabels.basicSalary,
          child: HomeSalaryField(
            key: const ValueKey('uae-basic'),
            label: UaeSalaryLabels.basicSalary.combined,
            value: uaeState.basicSalary,
            currencySymbol: currency.currencySymbol,
            countryFlag: '🇦🇪',
            onChanged: notifier.setBasic,
          ),
        ),
        _BilingualField(
          label: UaeSalaryLabels.housingAllowance,
          child: HomeSalaryField(
            key: const ValueKey('uae-housing'),
            label: UaeSalaryLabels.housingAllowance.combined,
            value: uaeState.housingAllowance,
            currencySymbol: currency.currencySymbol,
            countryFlag: '🇦🇪',
            onChanged: notifier.setHousing,
          ),
        ),
        _BilingualField(
          label: UaeSalaryLabels.transportationAllowance,
          child: HomeSalaryField(
            key: const ValueKey('uae-transport'),
            label: UaeSalaryLabels.transportationAllowance.combined,
            value: uaeState.transportationAllowance,
            currencySymbol: currency.currencySymbol,
            countryFlag: '🇦🇪',
            onChanged: notifier.setTransportation,
          ),
        ),
        _BilingualField(
          label: UaeSalaryLabels.airTicketAllowance,
          child: HomeSalaryField(
            key: const ValueKey('uae-air-ticket'),
            label: UaeSalaryLabels.airTicketAllowance.combined,
            value: uaeState.airTicketAllowanceMonthly,
            currencySymbol: currency.currencySymbol,
            countryFlag: '🇦🇪',
            onChanged: notifier.setAirTicket,
          ),
        ),
        _BilingualField(
          label: UaeSalaryLabels.healthInsurance,
          child: HomeSalaryField(
            key: const ValueKey('uae-health'),
            label: UaeSalaryLabels.healthInsurance.combined,
            value: uaeState.healthInsuranceMonthly,
            currencySymbol: currency.currencySymbol,
            countryFlag: '🇦🇪',
            onChanged: notifier.setHealthInsurance,
          ),
        ),
        _BilingualField(
          label: UaeSalaryLabels.visaFees,
          child: HomeSalaryField(
            key: const ValueKey('uae-visa'),
            label: UaeSalaryLabels.visaFees.combined,
            value: uaeState.visaFeesMonthly,
            currencySymbol: currency.currencySymbol,
            countryFlag: '🇦🇪',
            onChanged: notifier.setVisaFees,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${UaeSalaryLabels.yearsOfService.ar}: ${uaeState.yearsOfService}',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        Text(
          UaeSalaryLabels.yearsOfService.en,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Slider(
          value: uaeState.yearsOfService.toDouble(),
          min: 0,
          max: 30,
          divisions: 30,
          label: '${uaeState.yearsOfService}',
          activeColor: AppColors.emerald,
          onChanged: (v) => notifier.setYears(v.round()),
        ),
        Text(
          '${UaeSalaryLabels.annualLeaveEncashment.ar} (${UaeSalaryLabels.annualLeaveEncashment.en})',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '0 = ${model.annualLeaveDays} ${UaeSalaryLabels.annualLeaveEncashment.en}',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Slider(
          value: uaeState.unusedLeaveDays.toDouble(),
          min: 0,
          max: 30,
          divisions: 30,
          label: '${uaeState.unusedLeaveDays}',
          activeColor: AppColors.gold,
          onChanged: (v) => notifier.setUnusedLeaveDays(v.round()),
        ),
        Text(
          UaeSalaryLabels.nationality.combined,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<UAENationalityType>(
          segments: [
            ButtonSegment(
              value: UAENationalityType.citizen,
              label: Text(UaeSalaryLabels.citizen.combined),
            ),
            ButtonSegment(
              value: UAENationalityType.expat,
              label: Text(UaeSalaryLabels.expat.combined),
            ),
          ],
          selected: {uaeState.nationality},
          onSelectionChanged: (s) => notifier.setNationality(s.first),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.schemeLabelAr,
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          model.schemeLabelEn,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Row(
                UaeSalaryLabels.totalGross,
                currency.format(model.totalGross),
              ),
              _Row(
                UaeSalaryLabels.airTicketAllowance,
                currency.format(model.airTicketAllowanceMonthly),
              ),
              _Row(
                UaeSalaryLabels.monthlyDeductions,
                currency.format(model.totalMonthlyDeductions),
                bold: true,
              ),
              _Row(
                UaeSalaryLabels.pensionScheme,
                currency.format(model.pensionContribution),
              ),
              _Row(
                UaeSalaryLabels.healthInsurance,
                currency.format(model.healthInsuranceMonthly),
              ),
              _Row(
                UaeSalaryLabels.visaFees,
                currency.format(model.visaFeesMonthly),
              ),
              const Divider(height: 20),
              _Row(
                UaeSalaryLabels.endOfService,
                currency.format(model.endOfServiceGratuity),
                bold: true,
              ),
              if (model.yearsOfService >= 1)
                _Row(
                  const BilingualText(
                    'استحقاق شهري (EOS)',
                    'Monthly EOS Accrual',
                  ),
                  currency.format(model.endOfServiceMonthlyAccrual),
                ),
              _Row(
                UaeSalaryLabels.annualLeaveEncashment,
                currency.format(model.annualLeaveEncashment),
              ),
              const Divider(height: 20),
              _Row(
                UaeSalaryLabels.netSalary,
                currency.format(model.netSalary),
                bold: true,
                highlight: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BilingualField extends StatelessWidget {
  const _BilingualField({required this.label, required this.child});

  final BilingualText label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [child],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final BilingualText label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  size: 20, color: AppColors.emerald),
              const SizedBox(width: 8),
              Text(label.ar, style: AppTypography.sectionTitle()),
            ],
          ),
          Text(
            label.en,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
    this.label,
    this.value, {
    this.bold = false,
    this.highlight = false,
  });

  final BilingualText label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.ar, style: GoogleFonts.cairo(fontSize: 13)),
                Text(
                  label.en,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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
