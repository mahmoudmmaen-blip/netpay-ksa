import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/eosb_prefill_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/contract_analysis/models/contract_analysis_result.dart';
import 'package:share_plus/share_plus.dart';

/// نتائج تحليل عقد العمل.
class ContractResultScreen extends ConsumerWidget {
  const ContractResultScreen({
    super.key,
    required this.result,
    this.embeddedInHub = false,
  });

  final ContractAnalysisResult result;
  final bool embeddedInHub;

  Color _scoreColor(int score) {
    if (score <= 4) return Colors.red.shade600;
    if (score <= 7) return Colors.amber.shade700;
    return AppColors.emerald;
  }

  String _currencySymbol(String code) => switch (code.toUpperCase()) {
        'SAR' => 'ر.س',
        'AED' => 'د.إ',
        'QAR' => 'ر.ق',
        'KWD' => 'د.ك',
        'BHD' => 'د.ب',
        'OMR' => 'ر.ع',
        _ => code,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreColor = _scoreColor(result.overallScore);
    final locale = result.country.currencyLocale;
    final symbol = _currencySymbol(result.currency);
    final currency = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    );

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _ScoreCard(
          score: result.overallScore,
          color: scoreColor,
          country: result.country,
        ),
        const SizedBox(height: 16),
        GlassSurface(
          highlighted: true,
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'الملخص المالي',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 12),
              _Row(
                label: 'الراتب الأساسي',
                value: result.salaryBasic != null
                    ? currency.format(result.salaryBasic)
                    : '—',
              ),
              _Row(
                label: 'إجمالي الراتب',
                value: result.salaryTotal != null
                    ? currency.format(result.salaryTotal)
                    : '—',
              ),
              _Row(label: 'العملة', value: result.currency),
            ],
          ),
        ),
        if (result.allowances.isNotEmpty) ...[
          const SizedBox(height: 12),
          GlassSurface(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'البدلات',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...result.allowances.map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(a.name, style: GoogleFonts.cairo(fontSize: 13)),
                        ),
                        Text(
                          currency.format(a.amount),
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _BulletSection(
          title: 'نقاط إيجابية',
          items: result.positivePoints,
          icon: Icons.check_circle_rounded,
          color: AppColors.emerald,
        ),
        const SizedBox(height: 12),
        _BulletSection(
          title: 'مخاطر',
          items: result.risks,
          icon: Icons.warning_rounded,
          color: Colors.red.shade500,
          borderColor: Colors.red.shade200,
        ),
        const SizedBox(height: 12),
        _BulletSection(
          title: 'حقوق ناقصة',
          items: result.missingRights,
          icon: Icons.info_rounded,
          color: Colors.orange.shade700,
          borderColor: Colors.orange.shade200,
        ),
        const SizedBox(height: 12),
        GlassSurface(
          borderRadius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تفاصيل العقد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 10),
              _Row(
                label: 'مدة العقد',
                value: result.contractDurationMonths != null
                    ? '${result.contractDurationMonths} شهر'
                    : '—',
              ),
              _Row(
                label: 'إشعار الإنهاء',
                value: result.noticePeriodDays != null
                    ? '${result.noticePeriodDays} يوم'
                    : '—',
              ),
              _Row(
                label: 'الإجازة السنوية',
                value: result.annualLeaveDays != null
                    ? '${result.annualLeaveDays} يوم'
                    : '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Share.share(result.shareSummary),
          icon: const Icon(Icons.share_rounded),
          label: Text('مشاركة الملخص', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: result.salaryBasic != null && result.salaryBasic! > 0
                ? () {
                    ref.read(eosbPrefillProvider.notifier).state = EosbPrefillData(
                      country: result.country,
                      basicSalary: result.salaryBasic!,
                    );
                    context.push(AppRoutes.eosb);
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.card_giftcard_rounded),
            label: Text(
              'احسب نهاية الخدمة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassSurface(
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          child: Text(
            'هذا تحليل تقديري — راجع محامياً للتأكيد.',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'نتيجة التحليل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(child: body),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.score,
    required this.color,
    required this.country,
  });

  final int score;
  final Color color;
  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      highlighted: true,
      borderRadius: 22,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'تقييم العقد — ${country.nameAr}',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            height: 140,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 10),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: GoogleFonts.cairo(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Text(
                          '/ 10',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(fontSize: 13)),
          Text(
            value,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
    this.borderColor,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: borderColor != null
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor!, width: 1.5),
              )
            : const BoxDecoration(),
        child: Padding(
          padding: borderColor != null ? const EdgeInsets.all(10) : EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t, style: GoogleFonts.cairo(fontSize: 13, height: 1.45)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
