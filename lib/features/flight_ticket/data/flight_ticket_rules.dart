import 'package:netgulf/core/domain/gulf_country.dart';

enum FlightTicketFrequency { annual, biennial }

enum FlightDestinationRegion {
  domestic,
  gcc,
  asia,
  europe,
  americas,
}

class FlightTicketCountryRule {
  const FlightTicketCountryRule({
    required this.frequency,
    required this.noteAr,
  });

  final FlightTicketFrequency frequency;
  final String noteAr;
}

const Map<FlightDestinationRegion, double> defaultTicketCostByRegion = {
  FlightDestinationRegion.domestic: 500,
  FlightDestinationRegion.gcc: 800,
  FlightDestinationRegion.asia: 1500,
  FlightDestinationRegion.europe: 3000,
  FlightDestinationRegion.americas: 5000,
};

String flightRegionLabelAr(FlightDestinationRegion r) => switch (r) {
      FlightDestinationRegion.domestic => 'داخل الدولة',
      FlightDestinationRegion.gcc => 'دول الخليج',
      FlightDestinationRegion.asia => 'آسيا',
      FlightDestinationRegion.europe => 'أوروبا',
      FlightDestinationRegion.americas => 'أمريكا',
    };

FlightTicketCountryRule flightTicketRuleFor(GulfCountry country) =>
    switch (country) {
      GulfCountry.saudiArabia => const FlightTicketCountryRule(
          frequency: FlightTicketFrequency.annual,
          noteAr: 'سنوية — تشمل العائلة إن نص العقد',
        ),
      GulfCountry.uae => const FlightTicketCountryRule(
          frequency: FlightTicketFrequency.annual,
          noteAr: 'سنوية — المبلغ يختلف حسب الشركة',
        ),
      GulfCountry.qatar => const FlightTicketCountryRule(
          frequency: FlightTicketFrequency.annual,
          noteAr: 'سنوية — درجة اقتصادية لبلد الأم',
        ),
      GulfCountry.kuwait => const FlightTicketCountryRule(
          frequency: FlightTicketFrequency.annual,
          noteAr: 'سنوية وفق قانون العمل',
        ),
      GulfCountry.bahrain => const FlightTicketCountryRule(
          frequency: FlightTicketFrequency.annual,
          noteAr: 'سنوية وفق قانون العمل',
        ),
      GulfCountry.oman => const FlightTicketCountryRule(
          frequency: FlightTicketFrequency.annual,
          noteAr: 'سنوية وفق قانون العمل',
        ),
    };
