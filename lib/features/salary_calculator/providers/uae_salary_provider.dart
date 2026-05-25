import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/salary_calculator/models/uae_salary_model.dart';
import 'package:netgulf/features/uae/domain/models/uae_model.dart';

/// حالة مدخلات حاسبة الإمارات.
class UaeSalaryState extends Equatable {
  const UaeSalaryState({
    this.basicSalary = 10000,
    this.housingAllowance = 3000,
    this.transportationAllowance = 500,
    this.airTicketAllowanceMonthly = 400,
    this.yearsOfService = 2,
    this.unusedLeaveDays = 0,
    this.healthInsuranceMonthly = 150,
    this.visaFeesMonthly = 100,
    this.nationality = UAENationalityType.expat,
  });

  final double basicSalary;
  final double housingAllowance;
  final double transportationAllowance;
  final double airTicketAllowanceMonthly;
  final int yearsOfService;
  final int unusedLeaveDays;
  final double healthInsuranceMonthly;
  final double visaFeesMonthly;
  final UAENationalityType nationality;

  UaeSalaryModel get model => UaeSalaryModel(
        basicSalary: basicSalary,
        housingAllowance: housingAllowance,
        transportationAllowance: transportationAllowance,
        airTicketAllowanceMonthly: airTicketAllowanceMonthly,
        yearsOfService: yearsOfService,
        unusedLeaveDays: unusedLeaveDays,
        healthInsuranceMonthly: healthInsuranceMonthly,
        visaFeesMonthly: visaFeesMonthly,
        nationality: nationality,
      );

  UaeSalaryState copyWith({
    double? basicSalary,
    double? housingAllowance,
    double? transportationAllowance,
    double? airTicketAllowanceMonthly,
    int? yearsOfService,
    int? unusedLeaveDays,
    double? healthInsuranceMonthly,
    double? visaFeesMonthly,
    UAENationalityType? nationality,
  }) {
    return UaeSalaryState(
      basicSalary: basicSalary ?? this.basicSalary,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      transportationAllowance:
          transportationAllowance ?? this.transportationAllowance,
      airTicketAllowanceMonthly:
          airTicketAllowanceMonthly ?? this.airTicketAllowanceMonthly,
      yearsOfService: yearsOfService ?? this.yearsOfService,
      unusedLeaveDays: unusedLeaveDays ?? this.unusedLeaveDays,
      healthInsuranceMonthly:
          healthInsuranceMonthly ?? this.healthInsuranceMonthly,
      visaFeesMonthly: visaFeesMonthly ?? this.visaFeesMonthly,
      nationality: nationality ?? this.nationality,
    );
  }

  @override
  List<Object?> get props => [
        basicSalary,
        housingAllowance,
        transportationAllowance,
        airTicketAllowanceMonthly,
        yearsOfService,
        unusedLeaveDays,
        healthInsuranceMonthly,
        visaFeesMonthly,
        nationality,
      ];
}

/// UAE salary provider — Riverpod state for Emirates calculator.
class UaeSalaryNotifier extends Notifier<UaeSalaryState> {
  @override
  UaeSalaryState build() => const UaeSalaryState();

  void setBasic(double v) => state = state.copyWith(basicSalary: v);
  void setHousing(double v) => state = state.copyWith(housingAllowance: v);
  void setTransportation(double v) =>
      state = state.copyWith(transportationAllowance: v);
  void setAirTicket(double v) =>
      state = state.copyWith(airTicketAllowanceMonthly: v);
  void setYears(int v) => state = state.copyWith(yearsOfService: v);
  void setUnusedLeaveDays(int v) =>
      state = state.copyWith(unusedLeaveDays: v);
  void setHealthInsurance(double v) =>
      state = state.copyWith(healthInsuranceMonthly: v);
  void setVisaFees(double v) => state = state.copyWith(visaFeesMonthly: v);
  void setNationality(UAENationalityType v) =>
      state = state.copyWith(nationality: v);
}

final uaeSalaryNotifierProvider =
    NotifierProvider<UaeSalaryNotifier, UaeSalaryState>(
  UaeSalaryNotifier.new,
);

final uaeSalaryModelProvider = Provider<UaeSalaryModel>((ref) {
  return ref.watch(uaeSalaryNotifierProvider).model;
});
