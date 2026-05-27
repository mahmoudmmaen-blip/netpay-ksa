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
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/legal_assistant/providers/eosb_calculator_provider.dart';
import 'package:netgulf/features/legal_assistant/services/eosb_pdf_service.dart';

/// المساعد القانوني — حاسبة نهاية الخدمة الشاملة (offline).
class LegalAssistantScreen extends ConsumerStatefulWidget {
  const LegalAssistantScreen({super.key});

  @override
  ConsumerState<LegalAssistantScreen> createState() =>
      _LegalAssistantScreenState();
}

class _LegalAssistantScreenState extends ConsumerState<LegalAssistantScreen> {
  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => wizard.showResults
              ? ref.read(eosbWizardProvider.notifier).previousStep()
              : (context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.home)),
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
          child: wizard.showResults
              ? _ResultsView(isDark: isDark)
              : _WizardStepper(isDark: isDark),
        ),
      ),
    );
  }
}

class _WizardStepper extends ConsumerWidget {
  const _WizardStepper({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.emerald,
                  ),
            ),
            child: Stepper(
              type: StepperType.vertical,
              currentStep: wizard.stepIndex,
              onStepTapped: notifier.goToStep,
              controlsBuilder: (_, _) => const SizedBox.shrink(),
              steps: [
                Step(
                  state: _stepState(0, wizard.stepIndex),
                  isActive: wizard.stepIndex >= 0,
                  title: Text(
                    'نوع الإنهاء',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'فصل · استقالة · انتهاء عقد · تراضي',
                    style: GoogleFonts.cairo(fontSize: 11),
                  ),
                  content: const _StepTermination(),
                ),
                Step(
                  state: _stepState(1, wizard.stepIndex),
                  isActive: wizard.stepIndex >= 1,
                  title: Text(
                    'بيانات العقد',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'الدولة · المدة · الراتب والبدلات',
                    style: GoogleFonts.cairo(fontSize: 11),
                  ),
                  content: const _StepContract(),
                ),
                Step(
                  state: _stepState(2, wizard.stepIndex),
                  isActive: wizard.stepIndex >= 2,
                  title: Text(
                    'تفاصيل إضافية',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'إجازات · تذكرة · إشعار',
                    style: GoogleFonts.cairo(fontSize: 11),
                  ),
                  content: const _StepExtras(),
                ),
              ],
            ),
          ),
        ),
        _WizardBottomBar(stepIndex: wizard.stepIndex),
      ],
    );
  }

  StepState _stepState(int step, int current) {
    if (current > step) return StepState.complete;
    if (current == step) return StepState.editing;
    return StepState.indexed;
  }
}

