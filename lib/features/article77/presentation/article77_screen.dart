import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/article77/domain/article77_calculator.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';

class Article77Screen extends ConsumerStatefulWidget {
  const Article77Screen({super.key});

  @override
  ConsumerState<Article77Screen> createState() => _Article77ScreenState();
}

class _Article77ScreenState extends ConsumerState<Article77Screen> {
  Article77TerminatedBy _terminatedBy = Article77TerminatedBy.employer;
  Article77ContractType _contractType = Article77ContractType.openEnded;
  double _basicSalary = 0;
  double _remainingMonths = 6;
  double _yearsOfService = 3;
  bool _hasPenaltyClause = false;
  double _penaltyAmount = 0;

  Article77Result get _result => Article77Calculator.calculate(
        Article77Input(
          terminatedBy: _terminatedBy,
          contractType: _contractType,
          basicSalary: _basicSalary,
          remainingMonths: _remainingMonths,
          yearsOfService: _yearsOfService,
          hasPenaltyClause: _hasPenaltyClause,
          penaltyAmount: _penaltyAmount,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 0,
    );
    final result = _result;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حاسبة الفسخ التعسفي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'المادة 77 — نظام العمل السعودي',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
              ),
            ),
          ],
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
              Text('من أنهى العقد؟',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<Article77TerminatedBy>(
                segments: const [
                  ButtonSegment(
                    value: Article77TerminatedBy.employee,
                    label: Text('العامل أنهى'),
                  ),
                  ButtonSegment(
                    value: Article77TerminatedBy.employer,
                    label: Text('صاحب العمل أنهى'),
                  ),
                ],
                selected: {_terminatedBy},
                onSelectionChanged: (s) =>
                    setState(() => _terminatedBy = s.first),
              ),
              const SizedBox(height: 16),
              HomeSalaryField(
                label: 'الراتب الأساسي',
                value: _basicSalary,
                currencySymbol: 'ر.س',
                onChanged: (v) => setState(() => _basicSalary = v),
              ),
              Text('نوع العقد',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<Article77ContractType>(
                segments: const [
                  ButtonSegment(
                    value: Article77ContractType.fixedTerm,
                    label: Text('محدد'),
                  ),
                  ButtonSegment(
                    value: Article77ContractType.openEnded,
                    label: Text('غير محدد'),
                  ),
                ],
                selected: {_contractType},
                onSelectionChanged: (s) =>
                    setState(() => _contractType = s.first),
              ),
              const SizedBox(height: 12),
              if (_contractType == Article77ContractType.fixedTerm)
                _LabeledSlider(
                  label: 'الأشهر المتبقية في العقد',
                  value: _remainingMonths,
                  min: 1,
                  max: 60,
                  divisions: 59,
                  display: '${_remainingMonths.round()} شهر',
                  onChanged: (v) => setState(() => _remainingMonths = v),
                )
              else
                _LabeledSlider(
                  label: 'سنوات الخدمة',
                  value: _yearsOfService,
                  min: 0,
                  max: 30,
                  divisions: 60,
                  display: '${_yearsOfService.toStringAsFixed(1)} سنة',
                  onChanged: (v) => setState(() => _yearsOfService = v),
                ),
              if (_terminatedBy == Article77TerminatedBy.employee) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'يوجد شرط جزائي في العقد؟',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  value: _hasPenaltyClause,
                  activeThumbColor: AppColors.emerald,
                  onChanged: (v) => setState(() => _hasPenaltyClause = v),
                ),
                if (_hasPenaltyClause)
                  HomeSalaryField(
                    label: 'مبلغ الشرط الجزائي',
                    value: _penaltyAmount,
                    currencySymbol: 'ر.س',
                    onChanged: (v) => setState(() => _penaltyAmount = v),
                  ),
              ],
              const SizedBox(height: 20),
              GlassSurface(
                borderRadius: 18,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'المبلغ المستحق',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmt.format(result.totalAmount),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        color: AppColors.emerald,
                      ),
                    ),
                    if (result.breakdown.isNotEmpty) ...[
                      const Divider(height: 28),
                      Text(
                        'التفصيل',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      ...result.breakdown.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  line.label,
                                  style: GoogleFonts.cairo(fontSize: 13),
                                ),
                              ),
                              Text(
                                fmt.format(line.amount),
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      result.legalReference,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.shade700.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        result.note,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            ),
            Text(display,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                )),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
