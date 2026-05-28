import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/presentation/widgets/eosb_country_grid.dart';

void main() {
  testWidgets('EosbCountryGrid shows all 6 GCC countries', (tester) async {
    var selected = GulfCountry.saudiArabia;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: EosbCountryGrid(
              selected: selected,
              onSelected: (c) => selected = c,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(EosbCountryGrid.gccCountries, hasLength(6));
    for (final country in EosbCountryGrid.gccCountries) {
      expect(find.text(country.nameAr), findsOneWidget);
      expect(find.text(country.nameEn), findsOneWidget);
      expect(find.text(country.flag), findsOneWidget);
      expect(find.text(country.eosPensionSchemeLabel), findsOneWidget);
    }

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.text('قطر'));
    await tester.pumpAndSettle();
    expect(selected, GulfCountry.qatar);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('الكويت'), findsOneWidget);
    expect(find.text('البحرين'), findsOneWidget);
  });
}
