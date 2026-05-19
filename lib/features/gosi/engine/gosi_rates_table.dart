import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/gosi/domain/entities/gosi_rate_breakdown.dart';
import 'package:netgulf/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netgulf/features/gosi/domain/enums/nationality_type.dart';
import 'package:netgulf/features/gosi/domain/logic/gosi_rates_resolver.dart';

/// @Deprecated استخدم [GosiRatesResolver] — غلاف توافق خلفي.
class GosiRatesTable {
  GosiRatesTable._();

  static int resolvePhaseYear(DateTime date) =>
      GosiRatesResolver.resolvePhaseYear(date);

  static GosiRateBreakdown employeeRates({
    required NationalityType nationality,
    required GosiRegime regime,
    required DateTime calculationDate,
  }) =>
      GosiRatesResolver.employeeRates(
        nationality: nationality,
        regime: regime,
        calculationDate: calculationDate,
      );

  static GosiRateBreakdown employerRates({
    required NationalityType nationality,
    required GosiRegime regime,
    required DateTime calculationDate,
  }) =>
      GosiRatesResolver.employerRates(
        nationality: nationality,
        regime: regime,
        calculationDate: calculationDate,
      );

  static List<({int year, double employeeTotal, double employerTotal})>
      newLawSchedule() {
    return GosiPhaseRate.schedule2025to2028()
        .map(
          (p) => (
            year: p.phaseYear,
            employeeTotal: p.employeeTotalPercent,
            employerTotal: p.employerTotalPercent,
          ),
        )
        .toList();
  }
}
