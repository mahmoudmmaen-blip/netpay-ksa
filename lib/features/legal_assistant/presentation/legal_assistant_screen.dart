import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/services/premium_access.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/legal_assistant/providers/eosb_wizard_provider.dart';
import 'package:netgulf/features/legal_assistant/services/eosb_pdf_service.dart';

/// المساعد القانوني — حاسبة نهاية الخدمة الشاملة (offline).
class LegalAssistantScreen extends ConsumerWidget {
  const LegalAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المساعد القانوني',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'حاسبة نهاية الخدمة الشاملة',
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
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
          child: Column(
            children: [
              if (!wizard.showResults) _StepIndicator(current: wizard.stepIndex),
              Expanded(
                child: wizard.showResults
                    ? _ResultsView(isDark: isDark)
                    : _WizardBody(step: wizard.stepIndex, isDark: isDark),
              ),
              _BottomBar(showResults: wizard.showResults),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  static const _labels = [
    'نوع الإنهاء',
    'بيانات العقد',
    'تفاصيل إضافية',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i <= current;
          final isCurrent = i == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: active
                              ? AppColors.emerald
                              : AppColors.emerald.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.emerald
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < _labels.length - 1) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _WizardBody extends ConsumerWidget {
  const _WizardBody({required this.step, required this.isDark});

  final int step;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        switch (step) {
          0 => const _StepTermination(),
          1 => const _StepContract(),
          2 => const _StepExtras(),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _StepTermination extends ConsumerWidget {
  const _StepTermination();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    const options = <(EosbTerminationType, IconData)>[
      (EosbTerminationType.employerDismissalUnfair, Icons.gavel_rounded),
      (EosbTerminationType.employerDismissalValidReason, Icons.rule_rounded),
      (EosbTerminationType.employeeResignation, Icons.exit_to_app_rounded),
      (EosbTerminationType.contractExpiry, Icons.event_busy_rounded),
      (EosbTerminationType.mutualAgreement, Icons.handshake_rounded),
      (EosbTerminationType.retirementOrDeath, Icons.elderly_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'الخطوة 1: نوع إنهاء الخدمة',
          subtitle: 'اختر السبب الأقرب لحالتك',
        ),
        const SizedBox(height: 12),
        ...options.map((o) {
          final selected = wizard.terminationType == o.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassSurface(
              highlighted: selected,
              onTap: () => notifier.setTermination(o.$1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    o.$2,
                    color: selected ? AppColors.emerald : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      EosbModel.terminationTypeLabel(o.$1),
                      style: GoogleFonts.cairo(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.emerald),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StepContract extends ConsumerWidget {
  const _StepContract();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'الخطوة 2: بيانات العقد',
          subtitle: 'الدولة، المدة، والأجر',
        ),
        const SizedBox(height: 12),
        Text('الدولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CountryChip(
                country: GulfCountry.saudiArabia,
                selected: wizard.country == GulfCountry.saudiArabia,
                onTap: () => notifier.setCountry(GulfCountry.saudiArabia),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountryChip(
                country: GulfCountry.uae,
                selected: wizard.country == GulfCountry.uae,
                onTap: () => notifier.setCountry(GulfCountry.uae),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('مدة الخدمة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumField(
                label: 'سنوات',
                initial: wizard.years > 0 ? '${wizard.years}' : '',
                onChanged: (v) => notifier.setServiceDuration(
                  years: int.tryParse(v) ?? 0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumField(
                label: 'أشهر',
                initial: wizard.months > 0 ? '${wizard.months}' : '',
                onChanged: (v) => notifier.setServiceDuration(
                  months: (int.tryParse(v) ?? 0).clamp(0, 11),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumField(
                label: 'أيام',
                initial: wizard.days > 0 ? '${wizard.days}' : '',
                onChanged: (v) => notifier.setServiceDuration(
                  days: (int.tryParse(v) ?? 0).clamp(0, 364),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _NumField(
          label: 'الراتب الأساسي (${wizard.country.currencySymbol})',
          initial: wizard.basicSalary > 0 ? _fmt(wizard.basicSalary) : '',
          onChanged: (v) =>
              notifier.setSalaries(basic: double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 10),
        _NumField(
          label: 'بدل السكن (اختياري)',
          initial:
              wizard.housingAllowance > 0 ? _fmt(wizard.housingAllowance) : '',
          onChanged: (v) =>
              notifier.setSalaries(housing: double.tryParse(v) ?? 0),
        ),
        if (wizard.country == GulfCountry.uae)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'الإمارات: المكافأة تُحسب على الأجر الأساسي غالباً.',
              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.info),
            ),
          ),
        const SizedBox(height: 16),
        Text('نوع العقد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SegmentedButton<EosbContractType>(
          segments: const [
            ButtonSegment(
              value: EosbContractType.fixed,
              label: Text('محدد المدة'),
            ),
            ButtonSegment(
              value: EosbContractType.unlimited,
              label: Text('غير محدد'),
            ),
          ],
          selected: {wizard.contractType},
          onSelectionChanged: (s) => notifier.setContractType(s.first),
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);
}

class _StepExtras extends ConsumerWidget {
  const _StepExtras();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          title: 'الخطوة 3: تفاصيل إضافية',
          subtitle: 'إجازات، تذكرة، وإشعار الإنهاء',
        ),
        const SizedBox(height: 12),
        _NumField(
          label: 'الإجازات المتبقية (أيام)',
          initial:
              wizard.accruedLeaveDays > 0 ? '${wizard.accruedLeaveDays}' : '',
          onChanged: (v) =>
              notifier.setAccruedLeave(int.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 16),
        GlassSurface(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تذكرة الطيران (للوافدين)',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تضمين تذكرة سفر في الحساب',
                    style: GoogleFonts.cairo(fontSize: 14)),
                value: wizard.includeFlightTicket,
                activeThumbColor: AppColors.emerald,
                onChanged: (v) => notifier.setFlightTicket(include: v),
              ),
              if (wizard.includeFlightTicket) ...[
                _NumField(
                  label: 'تكلفة التذكرة التقديرية',
                  initial:
                      wizard.ticketCost > 0 ? '${wizard.ticketCost.round()}' : '',
                  onChanged: (v) => notifier.setFlightTicket(
                    include: true,
                    cost: double.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<FlightTicketFrequency>(
                  segments: [
                    ButtonSegment(
                      value: FlightTicketFrequency.yearly,
                      label: Text(
                        EosbModel.ticketFrequencyLabel(
                          FlightTicketFrequency.yearly,
                        ),
                        style: GoogleFonts.cairo(fontSize: 11),
                      ),
                    ),
                    ButtonSegment(
                      value: FlightTicketFrequency.biannual,
                      label: Text(
                        EosbModel.ticketFrequencyLabel(
                          FlightTicketFrequency.biannual,
                        ),
                        style: GoogleFonts.cairo(fontSize: 11),
                      ),
                    ),
                  ],
                  selected: {wizard.ticketFrequency},
                  onSelectionChanged: (s) =>
                      notifier.setTicketFrequency(s.first),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassSurface(
          padding: const EdgeInsets.all(14),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'تم تقديم إشعار الإنهاء وفق النظام',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'عدم الإشعار قد يؤثر على التعويضات',
              style: GoogleFonts.cairo(fontSize: 11),
            ),
            value: wizard.noticeProvided,
            activeThumbColor: AppColors.emerald,
            onChanged: notifier.setNoticeProvided,
          ),
        ),
      ],
    );
  }
}

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(eosbCalculationProvider);
    final currency = NumberFormat.currency(
      locale: model.country.currencyLocale,
      symbol: model.country.currencySymbol,
      decimalDigits: 2,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      children: [
        _TotalHeroCard(model: model, currency: currency, isDark: isDark),
        const SizedBox(height: 16),
        Text('جدول التفصيل',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        GlassSurface(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              _tableHeader(),
              ...model.breakdownRows.map((r) => _tableRow(r, currency)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('التفصيل القانوني',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 10),
        ...model.legalReferences.map(
          (ref) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassSurface(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.article,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ref.summary,
                    style: GoogleFonts.cairo(fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _LegalDisclaimer(),
        const SizedBox(height: 80),
      ],
    );
  }

  TableRow _tableHeader() => TableRow(
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.08),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text('البند',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text('المبلغ',
                textAlign: TextAlign.end,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          ),
        ],
      );

  TableRow _tableRow(EosbBreakdownRow row, NumberFormat currency) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            row.label,
            style: GoogleFonts.cairo(
              fontWeight: row.highlight ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            currency.format(row.amount),
            textAlign: TextAlign.end,
            style: GoogleFonts.cairo(
              fontWeight: row.highlight ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: row.highlight ? AppColors.emerald : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalHeroCard extends StatelessWidget {
  const _TotalHeroCard({
    required this.model,
    required this.currency,
    required this.isDark,
  });

  final EosbModel model;
  final NumberFormat currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: AppColors.brandGradient,
        boxShadow: AppColors.premiumCardGlow(isDark: isDark),
      ),
      child: Column(
        children: [
          Text(
            'الإجمالي المستحق',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currency.format(model.totalEntitlements),
            style: GoogleFonts.cairo(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.goldBright,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            model.terminationSummary,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'مكافأة نهاية الخدمة: ${currency.format(model.endOfServiceAmount)}',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.showResults});

  final bool showResults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    return GlassSurface(
      borderRadius: 0,
      blur: 8,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SafeArea(
        top: false,
        child: showResults
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _exportPdf(context, ref),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(
                        'تصدير PDF',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: notifier.reset,
                    child: Text(
                      'حساب جديد',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  if (wizard.stepIndex > 0)
                    TextButton(
                      onPressed: notifier.previousStep,
                      child: Text('السابق',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (!notifier.nextStep()) {
                        final msg = switch (wizard.stepIndex) {
                          0 => 'اختر نوع إنهاء الخدمة',
                          1 => 'أدخل مدة الخدمة والراتب الأساسي',
                          _ => 'أكمل الحقول المطلوبة',
                        };
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg, style: GoogleFonts.cairo()),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      wizard.stepIndex == 2 ? 'عرض النتيجة' : 'التالي',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final isPremium = await PremiumAccess.requirePremium(
      context,
      ref,
      feature: PremiumFeature.pdfExport,
    );
    if (!isPremium) {
      await PremiumAccess.showInterstitialAfterPdfAttempt(ref);
      return;
    }
    try {
      final model = ref.read(eosbCalculationProvider);
      await EosbPdfService.exportAndShare(model);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر تصدير PDF. حاول مرة أخرى.',
            style: GoogleFonts.cairo(),
          ),
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 18)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final GulfCountry country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      highlighted: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          '${country.flag} ${country.nameAr}',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _NumField extends StatefulWidget {
  const _NumField({
    required this.label,
    required this.onChanged,
    this.initial = '',
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _NumField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && widget.initial != _controller.text) {
      _controller.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
        ],
        onChanged: widget.onChanged,
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: GoogleFonts.cairo(fontSize: 13),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _LegalDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 20, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'تنبيه قانوني: هذه الحاسبة أداة تقديرية عامة وفق أنظمة العمل في '
              'السعودية والإمارات، ولا تُغني عن مراجعة العقد أو محامٍ أو الجهة '
              'المختصة — خاصة في الفصل لسبب مشروع أو النزاعات.',
              style: GoogleFonts.cairo(fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
