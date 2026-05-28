import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';

/// سجل محلي لحسابات نهاية الخدمة (Hive).
class EosbHistoryEntry {
  const EosbHistoryEntry({
    required this.id,
    required this.savedAt,
    required this.countryCode,
    required this.countryNameAr,
    required this.terminationSummary,
    required this.totalEntitlements,
    required this.endOfServiceAmount,
    required this.serviceYears,
    required this.currencySymbol,
  });

  final String id;
  final DateTime savedAt;
  final String countryCode;
  final String countryNameAr;
  final String terminationSummary;
  final double totalEntitlements;
  final double endOfServiceAmount;
  final double serviceYears;
  final String currencySymbol;

  factory EosbHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return EosbHistoryEntry(
      id: map['id'] as String,
      savedAt: DateTime.parse(map['savedAt'] as String),
      countryCode: map['countryCode'] as String,
      countryNameAr: map['countryNameAr'] as String,
      terminationSummary: map['terminationSummary'] as String,
      totalEntitlements: (map['totalEntitlements'] as num).toDouble(),
      endOfServiceAmount: (map['endOfServiceAmount'] as num).toDouble(),
      serviceYears: (map['serviceYears'] as num).toDouble(),
      currencySymbol: map['currencySymbol'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'countryCode': countryCode,
        'countryNameAr': countryNameAr,
        'terminationSummary': terminationSummary,
        'totalEntitlements': totalEntitlements,
        'endOfServiceAmount': endOfServiceAmount,
        'serviceYears': serviceYears,
        'currencySymbol': currencySymbol,
      };
}

/// حفظ وقراءة حسابات EOSB من صندوق Hive المشترك.
abstract final class EosbHistoryService {
  EosbHistoryService._();

  static const _storageKey = 'eosb_history_entries';
  static const _maxEntries = 50;

  static Future<bool> save(EosbCalculationResult result) async {
    final box = AppInitializer.historyBox;
    if (box == null) return false;

    final m = result.input;
    final entry = EosbHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      savedAt: DateTime.now(),
      countryCode: m.country.name,
      countryNameAr: m.country.nameAr,
      terminationSummary: m.terminationSummary,
      totalEntitlements: result.totalEntitlements,
      endOfServiceAmount: result.endOfServiceAmount,
      serviceYears: m.totalServiceYears,
      currencySymbol: m.country.currencySymbol,
    );

    final existing = loadAll();
    final next = [entry, ...existing].take(_maxEntries).toList();
    await box.put(_storageKey, next.map((e) => e.toMap()).toList());
    return true;
  }

  static List<EosbHistoryEntry> loadAll() {
    final box = AppInitializer.historyBox;
    if (box == null) return [];

    final raw = box.get(_storageKey);
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((e) => EosbHistoryEntry.fromMap(e))
        .toList();
  }
}
