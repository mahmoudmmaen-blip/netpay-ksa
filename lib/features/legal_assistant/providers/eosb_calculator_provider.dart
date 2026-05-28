import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// حالة معالج حاسبة نهاية الخدمة.
class EosbWizardState {
  const EosbWizardState({
    this.stepIndex = 0,
    this.terminationType,
    this.dismissalIsValidReason = false,
    this.country = GulfCountry.saudiArabia,
    this.years = 0,
    this.months = 0,
    this.days = 0,
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.otherAllowances = 0,
    this.contractType = EosbContractType.unlimited,
    this.accruedLeaveDays = 0,
    this.includeFlightTicket = false,
    this.ticketCost = 0,
    this.ticketFrequency = FlightTicketFrequency.yearly,
    this.noticeProvided = true,
    this.mutualAgreementPercent = 100,
    this.showResults = false,
  });

  final int stepIndex;
  final EosbTerminationType? terminationType;
  final bool dismissalIsValidReason;
  final GulfCountry country;
  final int years;
  final int months;
  final int days;
  final double basicSalary;
  final double housingAllowance;
  final double otherAllowances;
  final EosbContractType contractType;
  final int accruedLeaveDays;
  final bool includeFlightTicket;
  final double ticketCost;
  final FlightTicketFrequency ticketFrequency;
  final bool noticeProvided;
  final double mutualAgreementPercent;
  final bool showResults;

  static const int totalSteps = 3;

  EosbTerminationType? get resolvedTermination => terminationType;

  bool get canProceedStep0 => terminationType != null;

  bool get canProceedStep1 =>
      basicSalary > 0 && (years > 0 || months > 0);

  /// الخطوة 3 — كل الحقول اختيارية.
  bool get canProceedStep2 => true;

  /// معاينة مباشرة — فور اختيار نوع الإنهاء (تتحدث مع كل حقل).
  bool get canShowLivePreview => canProceedStep0;

  String? get serviceYearsFieldError {
    if (years > 40) return 'عدد السنوات يبدو غير واقعي (الحد الأقصى 40)';
    if (years <= 0 && months <= 0) {
      return 'أدخل عدد السنوات أو الشهور الإضافية';
    }
    return null;
  }

  String? get serviceMonthsFieldError {
    if (months > 11) return 'الشهور الإضافية من 0 إلى 11 فقط';
    return null;
  }

  String? get basicSalaryFieldError => basicSalary <= 0
      ? 'أدخل الراتب الأساسي (أكبر من صفر)'
      : null;

  String? validationMessageForStep(int step) {
    return switch (step) {
      0 when !canProceedStep0 =>
        'الخطوة 1: اختر نوع إنهاء الخدمة للمتابعة',
      1 when basicSalaryFieldError != null =>
        'الخطوة 2: ${basicSalaryFieldError!}',
      1 when serviceMonthsFieldError != null =>
        'الخطوة 2: ${serviceMonthsFieldError!}',
      1 when serviceYearsFieldError != null =>
        'الخطوة 2: ${serviceYearsFieldError!}',
      _ => null,
    };
  }

  /// هل يمكن الانتقال من الخطوة الحالية فقط؟
  bool get isCurrentStepValid => validationMessageForStep(stepIndex) == null;

  /// هل يمكن الانتقال للخطوة التالية أو عرض النتيجة؟
  bool get canAdvanceFromCurrentStep {
    if (stepIndex >= totalSteps - 1) {
      return validationBeforeResults() == null;
    }
    return isCurrentStepValid;
  }

  /// التحقق الكامل قبل عرض النتائج.
  String? validationBeforeResults() {
    for (var i = 0; i < totalSteps; i++) {
      final msg = validationMessageForStep(i);
      if (msg != null) {
        return switch (i) {
          0 => msg,
          1 => 'الخطوة 2 — $msg',
          _ => msg,
        };
      }
    }
    return null;
  }

  /// مدة الخدمة بالسنوات (مع الشهور الإضافية).
  double get totalServiceYears =>
      years + (months.clamp(0, 11) / 12.0) + (days.clamp(0, 364) / 365.0);

