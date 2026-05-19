import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/features/gosi/domain/logic/gosi_calculator.dart';

final gosiCalculatorProvider = Provider<GosiCalculator>((ref) {
  return const GosiCalculator();
});
