import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:netgulf/features/salary_calculator/models/salary_record.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// يبني سجل راتب من الحالة الحالية للتصدير.
SalaryRecord? buildCurrentSalaryRecord(WidgetRef ref, {String? label}) {
  final salaryState = ref.read(salaryNotifierProvider);
  final gosi = salaryState.gosi;
  if (gosi == null || gosi.netSalary <= 0) return null;

  return SalaryRecord(
    id: const Uuid().v4(),
    savedAt: DateTime.now(),
    label: label ?? 'راتب ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
    basicSalary: salaryState.basicSalary,
    housingAllowance: salaryState.housingAllowance,
    otherAllowances: salaryState.otherAllowances,
    includeOtherInGosiBase: salaryState.includeOtherInGosiBase,
    nationality: salaryState.nationality,
    regime: salaryState.regime,
    gosi: gosi,
  );
}
