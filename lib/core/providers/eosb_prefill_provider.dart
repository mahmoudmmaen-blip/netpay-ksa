import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/domain/gulf_country.dart';

/// تعبئة مسبقة لمعالج نهاية الخدمة (من تحليل العقد).
class EosbPrefillData {
  const EosbPrefillData({
    required this.country,
    required this.basicSalary,
  });

  final GulfCountry country;
  final double basicSalary;
}

final eosbPrefillProvider = StateProvider<EosbPrefillData?>((ref) => null);
