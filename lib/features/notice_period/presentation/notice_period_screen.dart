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
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_calculator.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_model.dart';
import 'package:netgulf/features/notice_period/providers/notice_period_provider.dart';

/// حاسبة مدة إشعار الإنهاء وتعويض عدم الإشعار — ٦ دول خليجية.
class NoticePeriodScreen extends ConsumerWidget {
  const NoticePeriodScreen({
    super.key,
    this.embeddedInHub = false,
  });

  /// داخل تبويب شاشة EOSB — بدون Scaffold منفصل.
  final bool embeddedInHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(noticePeriodProvider);
    final notifier = ref.read(noticePeriodProvider.notifier);
    final currency = NumberFormat.currency(
      locale: model.country.currencyLocale,
      symbol: model.country.currencySymbol,
      decimalDigits: 2,
    );

    final body = _NoticePeriodBody(
      model: model,
      notifier: notifier,
      currency: currency,
    );

    if (embeddedInHub) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(top: false, child: body),
      );
    }

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
              'إشعار الإنهاء',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'مدة الإشعار + تعويض عدم الإشعار',
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
        child: SafeArea(child: body),
      ),
    );
  }
}

class _NoticePeriodBody extends StatelessWidget {
  const _NoticePeriodBody({
    required this.model,
    required this.notifier,
    required this.currency,
  });

  final NoticePeriodModel model;
  final NoticePeriodNotifier notifier;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final showContractType = model.country == GulfCountry.saudiArabia;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'اختر دولة العمل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        EosbCountryGrid(
          selected: model.country,
          onSelected: (c) {
            HapticFeedback.selectionClick();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifier.setCountry(c);
            });
          },
        ),
        const SizedBox(height: 12),
        GlassSurface(
          borderRadius: 14,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gavel_rounded, color: AppColors.emerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      model.legalReference,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NoticePeriodCalculator.rulesSummary(model.country),
                      style: GoogleFonts.cairo(fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'سنوات الخدمة: ${model.totalServiceYears.toStringAsFixed(1)} سنة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        Slider(
          value: model.totalServiceYears.clamp(0, 30),
          min: 0,
          max: 30,
          divisions: 60,
          activeColor: AppColors.emerald,
          label: model.totalServiceYears.toStringAsFixed(1),
          onChanged: notifier.setYears,
        ),
        HomeSalaryField(
          key: ValueKey('notice-salary-${model.country.name}'),
          label: 'الراتب الأساسي الشهري',
          value: model.monthlyBasicSalary,
          currencySymbol: currency.currencySymbol,
          countryFlag: model.country.flag,
          onChanged: notifier.setSalary,
        ),
        if (showContractType) ...[
          const SizedBox(height: 8),
          Text(
            'نوع العقد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SegmentedButton<EosbContractType>(
            segments: [
              ButtonSegment(
                value: EosbContractType.unlimited,
                label: Text(
                  'غير محدد',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ),
              ButtonSegment(
                value: EosbContractType.fixed,
                label: Text(
                  'محدد',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ),
            ],
            selected: {model.contractType},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) notifier.setContractType(s.first);
            },
          ),
        ],
        const SizedBox(height: 16),
        GlassSurface(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'هل قُدّم إشعار الإنهاء؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'فعّل إذا أُبلغ الموظف رسمياً قبل إنهاء العقد',
              style: GoogleFonts.cairo(fontSize: 11, color: muted),
            ),
            value: model.noticeWasGiven,
            activeThumbColor: AppColors.emerald,
            onChanged: notifier.setNoticeGiven,
          ),
        ),
        if (model.noticeWasGiven) ...[
          const SizedBox(height: 8),
          GlassSurface(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'أيام الإشعار المقدّمة فعلياً: ${model.daysNoticeGiven}',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: model.daysNoticeGiven.clamp(0, 180).toDouble(),
                  min: 0,
                  max: 180,
                  divisions: 180,
                  activeColor: AppColors.emerald,
                  label: '${model.daysNoticeGiven}',
                  onChanged: (v) => notifier.setDaysGiven(v.round()),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _ResultCard(model: model, currency: currency),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.model,
    required this.currency,
  });

  final NoticePeriodModel model;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final hasSalary = model.monthlyBasicSalary > 0;

    return GlassSurface(
      highlighted: true,
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                color: AppColors.emerald,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'نتيجة إشعار الإنهاء — ${model.country.nameAr}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ResultRow(
            label: 'أيام الإشعار المطلوبة قانوناً',
            value: '${model.requiredNoticeDays} يوم',
          ),
          if (model.noticeWasGiven)
            _ResultRow(
              label: 'أيام الإشعار المقدّمة',
              value: '${model.daysNoticeGiven} يوم',
            ),
          _ResultRow(
            label: 'أيام الإشعار الناقصة',
            value: '${model.missingDays} يوم',
            highlight: model.missingDays > 0,
          ),
          const Divider(height: 24),
          _ResultRow(
            label: 'تعويض عدم الإشعار',
            value: hasSalary
                ? currency.format(model.compensationAmount)
                : '—',
            bold: true,
            highlight: true,
          ),
          if (hasSalary && model.dailyWage > 0) ...[
            const SizedBox(height: 8),
            Text(
              'الأجر اليومي: ${currency.format(model.dailyWage)}',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              model.legalReference,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: GoogleFonts.cairo(fontSize: 13)),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? AppColors.emerald : null,
            ),
          ),
        ],
      ),
    );
  }
}
