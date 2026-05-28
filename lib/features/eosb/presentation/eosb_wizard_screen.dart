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
import 'package:netgulf/features/eosb/domain/eosb_constants.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';
import 'package:netgulf/features/eosb/providers/eosb_providers.dart';

// ─── EOSB Wizard UI (مكافأة نهاية الخدمة — دول الخليج الست) ───
// 3-step wizard → live preview → results + PDF. No other feature flows here.

/// إنهاء الخطوة 3 → الانتقال التلقائي لشاشة النتائج (بعد التحقق).
bool eosbTryFinishAndShowResults(BuildContext context, WidgetRef ref) {
  ref.read(eosbWizardProvider.notifier).flushAllInputs();
  final error = ref.read(eosbWizardProvider.notifier).tryFinishWizard();
  if (error == null) {
    // showResults=true يُفعّل AnimatedSwitcher في [EosbWizardScreen] فوراً.
    return true;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
  return false;
}

/// حاسبة نهاية الخدمة — معالج 3 خطوات، معاينة مباشرة، نتائج، PDF.
class EosbWizardScreen extends ConsumerStatefulWidget {
  const EosbWizardScreen({
    super.key,
    this.dedicatedEosbBranding = false,
    this.historyEntryId,
  });

  /// عند true (مسار `/eosb`) — عنوان الشاشة مخصّص للحاسبة فقط.
  final bool dedicatedEosbBranding;

  /// عند التعيين — يُفتح الحساب المحفوظ من السجل مباشرة على النتائج.
  final String? historyEntryId;

  @override
  ConsumerState<EosbWizardScreen> createState() => _EosbWizardScreenState();
}

class _EosbWizardScreenState extends ConsumerState<EosbWizardScreen> {
  @override
  void initState() {
    super.initState();
    final historyId = widget.historyEntryId;
    if (historyId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final entry = EosbHistoryService.getById(historyId);
        if (entry == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لم يُعثر على الحساب المحفوظ',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        final ok = ref
            .read(eosbWizardProvider.notifier)
            .openFromHistoryEntry(entry);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تعذّر فتح التفاصيل — أعد الحفظ من شاشة النتائج',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      });
    }
  }

  void _onBackFromResults(BuildContext context, WidgetRef ref) {
    if (widget.historyEntryId != null) {
      context.pop();
      return;
    }
    ref.read(eosbWizardProvider.notifier).resumeEditing();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'عدت للمعالج — عدّل البيانات ثم اضغط «عرض النتيجة»',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wizard = ref.watch(eosbWizardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(eosbWizardProvider, (previous, next) {
      if (previous == null || !mounted) return;
      // انتقال تلقائي من الخطوة 3 → شاشة النتائج بعد نجاح finishWizard.
      if (!previous.showResults && next.showResults) {
        HapticFeedback.mediumImpact();
        final result = ref.read(eosbFinalizedResultProvider);
        if (result == null) return;
        final total = result.totalEntitlements;
        final eos = result.endOfServiceAmount;
        final sym = next.country.currencySymbol;
        final totalStr =
            NumberFormat.decimalPattern('ar').format(total.round());
        final message = eos <= 0 && total > 0
            ? 'تم الحساب بنجاح — الإجمالي $totalStr $sym '
                '(بدون مكافأة نهاية خدمة حسب النظام)'
            : 'تم الحساب بنجاح — الإجمالي $totalStr $sym · ${next.country.nameAr}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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
              ? _onBackFromResults(context, ref)
              : (context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.home)),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dedicatedEosbBranding
                  ? 'حاسبة نهاية الخدمة'
                  : 'المساعد القانوني',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              wizard.showResults
                  ? (widget.historyEntryId != null
                      ? 'تفاصيل حساب محفوظ'
                      : 'نتيجة الحساب والتفاصيل')
                  : (widget.dedicatedEosbBranding
                      ? 'دول الخليج الست — تقدير قانوني'
                      : 'حاسبة نهاية الخدمة الشاملة'),
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
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previous,
                ?current,
              ],
            ),
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
    'دول الخليج الست · المدة والأجر',
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

    ref.listen(eosbWizardProvider, (previous, next) {
      if (previous != null && previous.stepIndex != next.stepIndex) {
        ref.read(eosbWizardProvider.notifier).flushAllInputs();
      }
    });

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
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0.06, 0),
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
            child: SingleChildScrollView(
              key: ValueKey<int>(step),
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: switch (step) {
                0 => _StepTermination(key: const ValueKey('s0')),
                1 => _StepContract(key: const ValueKey('s1')),
                _ => _StepExtras(
                    key: const ValueKey('s2'),
                    onFinish: () => eosbTryFinishAndShowResults(context, ref),
                  ),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: validationMsg != null && !canAdvance
                ? Text(
                    validationMsg,
                    key: ValueKey(validationMsg),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  )
                : Text(
                    isLastStep && canAdvance
                        ? 'اضغط «عرض النتيجة» للانتقال التلقائي لشاشة النتائج'
                        : wizard.guidanceForStep(stepIndex),
                    key: ValueKey('hint_${stepIndex}_$canAdvance'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight:
                          isLastStep && canAdvance ? FontWeight.w600 : FontWeight.w500,
                      color: isLastStep && canAdvance
                          ? AppColors.emerald
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                    ),
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
              Tooltip(
                message: canAdvance
                    ? (isLastStep ? 'عرض النتيجة الكاملة' : 'الانتقال للخطوة التالية')
                    : (validationMsg ?? wizard.guidanceForStep(stepIndex)),
                child: FilledButton.icon(
                  onPressed: canAdvance
                      ? () {
                          if (isLastStep) {
                            if (eosbTryFinishAndShowResults(context, ref)) {
                              HapticFeedback.mediumImpact();
                            }
                            return;
                          }
                          notifier.flushAllInputs();
                          final error = ref
                              .read(eosbWizardProvider)
                              .validationMessageForStep(stepIndex);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error,
                                  style:
                                      GoogleFonts.cairo(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          if (notifier.nextStep()) {
                            HapticFeedback.selectionClick();
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// شريط المعاينة المباشرة — يُعاد بناؤه فور أي تغيير في المدخلات.
class _LivePreviewBar extends ConsumerWidget {
  const _LivePreviewBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(eosbWizardProvider);
    ref.watch(eosbCalculatorProvider);
    ref.watch(eosbLivePreviewKeyProvider);
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: RepaintBoundary(child: _EosbLivePreviewCard()),
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
  void deactivate() {
    _pushToProvider();
    super.deactivate();
  }

  @override
  void dispose() {
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
      years: _parseNonNegativeInt(_yearsCtrl.text)
          .clamp(0, EosbWizardState.maxServiceYears),
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
    final currencySuffix = wizard.country.currencyShortAr;
    final showFieldErrors =
        wizard.stepIndex == 1 && !wizard.canProceedStep1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('الدولة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        EosbCountryGrid(
          selected: wizard.country,
          onSelected: notifier.setCountry,
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _CountryLawChip(
            key: ValueKey(wizard.country),
            country: wizard.country,
          ),
        ),
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
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2);
}

class _StepExtras extends ConsumerStatefulWidget {
  const _StepExtras({super.key, required this.onFinish});

  final bool Function() onFinish;

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
  void deactivate() {
    _pushLeaveToProvider();
    super.deactivate();
  }

  @override
  void dispose() {
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
        if (wizard.canAdvanceFromCurrentStep) ...[
          const SizedBox(height: 20),
          _StepFinishButton(
            enabled: wizard.validationBeforeResults() == null,
            onPressed: () {
              final ok = widget.onFinish();
              if (ok) HapticFeedback.mediumImpact();
              return ok;
            },
          ),
        ] else if (wizard.validationBeforeResults() != null) ...[
          const SizedBox(height: 12),
          Text(
            wizard.validationBeforeResults()!,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// زر إنهاء سريع داخل الخطوة 3 — ينقل تلقائياً لشاشة النتائج.
class _StepFinishButton extends StatelessWidget {
  const _StepFinishButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final bool Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: enabled ? () => onPressed() : null,
        icon: const Icon(Icons.calculate_rounded, size: 22),
        label: Text(
          'عرض النتيجة الآن',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          disabledBackgroundColor: AppColors.emerald.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
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

  static Color _totalColor(BuildContext context, double total, double monthlyWage) {
    final muted = Theme.of(context)
        .colorScheme
        .onSurface
        .withValues(alpha: 0.45);
    if (total <= 0) return muted;
    if (monthlyWage <= 0) return AppColors.emerald;
    final ratio = total / monthlyWage;
    if (ratio >= 12) return AppColors.goldBright;
    if (ratio >= 6) return AppColors.emerald;
    if (ratio >= 3) return AppColors.emeraldLight;
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75);
  }

  static String? _entitlementHint(double total, double monthlyWage) {
    if (total <= 0 || monthlyWage <= 0) return null;
    final ratio = total / monthlyWage;
    if (ratio >= 12) return 'مستحقات مرتفعة — أكثر من سنة راتب';
    if (ratio >= 6) return 'مستحقات جيدة — أكثر من 6 أشهر راتب';
    if (ratio >= 3) return 'مستحقات معتدلة';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final previewKey = ref.watch(eosbLivePreviewKeyProvider);
    final result = ref.watch(eosbCalculatorProvider);
    final model = result.input;
    final currency = NumberFormat.currency(
      locale: model.country.currencyLocale,
      symbol: model.country.currencySymbol,
      decimalDigits: 0,
    );
    final needsContractData = !wizard.canProceedStep1;
    final previewWarning = wizard.livePreviewWarning;
    final total = result.totalEntitlements;
    final totalColor = _totalColor(context, total, model.monthlyWage);
    final hint = _entitlementHint(total, model.monthlyWage);
    final leaveTotal =
        result.cashLeaveAllowance + result.vacationAllowance;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final breakdown = <_PreviewBreakdownRow>[
      _PreviewBreakdownRow(
        icon: Icons.card_giftcard_rounded,
        label: 'مكافأة نهاية الخدمة',
        amount: result.endOfServiceAmount,
        accent: AppColors.emerald,
      ),
      _PreviewBreakdownRow(
        icon: Icons.beach_access_rounded,
        label: model.accruedLeaveDays > 0
            ? 'إجازات (${model.accruedLeaveDays} يوم + سنوية)'
            : 'إجازات (سنوية تقديرية)',
        amount: leaveTotal,
        accent: const Color(0xFF0EA5E9),
      ),
      _PreviewBreakdownRow(
        icon: Icons.flight_rounded,
        label: model.includeFlightTicket
            ? 'تذكرة طيران (تقدير)'
            : 'تذكرة طيران',
        amount: result.flightTicketAllowance,
        accent: const Color(0xFF8B5CF6),
        inactive: !model.includeFlightTicket,
      ),
    ];

    return GlassSurface(
      key: ValueKey(previewKey),
      highlighted: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.emerald.withValues(alpha: isDark ? 0.35 : 0.18),
                  AppColors.emeraldDark.withValues(alpha: isDark ? 0.2 : 0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppColors.emerald,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة المستحقات',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${model.country.flag} ${model.country.nameAr} · تقدير فوري',
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Container(
                    key: ValueKey(total.toStringAsFixed(0)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: totalColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: totalColor.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      currency.format(total),
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: totalColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hint != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: totalColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: totalColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hint,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: totalColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (needsContractData)
                  Text(
                    'أكمل مدة الخدمة والراتب في الخطوة 2 لعرض التفصيل',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
                  )
                else ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _PreviewChip(
                        icon: Icons.gavel_rounded,
                        label: model.terminationSummary,
                      ),
                      _PreviewChip(
                        icon: Icons.schedule_rounded,
                        label:
                            '${model.totalServiceYears.toStringAsFixed(1)} سنة خدمة',
                      ),
                      _PreviewChip(
                        icon: Icons.payments_rounded,
                        label:
                            'أجر ${currency.format(model.monthlyWage)}/شهر',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'تفصيل التقدير',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...breakdown.map(
                    (row) => _PreviewBreakdownTile(
                      row: row,
                      currency: currency,
                      total: total,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 8),
                    _PreviewProportionBar(
                      eos: result.endOfServiceAmount,
                      leave: leaveTotal,
                      ticket: model.includeFlightTicket
                          ? result.flightTicketAllowance
                          : 0,
                      total: total,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: AppColors.emerald.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'الإجمالي المستحق',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          currency.format(total),
                          key: ValueKey('total_$total'),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: totalColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (previewWarning != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          previewWarning,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBreakdownRow {
  const _PreviewBreakdownRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.accent,
    this.inactive = false,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color accent;
  final bool inactive;
}

class _PreviewBreakdownTile extends StatelessWidget {
  const _PreviewBreakdownTile({
    required this.row,
    required this.currency,
    required this.total,
  });

  final _PreviewBreakdownRow row;
  final NumberFormat currency;
  final double total;

  @override
  Widget build(BuildContext context) {
    final amountColor = row.inactive
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
        : row.amount > 0 && total > 0 && row.amount / total >= 0.5
            ? AppColors.emerald
            : row.amount > 0
                ? row.accent
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: row.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(row.icon, size: 16, color: row.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              row.inactive
                  ? 'غير مفعّلة'
                  : currency.format(row.amount),
              key: ValueKey('${row.label}_${row.amount}_${row.inactive}'),
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.emerald),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط نسبي — مكافأة · إجازات · تذكرة.
class _PreviewProportionBar extends StatelessWidget {
  const _PreviewProportionBar({
    required this.eos,
    required this.leave,
    required this.ticket,
    required this.total,
  });

  final double eos;
  final double leave;
  final double ticket;
  final double total;

  @override
  Widget build(BuildContext context) {
    final segments = <(Color, double)>[
      (AppColors.emerald, eos),
      (const Color(0xFF0EA5E9), leave),
      if (ticket > 0) (const Color(0xFF8B5CF6), ticket),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 6,
        child: Row(
          children: segments
              .where((s) => s.$2 > 0)
              .map(
                (s) => Expanded(
                  flex: (s.$2 / total * 100).round().clamp(1, 100),
                  child: ColoredBox(color: s.$1),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// شارة نظام العمل حسب الدولة.
class _CountryLawChip extends StatelessWidget {
  const _CountryLawChip({super.key, required this.country});

  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    final text = country.eosLawChipAr;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollResultsToTop());
  }

  void _scrollResultsToTop() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollResultsToTop());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(eosbWizardProvider);
    final finalized = ref.watch(eosbFinalizedResultProvider);

    if (finalized == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.emerald),
      );
    }

    final result = finalized;
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
              const _ResultsEdgeCaseBanner(),
              const SizedBox(height: 12),
              _AnimatedTotalHeroCard(
                result: result,
                currency: currency,
                isDark: widget.isDark,
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _ResultsCountryLawChip(
                  key: ValueKey(model.country),
                  country: model.country,
                ),
              ),
              const SizedBox(height: 12),
              _SaveCalculationButton(result: result),
              const SizedBox(height: 10),
              _EditWizardButton(
                onResume: (step) {
                  HapticFeedback.selectionClick();
                  ref.read(eosbWizardProvider.notifier).resumeEditing(
                        stepIndex: step,
                      );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        step == 0
                            ? 'عدت للخطوة 1 — نوع إنهاء الخدمة'
                            : step == 1
                                ? 'عدت للخطوة 2 — بيانات العقد'
                                : 'عدت للخطوة 3 — عدّل التفاصيل ثم «عرض النتيجة»',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
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
              const SizedBox(height: 20),
              const _ResultsBottomDisclaimer(),
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

/// تعديل البيانات — العودة للمعالج (الخطوة الحالية أو خطوة محددة).
class _EditWizardButton extends StatelessWidget {
  const _EditWizardButton({required this.onResume});

  final void Function(int stepIndex) onResume;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onResume(EosbWizardState.totalSteps - 1),
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: Text(
                'تعديل البيانات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emerald,
                side: const BorderSide(color: AppColors.emerald, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Text(
            'أو اختر خطوة محددة للتعديل:',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onResume(0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'من البداية',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onResume(1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'العقد',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FilledButton(
                  onPressed: () => onResume(2),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'التفاصيل',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// تنبيه عند حالات خاصة (مثلاً استقالة إماراتية أقل من 3 سنوات).
class _ResultsEdgeCaseBanner extends ConsumerWidget {
  const _ResultsEdgeCaseBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(eosbFinalizedResultProvider);
    if (result == null) return const SizedBox.shrink();
    final m = result.input;
    final rules = EosbCountryRules.forCountry(m.country);
    final showResignationZero = m.terminationType ==
            EosbTerminationType.employeeResignation &&
        result.endOfServiceAmount <= 0 &&
        ((rules != null &&
                rules.shouldShowResignationZeroBanner(m, result.endOfServiceAmount)) ||
            (m.country == GulfCountry.uae &&
                (result.resignationFactorApplied ?? 0) <= 0));

    if (!showResignationZero) {
      return const SizedBox.shrink();
    }

    final message = switch (m.country) {
      GulfCountry.uae =>
        'استقالة قبل إتمام 3 سنوات في الإمارات — لا تستحق مكافأة '
        'نهاية الخدمة (م. 51). قد يظهر في الإجمالي بدل إجازة أو تذكرة فقط.',
      GulfCountry.qatar =>
        'استقالة قبل سنتين في قطر — لا تستحق مكافأة نهاية الخدمة (م. 51).',
      GulfCountry.oman =>
        'استقالة قبل 3 سنوات في عُمان — لا تستحق مكافأة (م. 50).',
      GulfCountry.bahrain =>
        'استقالة قبل 3 سنوات في البحرين — لا تستحق مكافأة نهاية الخدمة.',
      GulfCountry.kuwait =>
        'استقالة قبل 3 سنوات في الكويت — لا تستحق مكافأة (م. 53).',
      _ => 'استقالة بمدة خدمة غير كافية — لا مكافأة نهاية خدمة.',
    };

    return GlassSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط نجاح أعلى شاشة النتائج — يظهر عند الانتقال من المعالج.
class _ResultsSuccessBanner extends ConsumerStatefulWidget {
  const _ResultsSuccessBanner();

  @override
  ConsumerState<_ResultsSuccessBanner> createState() =>
      _ResultsSuccessBannerState();
}

class _ResultsSuccessBannerState extends ConsumerState<_ResultsSuccessBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _fade = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(eosbFinalizedResultProvider);
    final countryHint = result != null
        ? '${result.countryLabel} — '
        : '';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GlassSurface(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم إكمال الحساب بنجاح',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.emerald,
                      ),
                    ),
                    Text(
                      '$countryHintانتقلت لشاشة النتائج — راجع التفاصيل أو صدّر PDF',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        height: 1.35,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
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

/// ملخص المدخلات — حي في المعالج، مجمّد على شاشة النتائج.
class _InputsSummaryCard extends ConsumerWidget {
  const _InputsSummaryCard({this.forResults = false});

  /// عند true: يقرأ [eosbFinalizedResultProvider] (نتيجة مجمّدة).
  final bool forResults;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(eosbWizardProvider);
    final EosbCalculationResult result = forResults
        ? ref.watch(eosbFinalizedResultProvider) ??
            ref.watch(eosbCalculatorProvider)
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

/// بطاقة الإجمالي — تدرج لوني، مبلغ كبير متحرك، نبض خفيف بعد الظهور.
class _AnimatedTotalHeroCard extends StatefulWidget {
  const _AnimatedTotalHeroCard({
    required this.result,
    required this.currency,
    required this.isDark,
  });

  final EosbCalculationResult result;
  final NumberFormat currency;
  final bool isDark;

  @override
  State<_AnimatedTotalHeroCard> createState() => _AnimatedTotalHeroCardState();
}

class _AnimatedTotalHeroCardState extends State<_AnimatedTotalHeroCard>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _entryScale;
  late final Animation<double> _entryFade;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    final curve = CurvedAnimation(
      parent: _entryCtrl,
      curve: Curves.easeOutBack,
    );
    _entryScale = Tween<double>(begin: 0.85, end: 1).animate(curve);
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _pulseScale = Tween<double>(begin: 1, end: 1.025).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _entryCtrl.forward().then((_) {
      if (mounted) _pulseCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final model = result.input;
    final total = result.totalEntitlements;

    return FadeTransition(
      opacity: _entryFade,
      child: ScaleTransition(
        scale: _entryScale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF064E3B),
                Color(0xFF0D7A5F),
                Color(0xFF0A5C47),
              ],
            ),
            boxShadow: [
              ...AppColors.premiumCardGlow(isDark: widget.isDark),
              BoxShadow(
                color: AppColors.goldBright.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                result.countryLabel,
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'إجمالي المستحقات',
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 14),
              ScaleTransition(
                scale: _pulseScale,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: total),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFF8DC),
                            AppColors.goldBright,
                            Color(0xFFE8C547),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          widget.currency.format(value),
                          style: GoogleFonts.cairo(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.02,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'مكافأة نهاية الخدمة',
                style: GoogleFonts.cairo(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  widget.currency.format(result.endOfServiceAmount),
                  key: ValueKey(result.endOfServiceAmount),
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
        ),
      ),
    );
  }
}

/// حفظ الحساب في السجل المحلي (Hive).
class _SaveCalculationButton extends StatefulWidget {
  const _SaveCalculationButton({required this.result});

  final EosbCalculationResult result;

  @override
  State<_SaveCalculationButton> createState() => _SaveCalculationButtonState();
}

class _SaveCalculationButtonState extends State<_SaveCalculationButton> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    if (_saving || _saved) return;
    setState(() => _saving = true);
    try {
      final ok = await EosbHistoryService.save(widget.result);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.mediumImpact();
        setState(() {
          _saved = true;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حفظ حساب ${widget.result.input.country.nameAr} — '
              'راجعه من سجل نهاية الخدمة',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'السجل',
              textColor: Colors.white,
              onPressed: () => context.push(AppRoutes.eosbHistory),
            ),
          ),
        );
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر الحفظ — حاول مرة أخرى',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذّر الحفظ محلياً',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _saving || _saved ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                _saved ? Icons.check_circle_rounded : Icons.bookmark_add_rounded,
                size: 24,
              ),
        label: Text(
          _saving
              ? 'جاري الحفظ...'
              : _saved
                  ? 'تم حفظ الحساب'
                  : 'حفظ الحساب',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _saved ? AppColors.emeraldDark : AppColors.navyMid,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.emerald.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
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
    var result = ref.read(eosbFinalizedResultProvider);
    if (result == null && ref.read(eosbWizardProvider).showResults) {
      final err = ref.read(eosbWizardProvider.notifier).tryFinishWizard();
      if (err != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err, style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      result = ref.read(eosbFinalizedResultProvider);
    }
    if (result == null ||
        (result.endOfServiceAmount <= 0 && result.totalEntitlements <= 0)) {
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

/// تنبيه تقريبية بارز — أسفل شاشة النتائج.
class _ResultsBottomDisclaimer extends StatelessWidget {
  const _ResultsBottomDisclaimer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.emerald.withValues(alpha: 0.55),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withValues(alpha: isDark ? 0.2 : 0.1),
            AppColors.warning.withValues(alpha: isDark ? 0.12 : 0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gavel_rounded,
              size: 22,
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              EosbConstants.approximationDisclaimerAr,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شارة القانون المطبّق على النتائج.
class _ResultsCountryLawChip extends StatelessWidget {
  const _ResultsCountryLawChip({super.key, required this.country});

  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              country.eosLawChipAr,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.emerald,
                height: 1.35,
              ),
            ),
          ),
        ],
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
              'تنبيه قانوني: أداة تقديرية عامة وفق أنظمة العمل في دول مجلس التعاون '
              'الخليجي (السعودية، الإمارات، عُمان، قطر، البحرين، الكويت). '
              'لا تُغني عن مراجعة العقد أو محامٍ أو الجهة المختصة.',
              style: GoogleFonts.cairo(fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
