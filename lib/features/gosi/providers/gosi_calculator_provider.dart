import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netpay_ksa/features/gosi/domain/logic/gosi_calculator.dart';

final gosiCalculatorProvider = Provider<GosiCalculator>((ref) {
  return const GosiCalculator();
});
