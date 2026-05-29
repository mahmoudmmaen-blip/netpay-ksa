import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/allowances/domain/allowances_calculator.dart';
import 'package:netgulf/features/allowances/providers/allowances_provider.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';

/// حاسبة البدلات وإجمالي الحزمة.
class AllowancesScreen extends ConsumerWidget {
  const AllowancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(allowancesProvider);
    final result = ref.watch(allowancesResultProvider);
    final notifier = ref.read(allowancesProvider.notifier);
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
        title: Text(
          'حاسبة البدلات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text('دولة العمل',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              EosbCountryGrid(
                selected: state.country,
                onSelected: (c) {
                  HapticFeedback.selectionClick();
                  notifier.setCountry(c);
                },
              ),
              const SizedBox(height: 16),
              HomeSalaryField(
                label: 'الراتب الأساسي',
                value: state.basicSalary,
                currencySymbol: state.country.currencySymbol,
                countryFlag: state.country.flag,
                onChanged: notifier.setBasic,
              ),
              const SizedBox(height: 12),
              _AllowanceToggle(
                title: 'سكن',
                enabled: state.housingEnabled,
                amount: state.housingAmount,
                hint: 'افتراضي ${(AllowancesCalculator.rules(state.country)['housing_pct'] as num) * 100}%',
                onToggle: (v) => notifier.setHousing(enabled: v),
                onAmount: (a) => notifier.setHousing(amount: a),
              ),
              _AllowanceToggle(
                title: 'مواصلات',
                enabled: state.transportEnabled,
                amount: state.transportAmount,
                onToggle: (v) => notifier.setTransport(enabled: v),
                onAmount: (a) => notifier.setTransport(amount: a),
              ),
              _AllowanceToggle(
                title: 'هاتف',
                enabled: state.phoneEnabled,
                amount: state.phoneAmount,
                onToggle: (v) => notifier.setPhone(enabled: v),
                onAmount: (a) => notifier.setPhone(amount: a),
              ),
              _AllowanceToggle(
                title: 'غذاء',
                enabled: state.foodEnabled,
                amount: state.foodAmount,
                onToggle: (v) => notifier.setFood(enabled: v),
                onAmount: (a) => notifier.setFood(amount: a),
              ),
              _AllowanceToggle(
                title: 'أخرى',
                enabled: state.otherEnabled,
                amount: state.otherAmount,
                onToggle: (v) => notifier.setOther(enabled: v),
                onAmount: (a) => notifier.setOther(amount: a),
              ),
              const SizedBox(height: 20),
              GlassSurface(
                highlighted: true,
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ResRow('إجمالي الحزمة', currency.format(result.totalPackage),
                        bold: true),
                    _ResRow('وعاء التأمينات', currency.format(result.gosiBase)),
                    _ResRow(
                      'صافي بعد التأمينات (${(result.employeeRate * 100).toStringAsFixed(1)}%)',
                      currency.format(result.netAfterGosi),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.eosbIncludesHousing
                          ? 'نهاية الخدمة: الأساسي + السكن'
                          : 'نهاية الخدمة: الأساسي فقط (حسب الدولة)',
                      style: GoogleFonts.cairo(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (state.basicSalary > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: result.totalPackage * 1.2,
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: result.basicSalary,
                              color: AppColors.emerald.withValues(alpha: 0.7),
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: result.totalPackage,
                              color: AppColors.emerald,
                              width: 28,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(
                              v == 0 ? 'أساسي' : 'الحزمة',
                              style: GoogleFonts.cairo(fontSize: 11),
                            ),
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
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

class _AllowanceToggle extends StatelessWidget {
  const _AllowanceToggle({
    required this.title,
    required this.enabled,
    required this.amount,
    required this.onToggle,
    required this.onAmount,
    this.hint,
  });

  final String title;
  final bool enabled;
  final double amount;
  final String? hint;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
                Switch(
                  value: enabled,
                  activeThumbColor: AppColors.emerald,
                  onChanged: onToggle,
                ),
              ],
            ),
            if (enabled)
              TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: hint ?? 'المبلغ (اختياري)',
                  labelStyle: GoogleFonts.cairo(fontSize: 12),
                  border: InputBorder.none,
                ),
                onChanged: (t) => onAmount(double.tryParse(t) ?? 0),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResRow extends StatelessWidget {
  const _ResRow(this.label, this.value, {this.bold = false});
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
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.emerald : null,
            ),
          ),
        ],
      ),
    );
  }
}
