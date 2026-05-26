import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/share/widgets/salary_share_card.dart';

import '../../test_utils/create_localized_test_widget.dart';

void main() {
  testWidgets('SalaryShareCard shows net salary label', (tester) async {
    // Use the same localization + RTL shell as production.
    await tester.pumpWidget(
      createLocalizedTestApp(
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

    // Prefer production constants to avoid hardcoded app identity leakage.
    expect(find.textContaining(AppConstants.appNameAr), findsOneWidget);
    // NOTE: SalaryShareCard currently hardcodes Arabic labels (no l10n keys exist).
    expect(find.text('صافي الراتب'), findsOneWidget);
  });
}
