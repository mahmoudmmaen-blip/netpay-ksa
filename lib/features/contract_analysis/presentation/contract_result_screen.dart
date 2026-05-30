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
import 'package:netgulf/features/notifications/contract_reminder/contract_reminder_service.dart';
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

  static bool _shouldShowArticle77Link(ContractAnalysisResult result) {
    return result.risks.any(
      (r) => r.contains('شرط جزائي') || r.contains('فسخ'),
    );
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
          positiveCount: result.positivePoints.length,
          risksCount: result.risks.length,
          missingRightsCount: result.missingRights.length,
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
        if (result.contractDurationMonths != null) ...[
          const SizedBox(height: 16),
          _ContractExpiryReminderCard(
            contractDurationMonths: result.contractDurationMonths!,
          ),
        ],
        if (_shouldShowArticle77Link(result)) ...[
          const SizedBox(height: 16),
          _Article77PromoCard(
            onTap: () => context.push(AppRoutes.article77),
          ),
        ],
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
    required this.positiveCount,
    required this.risksCount,
    required this.missingRightsCount,
  });

  final int score;
  final int positiveCount;
  final int risksCount;
  final int missingRightsCount;

  static const _redScore = Color(0xFFE53935);
  static const _amberScore = Color(0xFFF9A825);
  static const _greenScore = Color(0xFF1D9E75);

  Color _scoreColor(int value) {
    if (value <= 4) return _redScore;
    if (value <= 7) return _amberScore;
    return _greenScore;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return GlassSurface(
      highlighted: true,
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, animatedScore, _) {
                final display = animatedScore.round().clamp(0, 10);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: animatedScore / 10,
                      strokeWidth: 10,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$display',
                          style: GoogleFonts.cairo(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: color,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/10',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تقييم العقد',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: '✅ $positiveCount نقطة إيجابية',
                color: _greenScore,
              ),
              _SummaryChip(
                label: '⚠️ $risksCount مخطر',
                color: _redScore,
              ),
              _SummaryChip(
                label: 'ℹ️ $missingRightsCount حق ناقص',
                color: _amberScore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContractExpiryReminderCard extends StatefulWidget {
  const _ContractExpiryReminderCard({
    required this.contractDurationMonths,
  });

  final int contractDurationMonths;

  @override
  State<_ContractExpiryReminderCard> createState() =>
      _ContractExpiryReminderCardState();
}

class _ContractExpiryReminderCardState extends State<_ContractExpiryReminderCard> {
  bool _scheduled = false;
  bool _loading = false;

  Future<void> _enableReminder() async {
    setState(() => _loading = true);

    final outcome = await ContractReminderService.scheduleExpiryReminder(
      widget.contractDurationMonths,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case ContractReminderScheduleResult.scheduled:
        setState(() => _scheduled = true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'تم تفعيل التنبيه ✓',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        );
      case ContractReminderScheduleResult.notSupportedOnWeb:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'التنبيهات غير مدعومة على الويب',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      case ContractReminderScheduleResult.dateInPast:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'موعد التنبيه في الماضي — مدة العقد قصيرة جداً',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      case ContractReminderScheduleResult.permissionDenied:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'لم يُمنح إذن الإشعارات',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      case ContractReminderScheduleResult.failed:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'تعذر جدولة التنبيه',
              style: GoogleFonts.cairo(),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scheduled) return const SizedBox.shrink();

    return GlassSurface(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تنبيه انتهاء العقد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'هل تريد تذكيراً قبل انتهاء عقدك بـ 30 يوماً؟',
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.45,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: FilledButton(
              onPressed: _loading ? null : _enableReminder,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'تفعيل التنبيه',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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

class _Article77PromoCard extends StatelessWidget {
  const _Article77PromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.emerald.withValues(alpha: 0.15),
                Colors.amber.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '⚖️ احسب تعويضك في حالة الفسخ التعسفي',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'احسب المادة 77',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
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
