import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

enum _GulfCountry { saudi, uae }

/// حاسبة الراتب الإماراتية — GPSSA + DEWS/WPS.
class UaeCalculatorScreen extends ConsumerStatefulWidget {
  const UaeCalculatorScreen({super.key});

  @override
  ConsumerState<UaeCalculatorScreen> createState() =>
      _UaeCalculatorScreenState();
}

class _UaeCalculatorScreenState extends ConsumerState<UaeCalculatorScreen> {
  _GulfCountry _country = _GulfCountry.uae;
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
    final currency = NumberFormat.currency(
      locale: 'ar_AE',
      symbol: 'د.إ',
      decimalDigits: 2,
    );
    final model = _model;

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
            'حاسبة الإمارات',
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
                SegmentedButton<_GulfCountry>(
                  style: _segmentStyle(),
                  segments: const [
                    ButtonSegment(
                      value: _GulfCountry.saudi,
                      label: Text('🇸🇦 السعودية'),
                    ),
                    ButtonSegment(
                      value: _GulfCountry.uae,
                      label: Text('🇦🇪 الإمارات'),
                    ),
                  ],
                  selected: {_country},
                  onSelectionChanged: (s) {
                    if (s.first == _GulfCountry.saudi) {
                      context.go(AppRoutes.home);
                      return;
                    }
                    setState(() => _country = s.first);
                  },
                ),
                const SizedBox(height: 20),
                _ResultsCard(
                  model: model,
                  currency: currency,
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _SectionTitle(
                  title: 'تفاصيل الراتب',
                  icon: Icons.payments_outlined,
                ),
                _AedField(
                  label: 'الراتب الأساسي',
                  value: _basic,
                  onChanged: (v) => setState(() => _basic = v),
                ),
                _AedField(
                  label: 'بدل السكن',
                  value: _housing,
                  onChanged: (v) => setState(() => _housing = v),
                ),
                _AedField(
                  label: 'سنوات الخدمة',
                  value: _yearsOfService.toDouble(),
                  isInteger: true,
                  suffix: 'سنة',
                  onChanged: (v) => setState(() => _yearsOfService = v.round()),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'الجنسية',
                  icon: Icons.badge_outlined,
                ),
                SegmentedButton<UAENationalityType>(
                  style: _segmentStyle(),
                  segments: const [
                    ButtonSegment(
                      value: UAENationalityType.citizen,
                      label: Text('مواطن'),
                    ),
                    ButtonSegment(
                      value: UAENationalityType.expat,
                      label: Text('وافد'),
                    ),
                  ],
                  selected: {_nationality},
                  onSelectionChanged: (s) =>
                      setState(() => _nationality = s.first),
                ),
                const SizedBox(height: 16),
                _BreakdownCard(model: model, currency: currency),
                const SizedBox(height: 16),
                _DisclaimerBanner(),
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

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.model,
    required this.currency,
    required this.isDark,
  });

  final UaeModel model;
  final NumberFormat currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow(isDark: isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            model.schemeLabel,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'صافي الراتب',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
            ),
          ),
          Text(
            currency.format(model.netSalary),
            style: GoogleFonts.cairo(
              color: AppColors.goldBright,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _ResultRow(
            label: 'الاشتراك الشهري',
            value: currency.format(model.monthlyContribution),
          ),
          const SizedBox(height: 8),
          _ResultRow(
            label: 'المكافأة / التراكم السنوي',
            value: currency.format(model.annualGratuity),
          ),
          if (model.annualVacationDays > 0) ...[
            const SizedBox(height: 8),
            _ResultRow(
              label: 'قيمة الإجازة (${model.annualVacationDays} يوم)',
              value: currency.format(model.annualVacationValue),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _AedField extends StatefulWidget {
  const _AedField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isInteger = false,
    this.suffix,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isInteger;
  final String? suffix;

  @override
  State<_AedField> createState() => _AedFieldState();
}

class _AedFieldState extends State<_AedField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _AedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value || _focusNode.hasFocus) return;
    final formatted = _format(widget.value);
    if (_controller.text != formatted) _controller.text = formatted;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) {
    if (v <= 0) return '';
    return widget.isInteger ? v.round().toString() : v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [
          if (widget.isInteger)
            FilteringTextInputFormatter.digitsOnly
          else
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.cairo(),
          suffixText: widget.suffix ?? 'د.إ',
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (t) {
          final v = widget.isInteger
              ? (int.tryParse(t) ?? 0).toDouble()
              : (double.tryParse(t) ?? 0);
          widget.onChanged(v);
        },
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.model, required this.currency});

  final UaeModel model;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
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
            _Line('إجمالي الراتب', currency.format(model.totalGross)),
            _Line(
              'اشتراك الموظف',
              currency.format(model.monthlyContribution),
              highlight: true,
            ),
            if (model.isCitizen) ...[
              _Line(
                'صاحب العمل (${GpssaRates.employerPercent}%)',
                currency.format(model.employerMonthlyContribution),
              ),
              _Line(
                'الحكومة (${GpssaRates.governmentPercent}%)',
                currency.format(model.governmentMonthlyContribution),
              ),
            ] else
              _Line(
                'نسبة DEWS (${model.dewsMonthlyPercent}% من الأساسي)',
                currency.format(model.monthlyContribution),
              ),
            _Line(
              'إجازة سنوية',
              model.annualVacationDays > 0
                  ? '${model.annualVacationDays} يوم — ${currency.format(model.annualVacationValue)}'
                  : 'بعد سنة خدمة — 30 يوماً',
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.cairo(fontSize: 13)),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: highlight ? AppColors.emerald : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_outlined, color: AppColors.info, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'استناداً لقانون العمل الإماراتي — تقدير تقريبي وليس استشارة قانونية.',
              style: GoogleFonts.cairo(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
