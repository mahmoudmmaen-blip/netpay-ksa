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
      floatingActionButton: wizard.showResults
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(eosbWizardProvider.notifier).reset(),
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'حساب جديد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: wizard.showResults
                ? _ResultsView(
                    key: const ValueKey('eosb_results'),
                    isDark: isDark,
                  )
                : _WizardStepper(
                    key: const ValueKey('eosb_wizard'),
                    isDark: isDark,
                  ),
          ),
        ),
      ),
    );
  }
}

/// معالج 3 خطوات — خطوة واحدة ظاهرة في كل مرة.
class _WizardStepper extends ConsumerStatefulWidget {
  const _WizardStepper({super.key, required this.isDark});

  final bool isDark;

  @override
  ConsumerState<_WizardStepper> createState() => _WizardStepperState();
}

class _WizardStepperState extends ConsumerState<_WizardStepper> {

  static const _stepTitles = [
  'نوع إنهاء الخدمة',
  'بيانات العقد',
  'تفاصيل إضافية',
  ];

  static const _stepSubtitles = [
    'اختر السبب الأقرب لوضعك',
    'السعودية أو الإمارات · المدة والأجر',
    'إجازات · تذكرة · إشعار الإنهاء',
  ];

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    final step = wizard.stepIndex.clamp(0, 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _StepProgressDots(current: step),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _WizardStepHeader(
            stepNumber: step + 1,
            title: _stepTitles[step],
            subtitle: _stepSubtitles[step],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: SingleChildScrollView(
              key: ValueKey<int>(step),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: switch (step) {
                0 => _StepTermination(key: const ValueKey('s0')),
                1 => _StepContract(key: const ValueKey('s1')),
                _ => _StepExtras(key: const ValueKey('s2')),
              },
            ),
          ),
        ),
        _WizardBottomBar(stepIndex: step),
      ],
    );
  }
}

class _WizardStepHeader extends StatelessWidget {
  const _WizardStepHeader({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
  });

