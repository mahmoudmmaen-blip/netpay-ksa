import 'package:equatable/equatable.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netpay_ksa/features/gosi/domain/enums/nationality_type.dart';

class GosiCalculationInput extends Equatable {
  const GosiCalculationInput({
    required this.grossSalary,
    required this.nationality,
    required this.regime,
    this.calculationDate,
    this.customWageCeiling,
  });

  final double grossSalary;
  final NationalityType nationality;
  final GosiRegime regime;

  /// Used to resolve the July phase for [GosiRegime.newLawPhased].
  final DateTime? calculationDate;
  final double? customWageCeiling;

  @override
  List<Object?> get props => [
        grossSalary,
        nationality,
        regime,
        calculationDate,
        customWageCeiling,
      ];
}
