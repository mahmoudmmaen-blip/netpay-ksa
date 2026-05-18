import 'package:equatable/equatable.dart';

/// Percentage rates for one side (employee or employer).
class GosiRateBreakdown extends Equatable {
  const GosiRateBreakdown({
    required this.pensionPercent,
    required this.occupationalHazardPercent,
    required this.sanedPercent,
    required this.totalPercent,
  });

  /// Annuity / pension (التقاعد).
  final double pensionPercent;

  /// Occupational hazards (الأخطار المهنية) — employer only for Saudis.
  final double occupationalHazardPercent;

  /// SANED unemployment (ساند).
  final double sanedPercent;

  final double totalPercent;

  @override
  List<Object?> get props => [
        pensionPercent,
        occupationalHazardPercent,
        sanedPercent,
        totalPercent,
      ];
}