  final int stepNumber;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            boxShadow: AppColors.cardShadow(
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$stepNumber',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// نقاط تقدم أعلى المعالج.
class _StepProgressDots extends StatelessWidget {
  const _StepProgressDots({required this.current});

  final int current;

  static const _labels = ['الإنهاء', 'العقد', 'التفاصيل'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i <= current;
        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                height: 4,
                margin: EdgeInsets.only(left: i > 0 ? 4 : 0, right: i < 2 ? 4 : 0),
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
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                  color: i == current
                      ? AppColors.emerald
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _WizardBottomBar extends ConsumerWidget {
  const _WizardBottomBar({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);
    final isLastStep = stepIndex == EosbWizardState.totalSteps - 1;
    final canAdvance = wizard.canAdvanceFromCurrentStep;
    final validationMsg = wizard.validationMessageForStep(stepIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (wizard.canShowLivePreview) ...[
          const _LivePreviewBar(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: _InputsSummaryCard(),
          ),
        ],
        if (validationMsg != null && !canAdvance)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              validationMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        GlassSurface(
          borderRadius: 0,
          blur: 8,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: stepIndex > 0 ? notifier.previousStep : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  'السابق',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: canAdvance
                    ? () {
                        final error = isLastStep
                            ? wizard.validationBeforeResults()
                            : notifier.validateCurrentStep();
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error, style: GoogleFonts.cairo()),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (isLastStep) {
                          if (!notifier.finishWizard() && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تعذّر عرض النتيجة — راجع البيانات المطلوبة',
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } else {
                          notifier.nextStep();
                        }
                      }
                    : null,
                icon: Icon(
                  isLastStep ? Icons.calculate_rounded : Icons.arrow_back_rounded,
                  size: 18,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  disabledBackgroundColor:
                      AppColors.emerald.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                label: Text(
                  isLastStep ? 'عرض النتيجة' : 'التالي',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// معاينة مباشرة — تتحدث فوراً مع [eosbCalculatorProvider].
class _LivePreviewBar extends ConsumerWidget {
  const _LivePreviewBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(eosbCalculatorProvider);
    final lines = ref.watch(eosbPreviewLinesProvider);
    final currency = NumberFormat.currency(
      locale: result.input.country.currencyLocale,
      symbol: result.input.country.currencySymbol,
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: GlassSurface(
        highlighted: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppColors.emerald),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'معاينة الإجمالي (تقديرية)',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  currency.format(result.totalEntitlements),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          line.labelAr,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      Text(
                        currency.format(line.amount),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// خيارات الخطوة 1 — أزرار اختيار.
const _terminationRadioOptions = <(EosbTerminationType, String, IconData)>[
  (
    EosbTerminationType.employerDismissalUnfair,
    'فصل تعسفي',
    Icons.gavel_rounded,
  ),
  (
    EosbTerminationType.employerDismissalValidReason,
    'فصل لسبب مشروع',
    Icons.rule_rounded,
  ),
  (
    EosbTerminationType.employeeResignation,
    'استقالة الموظف',
    Icons.exit_to_app_rounded,
  ),
  (
    EosbTerminationType.contractExpiry,
    'انتهاء العقد',
    Icons.event_busy_rounded,
  ),
  (
    EosbTerminationType.mutualAgreement,
    'اتفاق بالتراضي',
    Icons.handshake_rounded,
  ),
];

class _StepTermination extends ConsumerWidget {
  const _StepTermination({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);
    final groupValue = wizard.resolvedTermination;

    return GlassSurface(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RadioGroup<EosbTerminationType>(
        groupValue: groupValue,
        onChanged: (v) {
          if (v != null) notifier.setTerminationType(v);
        },
        child: Column(
          children: _terminationRadioOptions.map((opt) {
            final selected = groupValue == opt.$1;
            return RadioListTile<EosbTerminationType>(
              value: opt.$1,
              activeColor: AppColors.emerald,
              selected: selected,
              title: Text(
                opt.$2,
                style: GoogleFonts.cairo(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              secondary: Icon(
                opt.$3,
                color: selected ? AppColors.emerald : null,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StepContract extends ConsumerStatefulWidget {
  const _StepContract({super.key});

  @override
  ConsumerState<_StepContract> createState() => _StepContractState();
}

class _StepContractState extends ConsumerState<_StepContract> {
  late final TextEditingController _yearsCtrl;
  late final TextEditingController _monthsCtrl;
  late final TextEditingController _basicCtrl;
  late final TextEditingController _housingCtrl;

  static int _parseNonNegativeInt(String raw) {
    final t = raw.trim();
    final v = int.tryParse(t) ?? 0;
    if (v < 0) return 0;
    return v;
  }

  static double _parseNonNegativeDouble(String raw) {
    // Allow user to paste formatted numbers: "12,000" / "12 000"
    final t = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    final v = double.tryParse(t) ?? 0;
    if (v < 0) return 0;
    return v;
  }

  @override
  void initState() {
    super.initState();
    final w = ref.read(eosbWizardProvider);
    _yearsCtrl = TextEditingController(text: '${w.years}');
    _monthsCtrl = TextEditingController(text: '${w.months}');
    _basicCtrl = TextEditingController(
      text: w.basicSalary > 0 ? _fmt(w.basicSalary) : '',
    );
    _housingCtrl = TextEditingController(
      text: w.housingAllowance > 0 ? _fmt(w.housingAllowance) : '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pushToProvider();
    });
  }

  @override
  void dispose() {
    _yearsCtrl.dispose();
    _monthsCtrl.dispose();
    _basicCtrl.dispose();
    _housingCtrl.dispose();
    super.dispose();
  }

  void _pushToProvider() {
    final notifier = ref.read(eosbWizardProvider.notifier);
    notifier.setServiceDuration(
      years: _parseNonNegativeInt(_yearsCtrl.text),
      months: _parseNonNegativeInt(_monthsCtrl.text),
    );
    notifier.setSalaries(
      basic: _parseNonNegativeDouble(_basicCtrl.text),
      housing: _parseNonNegativeDouble(_housingCtrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);
    final currencySuffix =
        wizard.country == GulfCountry.saudiArabia ? 'ريال' : 'درهم';
    final showFieldErrors = !wizard.canProceedStep1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('الدولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SegmentedButton<GulfCountry>(
          segments: [
            ButtonSegment(
              value: GulfCountry.saudiArabia,
              label: Text(
                'السعودية',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              icon: const Text('🇸🇦'),
            ),
            ButtonSegment(
              value: GulfCountry.uae,
              label: Text(
                'الإمارات',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              icon: const Text('🇦🇪'),
            ),
          ],
          selected: {wizard.country},
          onSelectionChanged: (s) => notifier.setCountry(s.first),
        ),
        const SizedBox(height: 10),
        _CountryLawChip(country: wizard.country),
        const SizedBox(height: 16),
        GlassSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EosbTextField(
                controller: _yearsCtrl,
                label: 'عدد السنوات',
                hint: 'مثال: 5',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: showFieldErrors ? wizard.serviceYearsFieldError : null,
                onChanged: (_) => _pushToProvider(),
              ),
              const SizedBox(height: 12),
              _EosbTextField(
                controller: _monthsCtrl,
                label: 'عدد الشهور الإضافية',
                hint: 'من 0 إلى 11',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText:
                    showFieldErrors ? wizard.serviceMonthsFieldError : null,
                onChanged: (_) => _pushToProvider(),
              ),
              const SizedBox(height: 12),
              _EosbTextField(
                controller: _basicCtrl,
                label: 'الراتب الأساسي',
                hint: 'مثال: 12000',
                suffixText: currencySuffix,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d., ]')),
                ],
                errorText: showFieldErrors ? wizard.basicSalaryFieldError : null,
                onChanged: (_) => _pushToProvider(),
              ),
              const SizedBox(height: 12),
              _EosbTextField(
                controller: _housingCtrl,
                label: 'بدل السكن (اختياري)',
                hint: 'اتركه فارغاً إن لم يوجد',
                suffixText: currencySuffix,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d., ]')),
                ],
                onChanged: (_) => _pushToProvider(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);
}

class _StepExtras extends ConsumerStatefulWidget {
  const _StepExtras({super.key});

  @override
  ConsumerState<_StepExtras> createState() => _StepExtrasState();
}

class _StepExtrasState extends ConsumerState<_StepExtras> {
  late final TextEditingController _leaveCtrl;

  @override
  void initState() {
    super.initState();
    final days = ref.read(eosbWizardProvider).accruedLeaveDays;
    _leaveCtrl = TextEditingController(text: '$days');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(eosbWizardProvider.notifier).setAccruedLeave(
              int.tryParse(_leaveCtrl.text) ?? 0,
            );
      }
    });
  }

  @override
  void dispose() {
    _leaveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSurface(
          padding: const EdgeInsets.all(16),
          child: _EosbTextField(
            controller: _leaveCtrl,
            label: 'عدد أيام الإجازات المتبقية',
            hint: '0 إن لم يوجد رصيد',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) => notifier.setAccruedLeave(
              (int.tryParse(v) ?? 0).clamp(0, 90),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SwitchListTile(
            title: Text(
              'هل تستحق تذكرة طيران؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'تقدير سنوي: ${EosbWizardNotifier.yearlyTicketEstimateFor(wizard.country).round()} ${wizard.country.currencySymbol}',
              style: GoogleFonts.cairo(fontSize: 11),
            ),
            value: wizard.includeFlightTicket,
            activeThumbColor: AppColors.emerald,
            onChanged: (v) => notifier.setFlightTicket(include: v),
          ),
        ),
        if (wizard.terminationType == EosbTerminationType.mutualAgreement) ...[
          const SizedBox(height: 12),
          GlassSurface(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'نسبة الاتفاق على المكافأة',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${wizard.mutualAgreementPercent.round()}%',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: wizard.mutualAgreementPercent,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.emerald,
                  label: '${wizard.mutualAgreementPercent.round()}%',
                  onChanged: notifier.setMutualAgreementPercent,
                ),
                Text(
                  'تُطبَّق على أساس المادة 84 (السعودية) أو 51 (الإمارات)',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        GlassSurface(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SwitchListTile(
            title: Text(
              'هل تم تقديم إشعار الإنهاء؟',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'عدم الإشعار قد يؤثر على التعويض (م. 75)',
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

/// شارة نظام العمل حسب الدولة.
class _CountryLawChip extends StatelessWidget {
  const _CountryLawChip({required this.country});

  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    final text = country == GulfCountry.saudiArabia
        ? '🇸🇦 نظام العمل السعودي — المواد 84 و 85'
        : '🇦🇪 قانون العمل الإماراتي — المادة 51';
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.balance_rounded, color: AppColors.emerald, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsView extends ConsumerWidget {
  const _ResultsView({super.key, required this.isDark});

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
            children: [
              _TotalHeroCard(result: result, currency: currency, isDark: isDark),
              const SizedBox(height: 14),
              const _InputsSummaryCard(),
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

/// ملخص المدخلات — يتحدث فوراً مع [eosbCalculatorProvider].
class _InputsSummaryCard extends ConsumerWidget {
  const _InputsSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(eosbCalculatorProvider);
    final m = result.input;
    final currency = m.country.currencySymbol;
    final factor = result.resignationFactorApplied;
    final awardPct = result.appliedAwardPercent;
    final rows = <(String, String)>[
      ('الدولة', '${m.country.flag} ${m.country.nameAr}'),
      ('نوع الإنهاء', m.terminationSummary),
      ('نوع العقد', EosbModel.contractTypeLabel(m.contractType)),
      (
        'مدة الخدمة',
        '${m.totalServiceYears.toStringAsFixed(1)} سنة '
        '(${m.yearsOfService}س ${m.monthsOfService}ش)',
      ),
      ('الراتب الأساسي', '${m.basicSalary.round()} $currency'),
      if (m.housingAllowance > 0)
        ('بدل السكن', '${m.housingAllowance.round()} $currency'),
      if (m.otherAllowances > 0)
        ('بدلات أخرى', '${m.otherAllowances.round()} $currency'),
      if (factor != null)
        ('نسبة الاستقالة (م. 85)', '${(factor * 100).round()}%'),
      if (awardPct != null)
        ('نسبة المكافأة المطبّقة', '${awardPct.round()}%'),
      if (m.isMutualAgreement)
        ('اتفاق بالتراضي', '${m.mutualAgreementPercent.round()}%'),
      if (m.accruedLeaveDays > 0)
        ('إجازات متبقية', '${m.accruedLeaveDays} يوم'),
      if (m.includeFlightTicket)
        (
          'تذكرة طيران',
          '${m.ticketCost > 0 ? "يدوي" : "تقدير تلقائي"} '
          '${m.effectiveTicketCost.round()} $currency · '
          '${EosbModel.ticketFrequencyLabel(m.ticketFrequency)}',
        ),
      (
        'إشعار الإنهاء',
        m.noticeProvided ? 'تم تقديمه' : 'لم يُقدَّم — راجع المادة 75',
      ),
    ];

    return GlassSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'بيانات الحساب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.$1,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

/// حقل إدخال زجاجي — TextFormField.
class _EosbTextField extends StatelessWidget {
  const _EosbTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: errorText != null ? (_) => errorText : null,
      style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixText: suffixText,
        labelStyle: GoogleFonts.cairo(fontSize: 13),
        hintStyle: GoogleFonts.cairo(
          fontSize: 13,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.45),
        ),
        suffixStyle: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.7),
        ),
        errorStyle: GoogleFonts.cairo(fontSize: 11),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
