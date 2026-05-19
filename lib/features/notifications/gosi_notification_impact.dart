import 'package:netgulf/features/gosi/domain/logic/gosi_calculator.dart';
import 'package:netgulf/features/salary_calculator/models/gosi_model.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// عرض تنبيه GOSI مع أثر شهري على صافي الراتب.
class GosiNotificationItem {
  const GosiNotificationItem({
    required this.warning,
    required this.monthlyNetImpactSar,
    required this.monthlyGosiIncreaseSar,
  });

  final GosiRateWarning warning;
  final double monthlyNetImpactSar;
  final double monthlyGosiIncreaseSar;
}

/// يبني قائمة الزيادات القادمة مع أثر مالي من الراتب الحالي.
List<GosiNotificationItem> buildUpcomingGosiNotificationItems(
  SalaryState salary,
  GosiCalculator calculator,
) {
  final gosi = salary.gosi;
  if (gosi == null) return const [];

  final warnings = gosi.upcomingWarnings;
  if (warnings.isEmpty) return const [];

  return warnings.map((w) {
    final impact = _monthlyImpact(salary, w, calculator);
    return GosiNotificationItem(
      warning: w,
      monthlyNetImpactSar: impact.netDrop,
      monthlyGosiIncreaseSar: impact.gosiIncrease,
    );
  }).toList();
}

({double netDrop, double gosiIncrease}) _monthlyImpact(
  SalaryState salary,
  GosiRateWarning warning,
  GosiCalculator calculator,
) {
  try {
    final current = GosiModel.fromSalaryForm(
      allowances: salary.allowances,
      nationality: salary.nationality,
      regime: salary.regime,
      calculationDate: salary.effectiveDate,
      calculator: calculator,
    );
    final future = GosiModel.fromSalaryForm(
      allowances: salary.allowances,
      nationality: salary.nationality,
      regime: salary.regime,
      calculationDate: warning.effectiveDate,
      calculator: calculator,
    );
    final gosiIncrease = future.employeeGosi - current.employeeGosi;
    final netDrop = current.netSalary - future.netSalary;
    return (
      netDrop: netDrop > 0 ? netDrop : 0,
      gosiIncrease: gosiIncrease > 0 ? gosiIncrease : 0,
    );
  } catch (_) {
    return (netDrop: 0, gosiIncrease: 0);
  }
}

/// هل توجد زيادة خلال [withinDays] يوماً؟
bool hasGosiIncreaseWithinDays(
  SalaryState salary,
  GosiCalculator calculator, {
  int withinDays = 30,
}) {
  final items = buildUpcomingGosiNotificationItems(salary, calculator);
  if (items.isEmpty) return false;
  return items.any((i) => i.warning.daysUntilEffective <= withinDays);
}
