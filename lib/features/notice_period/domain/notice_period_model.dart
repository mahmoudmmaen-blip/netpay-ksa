import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_calculator.dart';

/// نموذج بيانات حاسبة إشعار الإنهاء.
class NoticePeriodModel {
  const NoticePeriodModel({
    required this.country,
    required this.monthlyBasicSalary,
    required this.totalServiceYears,
    this.contractType = EosbContractType.unlimited,
    this.noticeWasGiven = false,
    this.daysNoticeGiven = 0,
  });

  final GulfCountry country;
  final double monthlyBasicSalary;
  final double totalServiceYears;
  final EosbContractType contractType;
  final bool noticeWasGiven;
  final int daysNoticeGiven;

  int get requiredNoticeDays => NoticePeriodCalculator.requiredDays(this);

  int get missingDays =>
      (requiredNoticeDays - daysNoticeGiven).clamp(0, 999);

  double get compensationAmount => NoticePeriodCalculator.compensation(this);

  double get dailyWage => monthlyBasicSalary / 30;

  String get legalReference => NoticePeriodCalculator.legalReference(country);

  NoticePeriodModel copyWith({
    GulfCountry? country,
    double? monthlyBasicSalary,
    double? totalServiceYears,
    EosbContractType? contractType,
    bool? noticeWasGiven,
    int? daysNoticeGiven,
  }) {
    return NoticePeriodModel(
      country: country ?? this.country,
      monthlyBasicSalary: monthlyBasicSalary ?? this.monthlyBasicSalary,
      totalServiceYears: totalServiceYears ?? this.totalServiceYears,
      contractType: contractType ?? this.contractType,
      noticeWasGiven: noticeWasGiven ?? this.noticeWasGiven,
      daysNoticeGiven: daysNoticeGiven ?? this.daysNoticeGiven,
    );
  }
}
