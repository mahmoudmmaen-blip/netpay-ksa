import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_calculator.dart';
import 'package:netgulf/features/leave_balance/domain/leave_balance_model.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_calculator.dart';
import 'package:netgulf/features/notice_period/domain/notice_period_model.dart';

/// صف في جدول المقارنة.
class ComparisonRow {
  const ComparisonRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    this.higherIsBetter = true,
  });

  final String label;
  final String valueA;
  final String valueB;
  final bool higherIsBetter;
}

abstract final class CountryComparisonEngine {
  CountryComparisonEngine._();

  static double _employeeRate(GulfCountry c) => switch (c) {
        GulfCountry.saudiArabia => 0.1025,
        GulfCountry.uae => 0.05,
        GulfCountry.oman => 0.08,
        GulfCountry.qatar => 0.05,
        GulfCountry.bahrain => 0.08,
        GulfCountry.kuwait => 0.045,
      };

  static double netSalary(GulfCountry country, double gross) {
    if (gross <= 0) return 0;
    return gross * (1 - _employeeRate(country));
  }

  static double eosbAfterYears(GulfCountry country, double salary, double years) {
    if (salary <= 0 || years <= 0) return 0;
    final model = EosbModel(
      country: country,
      yearsOfService: years.floor(),
      monthsOfService: ((years % 1) * 12).round().clamp(0, 11),
      basicSalary: salary,
      housingAllowance: country.eosGratuityUsesBasicOnly ? 0 : salary * 0.25,
      terminationType: EosbTerminationType.employerDismissalUnfair,
    );
    return const EosbCalculator()
        .calculateEndOfService(model)
        .endOfServiceAmount;
  }

  static int noticeDays(GulfCountry country) {
    return NoticePeriodCalculator.requiredDays(
      NoticePeriodModel(
        country: country,
        monthlyBasicSalary: 1,
        serviceYears: 3,
      ),
    );
  }

  static int annualLeave(GulfCountry country) {
    return LeaveBalanceCalculator.annualDays(
      LeaveBalanceModel(country: country, serviceYears: 3),
    );
  }

  static String weeklyHours(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => '48',
        GulfCountry.uae => '48',
        GulfCountry.oman => '45',
        GulfCountry.qatar => '48',
        GulfCountry.bahrain => '48',
        GulfCountry.kuwait => '48',
      };

  static String maternityDays(GulfCountry country) => switch (country) {
        GulfCountry.saudiArabia => '70',
        GulfCountry.uae => '60',
        GulfCountry.oman => '98',
        GulfCountry.qatar => '50',
        GulfCountry.bahrain => '60',
        GulfCountry.kuwait => '70',
      };

  static String flightTicket(GulfCountry country) => 'نعم';

  static String pensionSystem(GulfCountry country) => country.schemeShort;

  static List<ComparisonRow> compare({
    required GulfCountry a,
    required GulfCountry b,
    required double salary,
  }) {
    final fmt = (GulfCountry c, double v) =>
        '${v.toStringAsFixed(0)} ${c.currencySymbol}';

    return [
      ComparisonRow(
        label: 'الراتب الصافي (بعد التأمينات)',
        valueA: fmt(a, netSalary(a, salary)),
        valueB: fmt(b, netSalary(b, salary)),
      ),
      ComparisonRow(
        label: 'نهاية الخدمة بعد سنة',
        valueA: fmt(a, eosbAfterYears(a, salary, 1)),
        valueB: fmt(b, eosbAfterYears(b, salary, 1)),
      ),
      ComparisonRow(
        label: 'نهاية الخدمة بعد 5 سنوات',
        valueA: fmt(a, eosbAfterYears(a, salary, 5)),
        valueB: fmt(b, eosbAfterYears(b, salary, 5)),
      ),
      ComparisonRow(
        label: 'نهاية الخدمة بعد 10 سنوات',
        valueA: fmt(a, eosbAfterYears(a, salary, 10)),
        valueB: fmt(b, eosbAfterYears(b, salary, 10)),
      ),
      ComparisonRow(
        label: 'مدة الإشعار (أيام)',
        valueA: '${noticeDays(a)}',
        valueB: '${noticeDays(b)}',
        higherIsBetter: false,
      ),
      ComparisonRow(
        label: 'الإجازة السنوية (أيام)',
        valueA: '${annualLeave(a)}',
        valueB: '${annualLeave(b)}',
      ),
      ComparisonRow(
        label: 'ساعات العمل الأسبوعية',
        valueA: weeklyHours(a),
        valueB: weeklyHours(b),
        higherIsBetter: false,
      ),
      ComparisonRow(
        label: 'إجازة الأمومة (أيام)',
        valueA: maternityDays(a),
        valueB: maternityDays(b),
      ),
      ComparisonRow(
        label: 'تذكرة السفر',
        valueA: flightTicket(a),
        valueB: flightTicket(b),
      ),
      ComparisonRow(
        label: 'نظام التقاعد',
        valueA: pensionSystem(a),
        valueB: pensionSystem(b),
        higherIsBetter: false,
      ),
    ];
  }
}
