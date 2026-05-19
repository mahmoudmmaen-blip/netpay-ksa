import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/features/share/widgets/salary_share_card.dart';

void main() {
  testWidgets('SalaryShareCard shows net salary label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SalaryShareCard(
            data: SalaryShareData(
              netSalary: 8500,
              grossSalary: 10000,
              gosiDeduction: 1500,
              date: DateTime(2026, 5, 19),
            ),
          ),
        ),
      ),
    );

    expect(find.text('صافي الراتب'), findsOneWidget);
    expect(find.textContaining('نت غلف'), findsOneWidget);
  });
}
