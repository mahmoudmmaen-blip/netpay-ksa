import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netpay_ksa/core/router/app_routes.dart';
import 'package:netpay_ksa/core/theme/app_colors.dart';
import 'package:netpay_ksa/features/eosb/domain/models/eosb_model.dart';
import 'package:netpay_ksa/features/salary_calculator/providers/salary_notifier.dart';

/// حاسبة نهاية الخدمة والمستحقات — المادتان 84 و 85.
class EosbScreen extends ConsumerStatefulWidget {
  const EosbScreen({super.key});

  @override
  ConsumerState<EosbScreen> createState() => _EosbScreenState();
}

class _EosbScreenState extends ConsumerState<EosbScreen> {
  final _yearsController = TextEditingController(text: '0');
  final _monthsController = TextEditingController(text: '0');
  final _basicController = TextEditingController();
  final _housingController = TextEditingController();
  final _ticketController = TextEditingController(text: '0');

  EosbContractType _contractType = EosbContractType.unlimited;
  FlightTicketFrequency _ticketFrequency = FlightTicketFrequency.yearly;
  bool _salarySynced = false;

  @override
  void dispose() {
    _yearsController.dispose();
    _monthsController.dispose();
    _basicController.dispose();
    _housingController.dispose();
    _ticketController.dispose();
    super.dispose();
  }

  void _syncFromSalaryIfNeeded() {
    if (_salarySynced) return;
    final salary = ref.read(salaryNotifierProvider);
    _basicController.text = _formatNum(salary.basicSalary);
    _housingController.text = _formatNum(salary.housingAllowance);
    _salarySynced = true;
  }

  EosbModel _buildModel() {
    return EosbModel(
      yearsOfService: int.tryParse(_yearsController.text.trim()) ?? 0,
      monthsOfService: int.tryParse(_monthsController.text.trim()) ?? 0,
      basicSalary: double.tryParse(_basicController.text.trim()) ?? 0,
      housingAllowance: double.tryParse(_housingController.text.trim()) ?? 0,
      contractType: _contractType,
      ticketCost: double.tryParse(_ticketController.text.trim()) ?? 0,
      ticketFrequency: _ticketFrequency,
    );
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    _syncFromSalaryIfNeeded();
    final model = _buildModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
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
          'نهاية الخدمة والمستحقات',
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
              _DisclaimerBanner(contractType: model.contractType),
              const SizedBox(height: 16),
              _TotalCard(
                total: model.totalEntitlements,
                currency: currency,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'مدة الخدمة',
                icon: Icons.work_history_outlined,
              ),
              Row(
                children: [
                  Expanded(
                    child: _IntField(
                      controller: _yearsController,
                      label: 'سنوات',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IntField(
                      controller: _monthsController,
                      label: 'أشهر (0–11)',
                      max: 11,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'نوع العقد',
                icon: Icons.description_outlined,
              ),
              SegmentedButton<EosbContractType>(
                segments: const [
                  ButtonSegment(
                    value: EosbContractType.fixed,
                    label: Text('محدد'),
                  ),
                  ButtonSegment(
                    value: EosbContractType.unlimited,
                    label: Text('غير محدد'),
                  ),
                ],
                selected: {_contractType},
                onSelectionChanged: (s) {
                  setState(() => _contractType = s.first);
                },
                style: _segmentStyle(),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'الأجر الشهري',
                icon: Icons.payments_outlined,
              ),
              _AmountField(
                controller: _basicController,
                label: 'الراتب الأساسي',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _AmountField(
                controller: _housingController,
                label: 'بدل السكن',
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    final s = ref.read(salaryNotifierProvider);
                    setState(() {
                      _basicController.text = _formatNum(s.basicSalary);
                      _housingController.text = _formatNum(s.housingAllowance);
                    });
                  },
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    'مزامنة من حاسبة الراتب',
                    style: GoogleFonts.cairo(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'تذكرة السفر',
                icon: Icons.flight_takeoff_rounded,
              ),
              _AmountField(
                controller: _ticketController,
                label: 'تكلفة التذكرة (ر.س)',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SegmentedButton<FlightTicketFrequency>(
                segments: const [
                  ButtonSegment(
                    value: FlightTicketFrequency.yearly,
                    label: Text('سنوي'),
                  ),
                  ButtonSegment(
                    value: FlightTicketFrequency.biannual,
                    label: Text('نصف سنوي'),
                  ),
                ],
                selected: {_ticketFrequency},
                onSelectionChanged: (s) {
                  setState(() => _ticketFrequency = s.first);
                },
                style: _segmentStyle(),
              ),
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'تفاصيل المستحقات',
                icon: Icons.receipt_long_outlined,
              ),
              _BreakdownCard(
                currency: currency,
                isDark: isDark,
                rows: [
                  _BreakdownRow(
                    label: 'مكافأة نهاية الخدمة (م. 84)',
                    value: model.endOfServiceAmount,
                    subtitle:
                        '${model.totalServiceYears.toStringAsFixed(1)} سنة · ${EosbModel.contractTypeLabel(model.contractType)}',
                  ),
                  _BreakdownRow(
                    label: 'بدل الإجازة (${model.annualVacationDays} يوم)',
                    value: model.vacationAllowance,
                    subtitle: model.totalServiceYears >= 5
                        ? '30 يوماً للموظف 5+ سنوات'
                        : '21 يوماً للموظف أقل من 5 سنوات',
                  ),
                  _BreakdownRow(
                    label: 'بدل تذكرة السفر',
                    value: model.flightTicketAllowance,
                    subtitle: EosbModel.ticketFrequencyLabel(
                      model.ticketFrequency,
                    ),
                  ),
                ],
              ),
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

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.contractType});

  final EosbContractType contractType;

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
          const Icon(Icons.info_outline, color: AppColors.info, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'الحساب وفق المادة 84 (انتهاء العقد أو إنهاء من صاحب العمل). '
              'عقد ${EosbModel.contractTypeLabel(contractType)}. '
              'حالات الاستقالة تخضع لنسب مختلفة بموجب المادة 85.',
              style: GoogleFonts.cairo(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.total,
    required this.currency,
    required this.isDark,
  });

  final double total;
  final NumberFormat currency;
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
            'إجمالي المستحقات',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currency.format(total),
            style: GoogleFonts.cairo(
              color: AppColors.goldBright,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'مكافأة + إجازة + تذكرة سفر',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.rows,
    required this.currency,
    required this.isDark,
  });

  final List<_BreakdownRow> rows;
  final NumberFormat currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(isDark: isDark),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 24,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
              ),
            rows[i].build(context, currency),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.subtitle,
  });

  final String label;
  final double value;
  final String? subtitle;

  Widget build(BuildContext context, NumberFormat currency) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          currency.format(value),
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.emerald,
          ),
        ),
      ],
    );
  }
}

class _IntField extends StatelessWidget {
  const _IntField({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.max = 99,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _MaxValueFormatter(max),
      ],
      onChanged: onChanged,
      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emerald, width: 2),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      onChanged: onChanged,
      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        suffixText: 'ر.س',
        suffixStyle: GoogleFonts.cairo(fontSize: 13),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emerald, width: 2),
        ),
      ),
    );
  }
}

class _MaxValueFormatter extends TextInputFormatter {
  _MaxValueFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    if (n > max) {
      return TextEditingValue(
        text: max.toString(),
        selection: TextSelection.collapsed(offset: max.toString().length),
      );
    }
    return newValue;
  }
}
