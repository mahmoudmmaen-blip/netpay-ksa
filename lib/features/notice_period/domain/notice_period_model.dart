import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_calculator.dart';

/// نموذج بيانات حاسبة إشعار الإنهاء.
class NoticePeriodModel {
  const NoticePeriodModel({
    required this.country,
    required this.monthlyBasicSalary,
    this.serviceYears = 0,
    this.serviceMonths = 0,
    this.contractType = EosbContractType.unlimited,
    this.noticeWasGiven = false,
    this.daysNoticeGiven = 0,
  });

  final GulfCountry country;
  final double monthlyBasicSalary;
  final int serviceYears;
  final int serviceMonths;
  final EosbContractType contractType;
  final bool noticeWasGiven;
  final int daysNoticeGiven;

  /// إجمالي الخدمة بالسنوات (للحساب القانوني).
  double get totalServiceYears => serviceYears + serviceMonths / 12;

  int get requiredNoticeDays => NoticePeriodCalculator.requiredDays(this);

  int get missingDays =>
      (requiredNoticeDays - daysNoticeGiven).clamp(0, 999);

  double get compensationAmount => NoticePeriodCalculator.compensation(this);

  double get dailyWage => monthlyBasicSalary / 30;

  String get legalReference => NoticePeriodCalculator.legalReference(country);

  NoticePeriodModel copyWith({
    GulfCountry? country,
    double? monthlyBasicSalary,
    int? serviceYears,
    int? serviceMonths,
    EosbContractType? contractType,
    bool? noticeWasGiven,
    int? daysNoticeGiven,
  }) {
    return NoticePeriodModel(
      country: country ?? this.country,
      monthlyBasicSalary: monthlyBasicSalary ?? this.monthlyBasicSalary,
      serviceYears: serviceYears ?? this.serviceYears,
      serviceMonths: serviceMonths ?? this.serviceMonths,
      contractType: contractType ?? this.contractType,
      noticeWasGiven: noticeWasGiven ?? this.noticeWasGiven,
      daysNoticeGiven: daysNoticeGiven ?? this.daysNoticeGiven,
    );
  }
}