class _WizardBottomBar extends ConsumerWidget {
  const _WizardBottomBar({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(eosbWizardProvider.notifier);

    return GlassSurface(
      borderRadius: 0,
      blur: 8,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          if (stepIndex > 0)
            TextButton(
              onPressed: notifier.previousStep,
              child: Text(
                'السابق',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              if (!notifier.nextStep()) {
                final msg = switch (stepIndex) {
                  0 => 'اختر نوع إنهاء الخدمة',
                  1 => 'أدخل مدة الخدمة والراتب الأساسي',
                  _ => 'أكمل الحقول المطلوبة',
                };
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text(
              stepIndex == 2 ? 'عرض النتيجة' : 'التالي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// فئات الإنهاء الرئيسية (الخطوة 1).
enum _TerminationCategory {
  dismissal,
  resignation,
  contractEnd,
  mutual,
}

extension _TerminationCategoryX on _TerminationCategory {
  String get label => switch (this) {
        _TerminationCategory.dismissal => 'فصل من صاحب العمل',
        _TerminationCategory.resignation => 'استقالة الموظف',
        _TerminationCategory.contractEnd => 'انتهاء العقد',
        _TerminationCategory.mutual => 'اتفاق بالتراضي',
      };

  IconData get icon => switch (this) {
        _TerminationCategory.dismissal => Icons.gavel_rounded,
        _TerminationCategory.resignation => Icons.exit_to_app_rounded,
        _TerminationCategory.contractEnd => Icons.event_busy_rounded,
        _TerminationCategory.mutual => Icons.handshake_rounded,
      };

  EosbTerminationType get type => switch (this) {
        _TerminationCategory.dismissal =>
          EosbTerminationType.employerDismissalUnfair,
        _TerminationCategory.resignation =>
          EosbTerminationType.employeeResignation,
        _TerminationCategory.contractEnd => EosbTerminationType.contractExpiry,
        _TerminationCategory.mutual => EosbTerminationType.mutualAgreement,
      };
}

class _StepTermination extends ConsumerWidget {
  const _StepTermination();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    _TerminationCategory? selectedCategory;
    for (final c in _TerminationCategory.values) {
      if (wizard.terminationType == c.type ||
          (c == _TerminationCategory.dismissal &&
              (wizard.terminationType ==
                      EosbTerminationType.employerDismissalUnfair ||
                  wizard.terminationType ==
                      EosbTerminationType.employerDismissalValidReason))) {
        selectedCategory = c;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._TerminationCategory.values.map((cat) {
          final selected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassSurface(
              highlighted: selected,
              onTap: () => notifier.selectTerminationCategory(cat.type),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(cat.icon, color: selected ? AppColors.emerald : null),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.label,
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
        if (selectedCategory == _TerminationCategory.dismissal) ...[
          const SizedBox(height: 8),
          GlassSurface(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'نوع الفصل',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text('تعسفي', style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('سبب مشروع', style: GoogleFonts.cairo(fontSize: 12)),
                    ),
                  ],
                  selected: {wizard.dismissalIsValidReason},
                  onSelectionChanged: (s) =>
                      notifier.setDismissalValidReason(s.first),
                ),
              ],
            ),
          ),
        ],
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
        Text('مدة الخدمة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumField(
                label: 'سنوات',
                initial: wizard.years > 0 ? '${wizard.years}' : '',
                onChanged: (v) =>
                    notifier.setServiceDuration(years: int.tryParse(v) ?? 0),
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
          onChanged: (v) => notifier.setSalaries(basic: double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 10),
        _NumField(
          label: 'بدل السكن',
          initial:
              wizard.housingAllowance > 0 ? _fmt(wizard.housingAllowance) : '',
          onChanged: (v) =>
              notifier.setSalaries(housing: double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 10),
        _NumField(
          label: 'بدلات أخرى (اختياري)',
          initial:
              wizard.otherAllowances > 0 ? _fmt(wizard.otherAllowances) : '',
          onChanged: (v) =>
              notifier.setSalaries(other: double.tryParse(v) ?? 0),
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
        Text('نوع العقد', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SegmentedButton<EosbContractType>(
          segments: const [
            ButtonSegment(value: EosbContractType.fixed, label: Text('محدد')),
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
        _NumField(
          label: 'الإجازات المتبقية (أيام)',
          initial:
              wizard.accruedLeaveDays > 0 ? '${wizard.accruedLeaveDays}' : '',
          onChanged: (v) => notifier.setAccruedLeave(int.tryParse(v) ?? 0),
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
                title: Text('تضمين تذكرة سفر',
                    style: GoogleFonts.cairo(fontSize: 14)),
                value: wizard.includeFlightTicket,
                activeThumbColor: AppColors.emerald,
                onChanged: (v) => notifier.setFlightTicket(include: v),
              ),
              if (wizard.includeFlightTicket) ...[
                _NumField(
                  label: 'تكلفة التذكرة التقديرية',
                  initial: wizard.ticketCost > 0
                      ? '${wizard.ticketCost.round()}'
                      : '',
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
              'تم تقديم إشعار الإنهاء',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'عدم الإشعار قد يؤثر على التعويضات (م. 75)',
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
    final result = ref.watch(eosbCalculatorProvider);
    final model = result.input;
    final currency = NumberFormat.currency(
      locale: model.country.currencyLocale,
      symbol: model.country.currencySymbol,
      decimalDigits: 2,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              _TotalHeroCard(result: result, currency: currency, isDark: isDark),
              const SizedBox(height: 20),
              Text(
                'تفصيل المستحقات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ...result.components.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ComponentCard(item: c, currency: currency),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'المراجع القانونية',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...result.legalReferences.map(
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
              const _LegalDisclaimer(),
            ],
          ),
        ),
        _ResultsBottomBar(),
      ],
    );
  }
}

class _TotalHeroCard extends StatelessWidget {
  const _TotalHeroCard({
    required this.result,
    required this.currency,
    required this.isDark,
  });

  final EosbCalculationResult result;
  final NumberFormat currency;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final model = result.input;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.brandGradient,
        boxShadow: AppColors.premiumCardGlow(isDark: isDark),
      ),
      child: Column(
        children: [
          Text(
            result.countryLabel,
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'إجمالي المستحقات',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currency.format(result.totalEntitlements),
              style: GoogleFonts.cairo(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: AppColors.goldBright,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              model.terminationSummary,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({
    required this.item,
    required this.currency,
  });

  final EosbComponentItem item;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      highlighted: item.isPrimary,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _iconFor(item.id),
              color: AppColors.emerald,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleAr,
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (item.subtitleAr != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitleAr!,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            currency.format(item.amount),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: item.isPrimary ? AppColors.emerald : null,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
        'eos' => Icons.card_giftcard_rounded,
        'vacation' => Icons.beach_access_rounded,
        'leave' => Icons.event_available_rounded,
        'ticket' => Icons.flight_rounded,
        _ => Icons.payments_rounded,
      };
}

class _ResultsBottomBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(eosbWizardProvider.notifier);

    return GlassSurface(
      borderRadius: 0,
      blur: 8,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _exportPdf(context, ref),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                label: Text(
                  'تصدير PDF',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
      final result = ref.read(eosbCalculatorProvider);
      await EosbPdfService.exportAndShare(result);
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
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 14),
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
    if (oldWidget.initial != widget.initial &&
        widget.initial != _controller.text) {
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
  const _LegalDisclaimer();

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
              'تنبيه قانوني: أداة تقديرية عامة وفق أنظمة العمل في السعودية والإمارات. '
              'لا تُغني عن مراجعة العقد أو محامٍ أو الجهة المختصة.',
              style: GoogleFonts.cairo(fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
