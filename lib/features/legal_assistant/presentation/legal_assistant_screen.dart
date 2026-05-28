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

    ref.listen(eosbWizardProvider, (previous, next) {
      if (previous == null || !mounted) return;
      if (!previous.showResults && next.showResults) {
        HapticFeedback.mediumImpact();
        final total = ref.read(eosbResultsProvider).totalEntitlements;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حساب مستحقاتك — ${NumberFormat.decimalPattern('ar').format(total.round())} '
              '${next.country.currencySymbol}',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

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
              wizard.showResults
                  ? 'نتيجة الحساب والتفاصيل'
                  : 'حاسبة نهاية الخدمة الشاملة',
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
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ));
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
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
  final _scrollController = ScrollController();
  int _lastStepIndex = 0;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    final step = wizard.stepIndex.clamp(0, 2);

    if (step != _lastStepIndex) {
      _lastStepIndex = step;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
    }

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
              controller: _scrollController,
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
    ref.watch(eosbCalculatorProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);
    final isLastStep = stepIndex == EosbWizardState.totalSteps - 1;
    final canAdvance = wizard.canAdvanceFromCurrentStep;
    final validationMsg = isLastStep
        ? wizard.validationBeforeResults()
        : wizard.validationMessageForStep(stepIndex);

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
                        notifier.flushAllInputs();
                        final current = ref.read(eosbWizardProvider);
                        final error = isLastStep
                            ? current.validationBeforeResults()
                            : current.validationMessageForStep(stepIndex);
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
                          if (notifier.finishWizard()) {
                            HapticFeedback.mediumImpact();
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ref
                                          .read(eosbWizardProvider)
                                          .validationBeforeResults() ??
                                      'تعذّر عرض النتيجة — راجع البيانات المطلوبة',
                                  style: GoogleFonts.cairo(),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } else {
                          if (notifier.nextStep()) {
                            HapticFeedback.selectionClick();
                          }
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
class _LivePreviewBar extends StatelessWidget {
  const _LivePreviewBar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: _EosbLivePreviewCard(),
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
  (
    EosbTerminationType.retirementOrDeath,
    'تقاعد / وفاة',
    Icons.elderly_rounded,
  ),
];

class _StepTermination extends ConsumerWidget {
  const _StepTermination({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    ref.watch(eosbCalculatorProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);
    final groupValue = wizard.resolvedTermination;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSurface(
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
        ),
        if (wizard.terminationType == EosbTerminationType.mutualAgreement) ...[
          const SizedBox(height: 12),
          _MutualAgreementSlider(
            percent: wizard.mutualAgreementPercent,
            onChanged: notifier.setMutualAgreementPercent,
          ),
        ],
        if (wizard.canShowLivePreview) ...[
          const SizedBox(height: 16),
          const _EosbLivePreviewCard(),
        ],
      ],
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
      if (mounted) {
        ref.read(eosbWizardProvider.notifier).registerInputSync(_pushToProvider);
        _pushToProvider();
      }
    });
  }

  @override
  void dispose() {
    _pushToProvider();
    ref.read(eosbWizardProvider.notifier).unregisterInputSync(_pushToProvider);
    _yearsCtrl.dispose();
    _monthsCtrl.dispose();
    _basicCtrl.dispose();
    _housingCtrl.dispose();
    super.dispose();
  }

  void _pushToProvider() {
    final notifier = ref.read(eosbWizardProvider.notifier);
    final rawMonths = _parseNonNegativeInt(_monthsCtrl.text);
    final months = rawMonths.clamp(0, 11);
    if (rawMonths != months) {
      _monthsCtrl.text = '$months';
    }
    notifier.setServiceDuration(
      years: _parseNonNegativeInt(_yearsCtrl.text),
      months: months,
    );
    notifier.setSalaries(
      basic: _parseNonNegativeDouble(_basicCtrl.text),
      housing: _parseNonNegativeDouble(_housingCtrl.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    ref.watch(eosbCalculatorProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    ref.listen(eosbWizardProvider, (prev, next) {
      if (prev == null) return;
      if (prev.years != next.years && _yearsCtrl.text != '${next.years}') {
        _yearsCtrl.text = '${next.years}';
      }
      if (prev.months != next.months && _monthsCtrl.text != '${next.months}') {
        _monthsCtrl.text = '${next.months}';
      }
      final basicFmt =
          next.basicSalary > 0 ? _fmt(next.basicSalary) : '';
      if (prev.basicSalary != next.basicSalary && _basicCtrl.text != basicFmt) {
        _basicCtrl.text = basicFmt;
      }
      final housingFmt =
          next.housingAllowance > 0 ? _fmt(next.housingAllowance) : '';
      if (prev.housingAllowance != next.housingAllowance &&
          _housingCtrl.text != housingFmt) {
        _housingCtrl.text = housingFmt;
      }
    });
    final currencySuffix =
        wizard.country == GulfCountry.saudiArabia ? 'ريال' : 'درهم';
    final showFieldErrors =
        wizard.stepIndex == 1 && !wizard.canProceedStep1;

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
        Text('نوع العقد', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
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
                'محدد المدة',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
            ),
          ],
          selected: {wizard.contractType},
          onSelectionChanged: (s) => notifier.setContractType(s.first),
        ),
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
                onEditingComplete: _pushToProvider,
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
                onEditingComplete: _pushToProvider,
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
                onEditingComplete: _pushToProvider,
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
                onEditingComplete: _pushToProvider,
              ),
            ],
          ),
        ),
        if (wizard.canShowLivePreview) ...[
          const SizedBox(height: 16),
          const _EosbLivePreviewCard(),
        ],
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
        final notifier = ref.read(eosbWizardProvider.notifier);
        notifier.registerInputSync(_pushLeaveToProvider);
        _pushLeaveToProvider();
      }
    });
  }

  @override
  void dispose() {
    _pushLeaveToProvider();
    ref
        .read(eosbWizardProvider.notifier)
        .unregisterInputSync(_pushLeaveToProvider);
    _leaveCtrl.dispose();
    super.dispose();
  }

  void _pushLeaveToProvider() {
    ref.read(eosbWizardProvider.notifier).setAccruedLeave(
          int.tryParse(_leaveCtrl.text) ?? 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    ref.watch(eosbCalculatorProvider);
    final notifier = ref.read(eosbWizardProvider.notifier);

    ref.listen(eosbWizardProvider, (prev, next) {
      if (prev != null &&
          prev.accruedLeaveDays != next.accruedLeaveDays &&
          _leaveCtrl.text != '${next.accruedLeaveDays}') {
        _leaveCtrl.text = '${next.accruedLeaveDays}';
      }
    });

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
            onChanged: (_) => _pushLeaveToProvider(),
            onEditingComplete: _pushLeaveToProvider,
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
          _MutualAgreementSlider(
            percent: wizard.mutualAgreementPercent,
            onChanged: notifier.setMutualAgreementPercent,
          ),
        ],
        const SizedBox(height: 12),
        GlassSurface(
          padding: const EdgeInsets.all(14),
          child: Text(
            'بعد الضغط على «عرض النتيجة» ستظهر شاشة التفاصيل الكاملة '
            'مع المراجع القانونية وإمكانية التصدير PDF.',
            style: GoogleFonts.cairo(
              fontSize: 12,
              height: 1.45,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.65),
            ),
          ),
        ),
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
        if (wizard.canShowLivePreview) ...[
          const SizedBox(height: 16),
          const _EosbLivePreviewCard(),
        ],
      ],
    );
  }
}

