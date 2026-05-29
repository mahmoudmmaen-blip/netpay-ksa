import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/salary_distribution/domain/salary_distribution_calculator.dart';
import 'package:netgulf/features/salary_distribution/providers/salary_distribution_provider.dart';

class SalaryDistributionScreen extends ConsumerWidget {
  const SalaryDistributionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salaryDistributionProvider);
    final result = ref.watch(salaryDistributionResultProvider);
    final notifier = ref.read(salaryDistributionProvider.notifier);
    final fmt = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
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
        title: Text('توزيع الراتب',
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
              HomeSalaryField(
                label: 'الراتب الصافي',
                value: state.netSalary,
                currencySymbol: 'ر.س',
                onChanged: notifier.setNet,
              ),
              SegmentedButton<DistributionMode>(
                segments: const [
                  ButtonSegment(
                    value: DistributionMode.classic503020,
                    label: Text('50/30/20'),
                  ),
                  ButtonSegment(
                    value: DistributionMode.mode602020,
                    label: Text('60/20/20'),
                  ),
                  ButtonSegment(
                    value: DistributionMode.custom,
                    label: Text('مخصص'),
                  ),
                ],
                selected: {state.mode},
                onSelectionChanged: (s) => notifier.setMode(s.first),
              ),
              if (state.mode == DistributionMode.custom) ...[
                _SliderRow('احتياجات %', state.needsPercent, notifier.setNeeds),
                _SliderRow('رغبات %', state.wantsPercent, notifier.setWants),
                _SliderRow('ادخار %', state.savingsPercent, notifier.setSavings),
              ],
              HomeSalaryField(
                label: 'الإيجار (اختياري)',
                value: state.rent,
                currencySymbol: 'ر.س',
                onChanged: notifier.setRent,
              ),
              if (result.rentWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'إيجارك مرتفع — يستنزف ${result.rentPercentOfNet.toStringAsFixed(0)}% من راتبك',
                    style: GoogleFonts.cairo(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _CategoryCard(
                emoji: '🏠',
                title: 'الأساسيات (احتياجات)',
                amount: result.needsAmount,
                percent: result.needsPercent,
                color: AppColors.emerald,
                fmt: fmt,
              ),
              _CategoryCard(
                emoji: '🎯',
                title: 'الرغبات (ترفيه)',
                amount: result.wantsAmount,
                percent: result.wantsPercent,
                color: Colors.blue.shade600,
                fmt: fmt,
              ),
              _CategoryCard(
                emoji: '💰',
                title: 'الادخار والديون',
                amount: result.savingsAmount,
                percent: result.savingsPercent,
                color: AppColors.gold,
                fmt: fmt,
              ),
              if (state.netSalary > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: result.needsAmount,
                          color: AppColors.emerald,
                          title: '${result.needsPercent.round()}%',
                          radius: 50,
                          titleStyle: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: result.wantsAmount,
                          color: Colors.blue.shade600,
                          title: '${result.wantsPercent.round()}%',
                          radius: 46,
                          titleStyle: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: result.savingsAmount,
                          color: AppColors.gold,
                          title: '${result.savingsPercent.round()}%',
                          radius: 42,
                          titleStyle: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                    ),
                  ),
                ),
                Text(
                  'إذا ادّخرت ${fmt.format(result.savingsAmount)} شهرياً لمدة ${state.savingsYears} سنوات = ${fmt.format(result.projectedSavings)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12, height: 1.45),
                ),
                Slider(
                  value: state.savingsYears.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${state.savingsYears} سنة',
                  onChanged: (v) => notifier.setYears(v.round()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow(this.label, this.value, this.onChanged);
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$label: ${value.round()}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
        Slider(value: value, min: 0, max: 100, onChanged: onChanged),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.amount,
    required this.percent,
    required this.color,
    required this.fmt,
  });

  final String emoji;
  final String title;
  final double amount;
  final double percent;
  final Color color;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                  Text(
                    '${percent.round()}% · ${fmt.format(amount)}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