  EosbModel toModel() => EosbModel(
        country: country,
        yearsOfService: years,
        monthsOfService: months.clamp(0, 11),
        daysOfService: days.clamp(0, 364),
        basicSalary: basicSalary,
        housingAllowance: housingAllowance,
        otherAllowances: otherAllowances,
        contractType: contractType,
        terminationType:
            resolvedTermination ?? EosbTerminationType.employerDismissalUnfair,
        ticketCost: ticketCost,
        includeFlightTicket: includeFlightTicket,
        ticketFrequency: ticketFrequency,
        accruedLeaveDays: accruedLeaveDays,
        noticeProvided: noticeProvided,
        mutualAgreementPercent: mutualAgreementPercent,
      );

  EosbWizardState copyWith({
    int? stepIndex,
    EosbTerminationType? terminationType,
    bool? dismissalIsValidReason,
    GulfCountry? country,
    int? years,
    int? months,
    int? days,
    double? basicSalary,
    double? housingAllowance,
    double? otherAllowances,
    EosbContractType? contractType,
    int? accruedLeaveDays,
    bool? includeFlightTicket,
    double? ticketCost,
    FlightTicketFrequency? ticketFrequency,
    bool? noticeProvided,
    double? mutualAgreementPercent,
    bool? showResults,
  }) {
    return EosbWizardState(
      stepIndex: stepIndex ?? this.stepIndex,
      terminationType: terminationType ?? this.terminationType,
      dismissalIsValidReason:
          dismissalIsValidReason ?? this.dismissalIsValidReason,
      country: country ?? this.country,
      years: years ?? this.years,
      months: months ?? this.months,
      days: days ?? this.days,
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      otherAllowances: otherAllowances ?? this.otherAllowances,
      contractType: contractType ?? this.contractType,
      accruedLeaveDays: accruedLeaveDays ?? this.accruedLeaveDays,
      includeFlightTicket: includeFlightTicket ?? this.includeFlightTicket,
      ticketCost: ticketCost ?? this.ticketCost,
      ticketFrequency: ticketFrequency ?? this.ticketFrequency,
      noticeProvided: noticeProvided ?? this.noticeProvided,
      mutualAgreementPercent:
          mutualAgreementPercent ?? this.mutualAgreementPercent,
      showResults: showResults ?? this.showResults,
    );
  }
}

class EosbWizardNotifier extends Notifier<EosbWizardState> {
  /// تقدير تكلفة تذكرة سنوية واحدة حسب الدولة (ريال / درهم).
  static double yearlyTicketEstimateFor(GulfCountry country) =>
      EosbCalculator.defaultYearlyTicketEstimate(country);

  static double _defaultYearlyTicketEstimate(GulfCountry country) =>
      yearlyTicketEstimateFor(country);

  final List<void Function()> _inputSyncCallbacks = [];

  /// تسجيل دالة مزامنة حقول الخطوة (TextField → state) قبل الحساب أو الانتقال.
  void registerInputSync(void Function() sync) {
    if (!_inputSyncCallbacks.contains(sync)) {
      _inputSyncCallbacks.add(sync);
    }
  }

  void unregisterInputSync(void Function() sync) {
    _inputSyncCallbacks.remove(sync);
  }

  void flushAllInputs() {
    for (final sync in List<void Function()>.from(_inputSyncCallbacks)) {
      sync();
    }
  }

  @override
  EosbWizardState build() {
    // read فقط — تجنّب إعادة ضبط المعالج عند تغيّر الراتب أو الدولة عالمياً
    final country = ref.read(gulfCountryProvider);
    final salary = ref.read(salaryNotifierProvider);
    return EosbWizardState(
      country: country,
      basicSalary: salary.basicSalary,
      housingAllowance: salary.housingAllowance,
      otherAllowances: salary.otherAllowances,
    );
  }

  /// اختيار نوع الإنهاء (زر اختيار — الخطوة 1).
  void setTerminationType(EosbTerminationType type) {
    state = state.copyWith(
      terminationType: type,
      dismissalIsValidReason:
          type == EosbTerminationType.employerDismissalValidReason,
    );
  }

  /// @deprecated استخدم [setTerminationType]
  void selectTerminationCategory(EosbTerminationType type) =>
      setTerminationType(type);

  void setCountry(GulfCountry country) {
    final nextTicketCost = state.includeFlightTicket && state.ticketCost <= 0
        ? _defaultYearlyTicketEstimate(country)
        : state.ticketCost;
    state = state.copyWith(country: country, ticketCost: nextTicketCost);
  }

