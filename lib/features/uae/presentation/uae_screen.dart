import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

enum _AppCountry { saudi, uae }

/// حاسبة الراتب — الإمارات (GPSSA / DEWS) مع اختيار الدولة.
class UaeScreen extends ConsumerStatefulWidget {
  const UaeScreen({super.key});

  @override
  ConsumerState<UaeScreen> createState() => _UaeScreenState();
}

class _UaeScreenState extends ConsumerState<UaeScreen> {
  _AppCountry _country = _AppCountry.uae;
  UAENationalityType _nationality = UAENationalityType.citizen;
  double _basic = 0;
  double _housing = 0;
  int _yearsOfService = 0;

  UaeModel get _model => UaeModel(
        basicSalary: _basic,
        housingAllowance: _housing,
        yearsOfService: _yearsOfService,
        nationality: _nationality,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyAed = NumberFormat.currency(
      locale: 'ar_AE',
      symbol: 'د.إ',
      decimalDigits: 2,
    );

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
          'حاسبة الراتب — الخليج',
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
              Text(
                'الدولة',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_AppCountry>(
                style: _segmentStyle(),
                segments: const [
                  ButtonSegment(
                    value: _AppCountry.saudi,
                    label: Text('🇸🇦 السعودية'),
                  ),
                  ButtonSegment(
                    value: _AppCountry.uae,
                    label: Text('🇦🇪 الإمارات'),
                  ),
                ],
                selected: {_country},
                onSelectionChanged: (s) {
                  final c = s.first;
                  if (c == _AppCountry.saudi) {
                    context.go(AppRoutes.home);
                    return;
                  }
                  setState(() => _country = c);
                },
              ),
              if (_country == _AppCountry.uae) ...[
                const SizedBox(height: 20),
                _NetCard(
                  net: _model.netSalary,
                  gross: _model.totalGross,
                  deduction: _model.monthlyDeduction,
                  currency: currencyAed,
                  scheme: _model.schemeLabel,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'تفاصيل الراتب',
                  icon: Icons.payments_outlined,
                ),
                _SalaryField(
                  label: 'الراتب الأساسي',
                  value: _basic,
                  onChanged: (v) => setState(() => _basic = v),
                ),
                _SalaryField(
                  label: 'بدل السكن',
                  value: _housing,
                  onChanged: (v) => setState(() => _housing = v),
                ),
                const SizedBox(height: 20),
                _SectionTitle(
                  title: 'التأمينات / الادخار',
                  icon: Icons.shield_outlined,
                ),
                Text(
                  'الجنسية',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<UAENationalityType>(
                  style: _segmentStyle(),
                  segments: const [
                    ButtonSegment(
                      value: UAENationalityType.citizen,
                      label: Text('مواطن (GPSSA)'),
                    ),
                    ButtonSegment(
                      value: UAENationalityType.expat,
                      label: Text('وافد (DEWS)'),
                    ),
                  ],
                  selected: {_nationality},
                  onSelectionChanged: (s) =>
                      setState(() => _nationality = s.first),
                ),
                if (!_model.isCitizen) ...[
                  const SizedBox(height: 14),
                  Text(
                    'سنوات الخدمة (لنسبة DEWS)',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    style: _segmentStyle(),
                    segments: const [
                      ButtonSegment(
                        value: 2,
                        label: Text('أقل من 5 سنوات (5.83%)'),
                      ),
                      ButtonSegment(
                        value: 6,
                        label: Text('5+ سنوات (8.33%)'),
                      ),
                    ],
                    selected: {_yearsOfService >= 5 ? 6 : 2},
                    onSelectionChanged: (s) =>
                        setState(() => _yearsOfService = s.first),
                  ),
                ],
                const SizedBox(height: 20),
                _BreakdownCard(
                  model: _model,
                  currency: currencyAed,
                  isDark: isDark,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _segmentStyle() {
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
      padding: const EdgeInsets.only(bottom: 12, top: 4),
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

class _NetCard extends StatelessWidget {
  const _NetCard({
    required this.net,
    required this.gross,
    required this.deduction,
    required this.currency,
    required this.scheme,
    required this.isDark,
  });

  final double net;
  final double gross;
  final double deduction;
  final NumberFormat currency;
  final String scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow(isDark: isDark),
      ),
      child: Column(
        children: [
          Text(
            scheme,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'صافي الراتب',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(net),
            style: GoogleFonts.cairo(
              color: AppColors.goldBright,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'إجمالي ${currency.format(gross)} · خصم ${currency.format(deduction)}',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalaryField extends StatelessWidget {
  const _SalaryField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: value > 0 ? _format(value) : '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(),
          suffixText: 'د.إ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        onChanged: (t) => onChanged(double.tryParse(t.trim()) ?? 0),
      ),
    );
  }

  String _format(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.model,
    required this.currency,
    required this.isDark,
  });

  final UaeModel model;
  final NumberFormat currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final rows = <_RowData>[
      _RowData('إجمالي الراتب', model.totalGross),
      _RowData('خصم الموظف شهرياً', model.monthlyDeduction, highlight: true),
      _RowData('مستحق سنوي (موظف)', model.annualEntitlement),
    ];

    if (model.isCitizen) {
      rows.addAll([
        _RowData(
          'صاحب العمل (${GpssaRates.employerPercent}%)',
          model.employerMonthlyContribution,
        ),
        _RowData(
          'الحكومة (${GpssaRates.governmentPercent}%)',
          model.governmentMonthlyContribution,
        ),
      ]);
    } else {
      rows.add(
        _RowData(
          'نسبة DEWS (${model.dewsMonthlyPercent}% من الأساسي)',
          model.monthlyDeduction,
          subtitle: model.yearsOfService >= 5
              ? '5 سنوات فأكثر'
              : 'أقل من 5 سنوات',
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تفصيل ${model.schemeLabel}',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.label, style: GoogleFonts.cairo(fontSize: 14)),
                          if (r.subtitle != null)
                            Text(
                              r.subtitle!,
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
                    Text(
                      currency.format(r.value),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: r.highlight ? AppColors.emerald : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowData {
  const _RowData(this.label, this.value, {this.highlight = false, this.subtitle});

  final String label;
  final double value;
  final bool highlight;
  final String? subtitle;
}
