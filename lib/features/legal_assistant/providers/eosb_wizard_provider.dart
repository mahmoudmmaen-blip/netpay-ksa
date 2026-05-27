import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/providers/gulf_country_provider.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// حالة معالج حاسبة نهاية الخدمة.
class EosbWizardState {
  const EosbWizardState({
    this.stepIndex = 0,
    this.terminationType,
    this.country = GulfCountry.saudiArabia,
    this.years = 0,
    this.months = 0,
    this.days = 0,
    this.basicSalary = 0,
    this.housingAllowance = 0,
    this.contractType = EosbContractType.unlimited,
    this.accruedLeaveDays = 0,
    this.includeFlightTicket = false,
    this.ticketCost = 0,
    this.ticketFrequency = FlightTicketFrequency.yearly,
    this.noticeProvided = true,
    this.showResults = false,
  });

  final int stepIndex;
  final EosbTerminationType? terminationType;
  final GulfCountry country;
  final int years;
  final int months;
  final int days;
  final double basicSalary;
  final double housingAllowance;
  final EosbContractType contractType;
  final int accruedLeaveDays;
  final bool includeFlightTicket;
  final double ticketCost;
  final FlightTicketFrequency ticketFrequency;
  final bool noticeProvided;
  final bool showResults;

  static const int totalSteps = 3;

  bool get canProceedStep0 => terminationType != null;

  bool get canProceedStep1 =>
      basicSalary > 0 && (years > 0 || months > 0 || days > 0);

  EosbModel toModel() => EosbModel(
        country: country,
        yearsOfService: years,
        monthsOfService: months,
        daysOfService: days,
        basicSalary: basicSalary,
        housingAllowance: housingAllowance,
        contractType: contractType,
        terminationType:
            terminationType ?? EosbTerminationType.employerDismissalUnfair,
        ticketCost: ticketCost,
        includeFlightTicket: includeFlightTicket,
        ticketFrequency: ticketFrequency,
        accruedLeaveDays: accruedLeaveDays,
        noticeProvided: noticeProvided,
      );

  EosbWizardState copyWith({
    int? stepIndex,
    EosbTerminationType? terminationType,
    bool clearTermination = false,
    GulfCountry? country,
    int? years,
    int? months,
    int? days,
    double? basicSalary,
    double? housingAllowance,
    EosbContractType? contractType,
    int? accruedLeaveDays,
    bool? includeFlightTicket,
    double? ticketCost,
    FlightTicketFrequency? ticketFrequency,
    bool? noticeProvided,
    bool? showResults,
  }) {
    return EosbWizardState(
      stepIndex: stepIndex ?? this.stepIndex,
      terminationType:
          clearTermination ? null : (terminationType ?? this.terminationType),
      country: country ?? this.country,
      years: years ?? this.years,
      months: months ?? this.months,
      days: days ?? this.days,
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      contractType: contractType ?? this.contractType,
      accruedLeaveDays: accruedLeaveDays ?? this.accruedLeaveDays,
      includeFlightTicket: includeFlightTicket ?? this.includeFlightTicket,
      ticketCost: ticketCost ?? this.ticketCost,
      ticketFrequency: ticketFrequency ?? this.ticketFrequency,
      noticeProvided: noticeProvided ?? this.noticeProvided,
      showResults: showResults ?? this.showResults,
    );
  }
}

class EosbWizardNotifier extends Notifier<EosbWizardState> {
  @override
  EosbWizardState build() {
    final country = ref.watch(gulfCountryProvider);
    final salary = ref.watch(salaryNotifierProvider);
    return EosbWizardState(
      country: country,
      basicSalary: salary.basicSalary,
      housingAllowance: salary.housingAllowance,
    );
  }

  void setTermination(EosbTerminationType type) {
    state = state.copyWith(terminationType: type);
  }

  void setCountry(GulfCountry country) {
    state = state.copyWith(country: country);
  }

  void setContractType(EosbContractType type) {
    state = state.copyWith(contractType: type);
  }

  void setServiceDuration({int? years, int? months, int? days}) {
    state = state.copyWith(
      years: years ?? state.years,
      months: months ?? state.months,
      days: days ?? state.days,
    );
  }

  void setSalaries({double? basic, double? housing}) {
    state = state.copyWith(
      basicSalary: basic,
      housingAllowance: housing,
    );
  }

  void setAccruedLeave(int days) {
    state = state.copyWith(accruedLeaveDays: days);
  }

  void setFlightTicket({required bool include, double? cost}) {
    state = state.copyWith(
      includeFlightTicket: include,
      ticketCost: cost,
    );
  }

  void setTicketFrequency(FlightTicketFrequency f) {
    state = state.copyWith(ticketFrequency: f);
  }

  void setNoticeProvided(bool value) {
    state = state.copyWith(noticeProvided: value);
  }

  bool nextStep() {
    if (state.showResults) return false;
    if (state.stepIndex == 0 && !state.canProceedStep0) return false;
    if (state.stepIndex == 1 && !state.canProceedStep1) return false;
    if (state.stepIndex >= EosbWizardState.totalSteps - 1) {
      state = state.copyWith(showResults: true);
      return true;
    }
    state = state.copyWith(stepIndex: state.stepIndex + 1);
    return true;
  }

  void previousStep() {
    if (state.showResults) {
      state = state.copyWith(showResults: false);
      return;
    }
    if (state.stepIndex > 0) {
      state = state.copyWith(stepIndex: state.stepIndex - 1);
    }
  }

  void goToStep(int index) {
    if (index < 0 || index >= EosbWizardState.totalSteps) return;
    state = state.copyWith(stepIndex: index, showResults: false);
  }

  void reset() {
    state = EosbWizardState(country: ref.read(gulfCountryProvider));
  }
}

final eosbWizardProvider =
    NotifierProvider<EosbWizardNotifier, EosbWizardState>(
  EosbWizardNotifier.new,
);

final eosbCalculationProvider = Provider<EosbModel>((ref) {
  return ref.watch(eosbWizardProvider).toModel();
});
