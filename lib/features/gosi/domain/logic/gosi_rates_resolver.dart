import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/gosi/domain/entities/gosi_rate_breakdown.dart';
import 'package:netgulf/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netgulf/features/gosi/domain/enums/nationality_type.dart';

/// حلّ نسب GOSI الرسمية — مصدر واحد للحقيقة (2025–2028).
///
/// النظام القديم (موظف مسجّل قبل يوليو 2024):
///   موظف 9.75% = 9% تقاعد + 0.75% ساند
///   صاحب عمل 11.75% = 9% + 2% أخطار + 0.75% ساند
///
/// النظام الجديد (0.25% ساند + تقاعد مرحلي +0.5% كل يوليو):
///   2025→9.75% | 2026→10.25% | 2027→10.75% | 2028→11.25% (موظف)
abstract final class GosiRatesResolver {
  GosiRatesResolver._();

  /// سنة مرحلة يوليو النشطة لتاريخ الحساب.
  ///
  /// قبل 1 يوليو: تُحسب المرحلة على سنة سابقة
  /// (مثال: مارس 2026 → مرحلة 2025 → 9.75%).
  static int resolvePhaseYear(DateTime date) {
    final julyFirst = DateTime(date.year, 7, 1);
    final effectiveYear =
        date.isBefore(julyFirst) ? date.year - 1 : date.year;
    return effectiveYear.clamp(
      GosiConstants.phasedIncreaseStartYear,
      GosiConstants.phasedIncreaseEndYear,
    );
  }

  static DateTime julyPhaseStart(int phaseYear) => DateTime(phaseYear, 7, 1);

  static GosiRateBreakdown employeeRates({
    required NationalityType nationality,
    required GosiRegime regime,
    required DateTime calculationDate,
  }) {
    if (!nationality.isSaudi) {
      return const GosiRateBreakdown(
        pensionPercent: 0,
        occupationalHazardPercent: 0,
        sanedPercent: 0,
        totalPercent: GosiConstants.nonSaudiEmployeePercent,
      );
    }

    return switch (regime) {
      GosiRegime.legacy => _legacyEmployee(),
      GosiRegime.newLawPhased => _newLawEmployee(
          resolvePhaseYear(calculationDate),
        ),
    };
  }

  static GosiRateBreakdown employerRates({
    required NationalityType nationality,
    required GosiRegime regime,
    required DateTime calculationDate,
  }) {
    if (!nationality.isSaudi) {
      return const GosiRateBreakdown(
        pensionPercent: 0,
        occupationalHazardPercent:
            GosiConstants.employerOccupationalHazardPercent,
        sanedPercent: 0,
        totalPercent: GosiConstants.nonSaudiEmployerPercent,
      );
    }

    return switch (regime) {
      GosiRegime.legacy => _legacyEmployer(),
      GosiRegime.newLawPhased => _newLawEmployer(
          resolvePhaseYear(calculationDate),
        ),
    };
  }

  // ── قديم: 9.75% / 11.75% ─────────────────────────────────────────────────

  static GosiRateBreakdown _legacyEmployee() {
    return const GosiRateBreakdown(
      pensionPercent: GosiConstants.legacyPensionPercent,
      occupationalHazardPercent: 0,
      sanedPercent: GosiConstants.legacySanedPercent,
      totalPercent: GosiConstants.legacyEmployeeTotalPercent,
    );
  }

  static GosiRateBreakdown _legacyEmployer() {
    return const GosiRateBreakdown(
      pensionPercent: GosiConstants.legacyPensionPercent,
      occupationalHazardPercent:
          GosiConstants.employerOccupationalHazardPercent,
      sanedPercent: GosiConstants.legacySanedPercent,
      totalPercent: GosiConstants.legacyEmployerTotalPercent,
    );
  }

  // ── جديد: مرحلي ─────────────────────────────────────────────────────────

  static GosiRateBreakdown _newLawEmployee(int phaseYear) {
    final pension = _pensionForPhase(phaseYear);
    const saned = GosiConstants.newLawSanedPercent;
    return GosiRateBreakdown(
      pensionPercent: pension,
      occupationalHazardPercent: 0,
      sanedPercent: saned,
      totalPercent: pension + saned,
    );
  }

  static GosiRateBreakdown _newLawEmployer(int phaseYear) {
    final pension = _pensionForPhase(phaseYear);
    const saned = GosiConstants.newLawSanedPercent;
    const hazard = GosiConstants.employerOccupationalHazardPercent;
    return GosiRateBreakdown(
      pensionPercent: pension,
      occupationalHazardPercent: hazard,
      sanedPercent: saned,
      totalPercent: pension + hazard + saned,
    );
  }

  static double _pensionForPhase(int phaseYear) {
    return GosiConstants.newLawPensionPercentByPhaseYear[phaseYear] ??
        GosiConstants.newLawPensionPercentByPhaseYear[
            GosiConstants.phasedIncreaseEndYear]!;
  }

  /// كل زيادات يوليو القادمة (للتنبيهات).
  static List<({int phaseYear, double employeePercent, double employerPercent})>
      upcomingPhasesFrom(DateTime date) {
    final currentPhase = resolvePhaseYear(date);
    final entries = GosiConstants.newLawPensionPercentByPhaseYear.entries
        .where((e) => e.key > currentPhase)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries.map((e) {
      final emp = _newLawEmployee(e.key).totalPercent;
      final er = _newLawEmployer(e.key).totalPercent;
      return (
        phaseYear: e.key,
        employeePercent: emp,
        employerPercent: er,
      );
    }).toList();
  }
}