/// شريط نسبة الاتفاق بالتراضي.
class _MutualAgreementSlider extends StatelessWidget {
  const _MutualAgreementSlider({
    required this.percent,
    required this.onChanged,
  });

  final double percent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
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
                '${percent.round()}%',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          Slider(
            value: percent,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.emerald,
            label: '${percent.round()}%',
            onChanged: onChanged,
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
    );
  }
}

/// معاينة مباشرة — تتحدث فوراً مع [eosbCalculatorProvider].
class _EosbLivePreviewCard extends ConsumerWidget {
  const _EosbLivePreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final result = ref.watch(eosbCalculatorProvider);
    final lines = ref.watch(eosbPreviewLinesProvider);
    final currency = NumberFormat.currency(
      locale: result.input.country.currencyLocale,
      symbol: result.input.country.currencySymbol,
      decimalDigits: 0,
    );
    final needsContractData = !wizard.canProceedStep1;

    return GlassSurface(
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
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  currency.format(result.totalEntitlements),
                  key: ValueKey(result.totalEntitlements.toStringAsFixed(0)),
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          if (needsContractData) ...[
            const SizedBox(height: 6),
            Text(
              'أكمل مدة الخدمة والراتب في الخطوة 2 لتحديث المكافأة',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ],
          if (!needsContractData) ...[
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        currency.format(line.amount),
                        key: ValueKey('${line.labelAr}_${line.amount}'),
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: line.labelAr == 'الإجمالي المستحق'
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: line.labelAr == 'الإجمالي المستحق'
                              ? AppColors.emerald
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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

class _ResultsView extends ConsumerStatefulWidget {
  const _ResultsView({super.key, required this.isDark});

  final bool isDark;

  @override
  ConsumerState<_ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends ConsumerState<_ResultsView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(eosbResultsProvider);
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
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
            children: [
              const _ResultsSuccessBanner(),
              const SizedBox(height: 12),
              _TotalHeroCard(
                result: result,
                currency: currency,
                isDark: widget.isDark,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(eosbWizardProvider.notifier).previousStep(),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: Text(
                    'تعديل البيانات',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const _InputsSummaryCard(forResults: true),
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
        const _ResultsBottomBar(),
      ],
    );
  }
}

/// شريط نجاح أعلى شاشة النتائج.
class _ResultsSuccessBanner extends StatelessWidget {
  const _ResultsSuccessBanner();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      highlighted: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.emerald,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'اكتمل الحساب — يمكنك مراجعة التفاصيل أو تصدير PDF',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ملخص المدخلات — حي في المعالج، مجمّد على شاشة النتائج.
class _InputsSummaryCard extends ConsumerWidget {
  const _InputsSummaryCard({this.forResults = false});

  /// عند true: يقرأ [eosbResultsProvider] (نتيجة الخطوة 3).
  final bool forResults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final result = forResults || wizard.showResults
        ? ref.watch(eosbResultsProvider)
        : ref.watch(eosbCalculatorProvider);
    final m = result.input;
    final currency = m.country.currencySymbol;
    final factor = result.resignationFactorApplied;
    final awardPct = result.appliedAwardPercent;
    final rows = <(String, String)>[
      ('الدولة', '${m.country.flag} ${m.country.nameAr}'),
      ('نوع الإنهاء', m.terminationSummary),
      (
        'مكافأة نهاية الخدمة',
        '${result.endOfServiceAmount.round()} $currency',
      ),
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
        (
          m.isMutualAgreement ? 'نسبة الاتفاق بالتراضي' : 'نسبة المكافأة المطبّقة',
          '${awardPct.round()}%',
        ),
      if (m.isMutualAgreement)
        ('وعاء الاتفاق', 'م. 84 (أساسي + سكن)'),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  forResults ? 'ملخص الحساب النهائي' : 'بيانات الحساب',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!forResults && wizard.canProceedStep1)
                Text(
                  'مباشر',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
            ],
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
          const SizedBox(height: 8),
          Text(
            'مكافأة نهاية الخدمة',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
          Text(
            currency.format(result.endOfServiceAmount),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.95),
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
        'total' => Icons.summarize_rounded,
        _ => Icons.payments_rounded,
      };
}

class _ResultsBottomBar extends ConsumerStatefulWidget {
  const _ResultsBottomBar();

  @override
  ConsumerState<_ResultsBottomBar> createState() => _ResultsBottomBarState();
}

class _ResultsBottomBarState extends ConsumerState<_ResultsBottomBar> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
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
                onPressed: _exporting ? null : () => _exportPdf(context),
                icon: _exporting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 22),
                label: Text(
                  _exporting ? 'جاري التصدير...' : 'تصدير PDF',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.emerald.withValues(alpha: 0.7),
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

  Future<void> _exportPdf(BuildContext context) async {
    final result = ref.read(eosbResultsProvider);
    if (result.endOfServiceAmount <= 0 && result.totalEntitlements <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا توجد بيانات كافية للتصدير — راجع مدخلات الحساب',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isPremium = await PremiumAccess.requirePremium(
      context,
      ref,
      feature: PremiumFeature.pdfExport,
    );
    if (!isPremium) {
      await PremiumAccess.showInterstitialAfterPdfAttempt(ref);
      return;
    }
    if (!mounted) return;

    setState(() => _exporting = true);
    try {
      await EosbPdfService.exportAndShare(result);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إنشاء التقرير — اختر التطبيق للمشاركة أو الحفظ',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر تصدير PDF. تحقق من الاتصال وحاول مرة أخرى.',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
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
    this.onEditingComplete,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
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
