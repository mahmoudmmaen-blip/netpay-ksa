import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';
import 'package:netgulf/features/gosi/providers/gosi_calculator_provider.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// مقارنة عرضين وظيفيين — صافي الراتب بعد GOSI.
class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  final _offer1 = _OfferInputs();
  final _offer2 = _OfferInputs();
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPremiumAccess());
  }

  Future<void> _checkPremiumAccess() async {
    if (_gateChecked || !mounted) return;
    _gateChecked = true;

    if (ref.read(isPremiumProvider)) return;

    await showPremiumGate(context, feature: PremiumFeature.fullComparison);
    if (!mounted) return;
    if (!ref.read(isPremiumProvider)) {
      context.canPop() ? context.pop() : context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _offer1.dispose();
    _offer2.dispose();
    super.dispose();
  }

  GosiModel? _computeGosi(_OfferInputs offer) {
    final salary = ref.read(salaryNotifierProvider);
    final basic = double.tryParse(offer.basic.text.trim()) ?? 0;
    final housing = double.tryParse(offer.housing.text.trim()) ?? 0;
    final other = double.tryParse(offer.other.text.trim()) ?? 0;

    try {
      return GosiModel.fromSalaryForm(
        allowances: SalaryAllowances(
          basicSalary: basic,
          housingAllowance: housing,
          otherAllowances: other,
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
    final gosi1 = _computeGosi(_offer1);
    final gosi2 = _computeGosi(_offer2);
    final net1 = gosi1?.netSalary ?? 0;
    final net2 = gosi2?.netSalary ?? 0;
    final winner = net1 > net2 ? 1 : net2 > net1 ? 2 : 0;
    final diff = (net1 - net2).abs();

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
          'مقارنة العروض',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (winner != 0) ...[
                _WinnerBanner(
                  winnerLabel: winner == 1 ? 'العرض 1' : 'العرض 2',
                  diff: diff,
                  currency: currency,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _OfferColumn(
                      title: 'عرض 1',
                      inputs: _offer1,
                      gosi: gosi1,
                      currency: currency,
                      isWinner: winner == 1,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OfferColumn(
                      title: 'عرض 2',
                      inputs: _offer2,
                      gosi: gosi2,
                      currency: currency,
                      isWinner: winner == 2,
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'يُستخدم نظام GOSI والجنسية من إعدادات الشاشة الرئيسية.',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferInputs {
  final basic = TextEditingController(text: '10000');
  final housing = TextEditingController(text: '2500');
  final other = TextEditingController(text: '0');

  void dispose() {
    basic.dispose();
    housing.dispose();
    other.dispose();
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({
    required this.winnerLabel,
    required this.diff,
    required this.currency,
  });

  final String winnerLabel;
  final double diff;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: AppColors.success),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$winnerLabel أفضل',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'فرق صافي: ${currency.format(diff)} شهرياً',
                  style: GoogleFonts.cairo(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferColumn extends StatelessWidget {
  const _OfferColumn({
    required this.title,
    required this.inputs,
    required this.gosi,
    required this.currency,
    required this.isWinner,
    required this.onChanged,
  });

  final String title;
  final _OfferInputs inputs;
  final GosiModel? gosi;
  final NumberFormat currency;
  final bool isWinner;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isWinner ? AppColors.success : AppColors.emerald.withValues(alpha: 0.25);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isWinner ? 2.5 : 1),
        boxShadow: isWinner ? AppColors.cardShadow() : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isWinner ? AppColors.success : AppColors.emerald,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: inputs.basic,
            label: 'أساسي',
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
          _Field(
            controller: inputs.housing,
            label: 'سكن',
            onChanged: onChanged,
          ),
          const SizedBox(height: 8),
          _Field(
            controller: inputs.other,
            label: 'أخرى',
            onChanged: onChanged,
          ),
          const SizedBox(height: 16),
          if (gosi != null) ...[
            _ResultRow(
              label: 'الإجمالي',
              value: currency.format(gosi!.totalGross),
            ),
            _ResultRow(
              label: 'GOSI',
              value: currency.format(gosi!.employeeGosi),
            ),
            const Divider(height: 20),
            Text(
              'الصافي',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              currency.format(gosi!.netSalary),
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isWinner ? AppColors.success : AppColors.emerald,
              ),
            ),
          ] else
            Text(
              'أدخل قيماً صحيحة',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      onChanged: (_) => onChanged(),
      style: GoogleFonts.cairo(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 12)),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