  void setContractType(EosbContractType type) {
    state = state.copyWith(contractType: type);
  }

  void setServiceDuration({int? years, int? months, int? days}) {
    state = state.copyWith(
      years: (years ?? state.years).clamp(0, 40),
      months: (months ?? state.months).clamp(0, 11),
      days: (days ?? state.days).clamp(0, 364),
    );
  }

  void setSalaries({double? basic, double? housing, double? other}) {
    state = state.copyWith(
      basicSalary: basic ?? state.basicSalary,
      housingAllowance: housing ?? state.housingAllowance,
      otherAllowances: other ?? state.otherAllowances,
    );
  }

  void setAccruedLeave(int days) {
    state = state.copyWith(accruedLeaveDays: days.clamp(0, 90));
  }

  void setFlightTicket({required bool include, double? cost}) {
    final resolvedCost = cost ??
        (include && state.ticketCost <= 0
            ? _defaultYearlyTicketEstimate(state.country)
            : state.ticketCost);
    state = state.copyWith(
      includeFlightTicket: include,
      ticketCost: resolvedCost,
      ticketFrequency: include ? FlightTicketFrequency.yearly : state.ticketFrequency,
    );
  }

  void setTicketFrequency(FlightTicketFrequency f) {
    state = state.copyWith(ticketFrequency: f);
  }

  void setNoticeProvided(bool value) {
    state = state.copyWith(noticeProvided: value);
  }

  void setMutualAgreementPercent(double percent) {
    state = state.copyWith(
      mutualAgreementPercent: percent.clamp(0, 100),
    );
  }

  /// يتحقق من الخطوة الحالية ثم يتقدم أو يعرض النتائج.
  String? validateCurrentStep() =>
      state.validationMessageForStep(state.stepIndex);

  bool nextStep() {
    if (state.showResults) return false;
    flushAllInputs();
    if (validateCurrentStep() != null) return false;
    if (state.stepIndex >= EosbWizardState.totalSteps - 1) {
      return finishWizard();
    }
    state = state.copyWith(stepIndex: state.stepIndex + 1);
    return true;
  }

  /// إنهاء المعالج — حفظ نتيجة الحساب والانتقال لشاشة النتائج.
  bool finishWizard() {
    flushAllInputs();
    final validationError = state.validationBeforeResults();
    if (validationError != null) return false;

    final model = state.toModel();
    final result = eosbEngine.calculateEndOfService(model);
    // تأكيد اتساق المكافأة مع نوع الإنهاء
    assert(
      (result.endOfServiceAmount -
                  EosbCalculator.calculateEndOfServiceAward(model))
              .abs() <
          0.01,
      'endOfServiceAmount must match calculateEndOfServiceAward',
    );

    ref.read(eosbFinalizedResultProvider.notifier).state = result;

    state = state.copyWith(
      showResults: true,
      stepIndex: EosbWizardState.totalSteps - 1,
    );
    return true;
  }

  void previousStep() {
    if (state.showResults) {
      resumeEditing();
      return;
    }
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1);
    }
  }

  /// العودة من شاشة النتائج لتعديل المعالج (الخطوة الحالية أو خطوة محددة).
  ///
  /// [stepIndex] null = آخر خطوة (3). 0 = البداية من نوع الإنهاء.
  void resumeEditing({int? stepIndex}) {
    flushAllInputs();
    ref.read(eosbFinalizedResultProvider.notifier).state = null;
    final target = (stepIndex ?? EosbWizardState.totalSteps - 1).clamp(
      0,
      EosbWizardState.totalSteps - 1,
    );
    state = state.copyWith(
      showResults: false,
      stepIndex: target,
    );
  }

  void goToStep(int index) {
    if (index < 0 || index >= EosbWizardState.totalSteps) return;
    ref.read(eosbFinalizedResultProvider.notifier).state = null;
    state = state.copyWith(stepIndex: index, showResults: false);
  }

  void reset() {
    ref.read(eosbFinalizedResultProvider.notifier).state = null;
    final salary = ref.read(salaryNotifierProvider);
    state = EosbWizardState(
      country: ref.read(gulfCountryProvider),
      basicSalary: salary.basicSalary,
      housingAllowance: salary.housingAllowance,
      otherAllowances: salary.otherAllowances,
    );
  }

  /// مكافأة نهاية الخدمة فقط — [EosbCalculator.calculateEndOfServiceAward].
  double calculateEndOfServiceAward() =>
      EosbCalculator.calculateEndOfServiceAward(state.toModel());

  /// حساب كامل من الحالة الحالية (معاينة مباشرة).
  EosbCalculationResult calculateEndOfService() =>
      eosbEngine.calculateEndOfService(state.toModel());
}

