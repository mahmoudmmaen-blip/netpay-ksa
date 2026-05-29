import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/home_loan/providers/home_loan_provider.dart';

class HomeLoanScreen extends ConsumerWidget {
  const HomeLoanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeLoanProvider);
    final result = ref.watch(homeLoanResultProvider);
    final notifier = ref.read(homeLoanProvider.notifier);
    final currency = NumberFormat.currency(
      locale: state.country.currencyLocale,
      symbol: state.country.currencySymbol,
      decimalDigits: 0,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.home),
        ),
        title: Text('قرض السكن',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              EosbCountryGrid(
                selected: state.country,
                onSelected: notifier.setCountry,
              ),
              const SizedBox(height: 12),
              HomeSalaryField(
                label: 'سعر العقار',
                value: state.propertyPrice,
                currencySymbol: state.country.currencySymbol,
                onChanged: notifier.setPropertyPrice,
              ),
              Text('الدفعة الأولى: ${state.downPaymentPercent.round()}%',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              Slider(
                value: state.downPaymentPercent,
                min: 10,
                max: 30,
                divisions: 4,
                label: '${state.downPaymentPercent.round()}%',
                onChanged: notifier.setDownPayment,
              ),
              HomeSalaryField(
                label: 'نسبة الفائدة السنوية %',
                value: state.annualInterestRate,
                currencySymbol: '%',
                onChanged: notifier.setRate,
              ),
              Text('مدة القرض',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              Wrap(
                spacing: 8,
                children: [5, 10, 15, 20, 25, 30].map((y) {
                  return ChoiceChip(
                    label: Text('$y سنة', style: GoogleFonts.cairo(fontSize: 12)),
                    selected: state.loanYears == y,
                    onSelected: (_) => notifier.setYears(y),
                  );
                }).toList(),
              ),
              HomeSalaryField(
                label: 'الراتب الشهري (اختياري)',
                value: state.monthlySalary,
                currencySymbol: state.country.currencySymbol,
                onChanged: notifier.setSalary,
              ),
              if (state.propertyPrice > 0) ...[
                const SizedBox(height: 20),
                GlassSurface(
                  highlighted: true,
                  borderRadius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('القسط الشهري',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                      Text(
                        currency.format(result.monthlyPayment),
                        style: GoogleFonts.cairo(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.emerald,
                        ),
                      ),
                      _Row('مبلغ القرض', currency.format(result.loanAmount)),
                      _Row('إجمالي المدفوع', currency.format(result.totalPaid)),
                      _Row('إجمالي الفوائد', currency.format(result.totalInterest)),
                      _Row('نسبة الفوائد',
                          '${result.interestPercent.toStringAsFixed(1)}%'),
                      if (result.affordabilityRatio != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          result.affordabilityWarning
                              ? 'تحذير: القسط ${(result.affordabilityRatio! * 100).toStringAsFixed(0)}% من راتبك (أعلى من 33%)'
                              : 'نسبة القسط من الراتب: ${(result.affordabilityRatio! * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: result.affordabilityWarning
                                ? Colors.red.shade400
                                : AppColors.emerald,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: [
                        PieChartSectionData(
                          value: result.loanAmount,
                          color: AppColors.emerald,
                          title: 'أصل',
                          radius: 48,
                          titleStyle: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: result.totalInterest,
                          color: Colors.orange.shade600,
                          title: 'فوائد',
                          radius: 44,
                          titleStyle: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: notifier.toggleSchedule,
                  icon: Icon(state.showSchedule
                      ? Icons.expand_less
                      : Icons.expand_more),
                  label: Text('جدول السداد',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
                if (state.showSchedule)
                  ...result.yearlyBreakdown.map(
                    (y) => ListTile(
                      dense: true,
                      title: Text('السنة ${y.year}',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        'أصل: ${currency.format(y.principalPaid)} · فوائد: ${currency.format(y.interestPaid)} · متبقي: ${currency.format(y.remainingBalance)}',
                        style: GoogleFonts.cairo(fontSize: 11),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 13)),
          Text(value, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
