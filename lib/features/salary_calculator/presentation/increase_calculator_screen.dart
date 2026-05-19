import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/gosi/providers/gosi_calculator_provider.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// حاسبة زيادة الراتب — أثر الزيادة على الصافي و GOSI.
class IncreaseCalculatorScreen extends ConsumerStatefulWidget {
  const IncreaseCalculatorScreen({super.key});

  @override
  ConsumerState<IncreaseCalculatorScreen> createState() =>
      _IncreaseCalculatorScreenState();
}

class _IncreaseCalculatorScreenState
    extends ConsumerState<IncreaseCalculatorScreen> {
  double _increasePercent = 10;

  GosiModel? _gosiForBasic(double basic) {
    final salary = ref.read(salaryNotifierProvider);
    try {
      return GosiModel.fromSalaryForm(
        allowances: SalaryAllowances(
          basicSalary: basic,
          housingAllowance: salary.housingAllowance,
          otherAllowances: salary.otherAllowances,
          includeOtherInGosiBase: salary.includeOtherInGosiBase,
        ),
        nationality: salary.nationality,
        regime: salary.regime,
        calculationDate: salary.effectiveDate,
        calculator: ref.read(gosiCalculatorProvider),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final salary = ref.watch(salaryNotifierProvider);
    final currentBasic = salary.basicSalary;
    final newBasic = currentBasic * (1 + _increasePercent / 100);

    final currentGosi = _gosiForBasic(currentBasic);
    final newGosi = _gosiForBasic(newBasic);

    final currentNet = currentGosi?.netSalary ?? 0;
    final newNet = newGosi?.netSalary ?? 0;
    final netDiff = newNet - currentNet;
    final gosiDiff =
        (newGosi?.employeeGosi ?? 0) - (currentGosi?.employeeGosi ?? 0);

    final currency = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 2,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: Text(
          'حاسبة الزيادة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.cardShadow(isDark: isDark),
                ),
                child: Column(
                  children: [
                    Text(
                      'الصافي بعد الزيادة',
                      style: GoogleFonts.cairo(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currency.format(newNet),
                      style: GoogleFonts.cairo(
                        color: AppColors.goldBright,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+${currency.format(netDiff)} شهرياً',
                      style: GoogleFonts.cairo(
                        color: AppColors.success,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'الراتب الحالي', icon: Icons.payments_outlined),
              _InfoTile(
                label: 'الأساسي الحالي',
                value: currency.format(currentBasic),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'نسبة الزيادة',
                icon: Icons.trending_up_rounded,
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _increasePercent,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      activeColor: AppColors.emerald,
                      label: '${_increasePercent.round()}%',
                      onChanged: (v) => setState(() => _increasePercent = v),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${_increasePercent.round()}%',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'المقارنة', icon: Icons.compare_arrows_rounded),
              _ComparisonCard(
                rows: [
                  _RowData('الأساسي الجديد', currency.format(newBasic)),
                  _RowData('الصافي الحالي', currency.format(currentNet)),
                  _RowData('الصافي الجديد', currency.format(newNet)),
                  _RowData(
                    'فرق الصافي',
                    '${netDiff >= 0 ? '+' : ''}${currency.format(netDiff)}',
                    highlight: true,
                  ),
                  _RowData(
                    'فرق خصم GOSI',
                    '${gosiDiff >= 0 ? '+' : ''}${currency.format(gosiDiff)}',
                  ),
                ],
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.emerald),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.cairo(fontSize: 13)),
      trailing: Text(
        value,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RowData {
  const _RowData(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.rows});

  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rows[i].label,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight:
                        rows[i].highlight ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                Text(
                  rows[i].value,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: rows[i].highlight
                        ? AppColors.emerald
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