/// محرك الحساب الموحّد — يقرأ [EosbWizardState.toModel] ويطبّق:
/// - مكافأة نهاية الخدمة (م. 84/85 السعودية · م. 51 الإمارات)
/// - بدل إجازة سنوية · إجازات متبقية · تذكرة طيران (تقدير)
const eosbEngine = EosbCalculator();

final eosbWizardProvider =
    NotifierProvider<EosbWizardNotifier, EosbWizardState>(
  EosbWizardNotifier.new,
);

/// نتيجة حية — تتحدث فوراً مع أي تغيير في المعالج (معاينة + ملخص).
final eosbCalculatorProvider = Provider<EosbCalculationResult>((ref) {
  final wizard = ref.watch(eosbWizardProvider);
  return eosbEngine.calculateEndOfService(wizard.toModel());
});

/// نتيجة مُجمّدة عند «عرض النتيجة» — تبقى ثابتة على شاشة النتائج وPDF.
final eosbFinalizedResultProvider =
    StateProvider<EosbCalculationResult?>((ref) => null);

/// نتيجة العرض: حية في المعالج (تتزامن فوراً)، مجمّدة بعد إنهاء الخطوة 3.
///
/// المعاينة المباشرة وملخص المدخلات يمكنهما الاعتماد عليه دائماً —
/// أثناء المعالج يعاد توجيهه تلقائياً إلى [eosbCalculatorProvider].
final eosbResultsProvider = Provider<EosbCalculationResult>((ref) {
  final wizard = ref.watch(eosbWizardProvider);
  final live = ref.watch(eosbCalculatorProvider);
  if (!wizard.showResults) return live;

  final finalized = ref.watch(eosbFinalizedResultProvider);
  return finalized ?? live;
});

/// مكافأة نهاية الخدمة حسب نوع الإنهاء — للمعاينة السريعة.
final eosbEndOfServiceAwardProvider = Provider<double>((ref) {
  final wizard = ref.watch(eosbWizardProvider);
  return EosbCalculator.calculateEndOfServiceAward(wizard.toModel());
});

/// بنود المعاينة المباشرة — متزامنة مع [eosbResultsProvider].
final eosbPreviewLinesProvider = Provider<List<EosbPreviewLine>>((ref) {
  final result = ref.watch(eosbResultsProvider);
  return EosbPreviewLine.fromResult(result);
});

/// سطر في معاينة/ملخص المستحقات.
class EosbPreviewLine {
  const EosbPreviewLine({required this.labelAr, required this.amount});

  final String labelAr;
  final double amount;

  static List<EosbPreviewLine> fromResult(EosbCalculationResult result) {
    final m = result.input;
    return [
      EosbPreviewLine(
        labelAr: 'مكافأة نهاية الخدمة',
        amount: result.endOfServiceAmount,
      ),
      if (m.accruedLeaveDays > 0)
        EosbPreviewLine(
          labelAr: 'بدل الإجازات المتبقية',
          amount: result.cashLeaveAllowance,
        ),
      EosbPreviewLine(
        labelAr: 'بدل إجازة سنوية (تقدير)',
        amount: result.vacationAllowance,
      ),
      if (m.includeFlightTicket)
        EosbPreviewLine(
          labelAr: 'تذكرة طيران (تقدير)',
          amount: result.flightTicketAllowance,
        ),
      EosbPreviewLine(
        labelAr: 'الإجمالي المستحق',
        amount: result.totalEntitlements,
      ),
    ];
  }
}

/// @deprecated استخدم [eosbCalculatorProvider]
final eosbCalculationProvider = Provider<EosbModel>((ref) {
  return ref.watch(eosbCalculatorProvider).input;
});
