import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/utils/feature_hive_store.dart';
import 'package:netgulf/features/flight_ticket/data/flight_ticket_rules.dart';

const _hiveBox = 'flight_ticket';

class FlightTicketState {
  const FlightTicketState({
    this.country = GulfCountry.saudiArabia,
    this.frequency = FlightTicketFrequency.annual,
    this.familyMembers = 1,
    this.region = FlightDestinationRegion.gcc,
    this.ticketCost = 800,
    this.monthlySalary = 0,
  });

  final GulfCountry country;
  final FlightTicketFrequency frequency;
  final int familyMembers;
  final FlightDestinationRegion region;
  final double ticketCost;
  final double monthlySalary;

  double get annualValue =>
      ticketCost * familyMembers.clamp(1, 4) *
      (frequency == FlightTicketFrequency.annual ? 1 : 0.5);

  double get monthlyEquivalent => annualValue / 12;

  FlightTicketState copyWith({
    GulfCountry? country,
    FlightTicketFrequency? frequency,
    int? familyMembers,
    FlightDestinationRegion? region,
    double? ticketCost,
    double? monthlySalary,
  }) {
    return FlightTicketState(
      country: country ?? this.country,
      frequency: frequency ?? this.frequency,
      familyMembers: familyMembers ?? this.familyMembers,
      region: region ?? this.region,
      ticketCost: ticketCost ?? this.ticketCost,
      monthlySalary: monthlySalary ?? this.monthlySalary,
    );
  }
}

class FlightTicketNotifier extends StateNotifier<FlightTicketState> {
  FlightTicketNotifier() : super(const FlightTicketState()) {
    _load();
  }

  Future<void> _load() async {
    final cost = await FeatureHiveStore.get<double>(_hiveBox, 'cost');
    if (cost != null) state = state.copyWith(ticketCost: cost);
  }

  void setCountry(GulfCountry c) {
    final rule = flightTicketRuleFor(c);
    state = state.copyWith(
      country: c,
      frequency: rule.frequency,
      ticketCost: defaultTicketCostByRegion[state.region] ?? 800,
    );
  }

  void setFrequency(FlightTicketFrequency f) =>
      state = state.copyWith(frequency: f);

  void setFamily(int n) =>
      state = state.copyWith(familyMembers: n.clamp(1, 4));

  void setRegion(FlightDestinationRegion r) => state = state.copyWith(
        region: r,
        ticketCost: defaultTicketCostByRegion[r] ?? state.ticketCost,
      );

  void setTicketCost(double v) {
    state = state.copyWith(ticketCost: v);
    FeatureHiveStore.put(_hiveBox, 'cost', v);
  }

  void setMonthlySalary(double v) => state = state.copyWith(monthlySalary: v);
}

final flightTicketProvider =
    StateNotifierProvider<FlightTicketNotifier, FlightTicketState>(
  (ref) => FlightTicketNotifier(),
);
