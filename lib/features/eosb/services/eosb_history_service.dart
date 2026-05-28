import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/features/eosb/domain/logic/eosb_calculator.dart';
import 'package:netgulf/features/eosb/domain/models/eosb_model.dart';

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
    this.modelSnapshot,
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

  /// لاستعادة الحساب وعرض شاشة النتائج.
  final Map<String, dynamic>? modelSnapshot;

  bool get canOpenDetails => modelSnapshot != null;

  factory EosbHistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    final snapshot = map['modelSnapshot'];
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
      modelSnapshot: snapshot is Map
          ? Map<String, dynamic>.from(snapshot)
          : null,
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
        if (modelSnapshot != null) 'modelSnapshot': modelSnapshot,
      };

  EosbModel? toModel() {
    final snap = modelSnapshot;
    if (snap == null) return null;
    try {
      return EosbModel(
        country: GulfCountry.values.byName(snap['country'] as String),
        yearsOfService: (snap['yearsOfService'] as num).toInt(),
        monthsOfService: (snap['monthsOfService'] as num).toInt(),
        daysOfService: (snap['daysOfService'] as num).toInt(),
        basicSalary: (snap['basicSalary'] as num).toDouble(),
        housingAllowance: (snap['housingAllowance'] as num).toDouble(),
        otherAllowances: (snap['otherAllowances'] as num).toDouble(),
        contractType: EosbContractType.values.byName(
          snap['contractType'] as String,
        ),
        terminationType: EosbTerminationType.values.byName(
          snap['terminationType'] as String,
        ),
        ticketCost: (snap['ticketCost'] as num).toDouble(),
        includeFlightTicket: snap['includeFlightTicket'] as bool,
        ticketFrequency: FlightTicketFrequency.values.byName(
          snap['ticketFrequency'] as String,
        ),
        accruedLeaveDays: (snap['accruedLeaveDays'] as num).toInt(),
        noticeProvided: snap['noticeProvided'] as bool,
        mutualAgreementPercent:
            (snap['mutualAgreementPercent'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// حفظ وقراءة حسابات EOSB من صندوق Hive المشترك.
abstract final class EosbHistoryService {
  EosbHistoryService._();

  static const _storageKey = 'eosb_history_entries';
  static const _maxEntries = 50;

  /// للاختبارات — صندوق Hive بديل عن [AppInitializer.historyBox].
  @visibleForTesting
  static Box<dynamic>? testHistoryBoxOverride;

  static Box<dynamic>? get _historyBox =>
      testHistoryBoxOverride ?? AppInitializer.historyBox;

  @visibleForTesting
  static void setHistoryBoxForTesting(Box<dynamic>? box) {
    testHistoryBoxOverride = box;
  }

  @visibleForTesting
  static Future<void> clearAllForTesting() async {
    final box = _historyBox;
    if (box == null) return;
    await box.delete(_storageKey);
  }

  static Map<String, dynamic> _modelSnapshot(EosbModel m) => {
        'country': m.country.name,
        'yearsOfService': m.yearsOfService,
        'monthsOfService': m.monthsOfService,
        'daysOfService': m.daysOfService,
        'basicSalary': m.basicSalary,
        'housingAllowance': m.housingAllowance,
        'otherAllowances': m.otherAllowances,
        'contractType': m.contractType.name,
        'terminationType': m.terminationType.name,
        'ticketCost': m.ticketCost,
        'includeFlightTicket': m.includeFlightTicket,
        'ticketFrequency': m.ticketFrequency.name,
        'accruedLeaveDays': m.accruedLeaveDays,
        'noticeProvided': m.noticeProvided,
        'mutualAgreementPercent': m.mutualAgreementPercent,
      };

  static Future<bool> save(EosbCalculationResult result) async {
    final box = _historyBox;
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
      modelSnapshot: _modelSnapshot(m),
    );

    final existing = loadAll();
    final next = [entry, ...existing].take(_maxEntries).toList();
    await _persist(next);
    return true;
  }

  static Future<bool> delete(String id) async {
    final box = _historyBox;
    if (box == null) return false;
    final next = loadAll().where((e) => e.id != id).toList();
    await _persist(next);
    return true;
  }

  static EosbHistoryEntry? getById(String id) {
    for (final e in loadAll()) {
      if (e.id == id) return e;
    }
    return null;
  }

  static EosbCalculationResult? calculationResultFor(EosbHistoryEntry entry) {
    final model = entry.toModel();
    if (model == null) return null;
    return const EosbCalculator().calculateEndOfService(model);
  }

  static List<EosbHistoryEntry> loadAll() {
    final box = _historyBox;
    if (box == null) return [];

    final raw = box.get(_storageKey);
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((e) => EosbHistoryEntry.fromMap(e))
        .toList();
  }

  static Future<void> _persist(List<EosbHistoryEntry> entries) async {
    final box = _historyBox;
    if (box == null) return;
    await box.put(_storageKey, entries.map((e) => e.toMap()).toList());
  }
}
