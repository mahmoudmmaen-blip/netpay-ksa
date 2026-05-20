import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/features/salary_calculator/models/salary_record.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

const _kHistoryKey = 'salary_history_v1';

class HistoryNotifier extends AsyncNotifier<List<SalaryRecord>> {
  @override
  Future<List<SalaryRecord>> build() async => _load();

  bool get _isPremium => ref.read(isPremiumProvider);

  int get maxRecords =>
      _isPremium ? 9999 : AppConstants.freeHistoryRecordLimit;

  /// هل يمكن إضافة سجل جديد (حسب حد Premium).
  Future<bool> canSaveMore() async {
    if (_isPremium) return true;
    final current = await future;
    return current.length < AppConstants.freeHistoryRecordLimit;
  }

  /// يحفظ الحالة الحالية كسجل جديد.
  Future<bool> saveCurrentSalary(String label) async {
    if (!await canSaveMore()) return false;

    final salaryState = ref.read(salaryNotifierProvider);
    final gosi = salaryState.gosi;
    if (gosi == null) return false;

    final record = SalaryRecord(
      id: const Uuid().v4(),
      savedAt: DateTime.now(),
      label: label.trim().isEmpty ? _defaultLabel() : label.trim(),
      basicSalary: salaryState.basicSalary,
      housingAllowance: salaryState.housingAllowance,
      otherAllowances: salaryState.otherAllowances,
      includeOtherInGosiBase: salaryState.includeOtherInGosiBase,
      nationality: salaryState.nationality,
      regime: salaryState.regime,
      gosi: gosi,
    );

    final current = await future;
    final updated = [record, ...current].take(maxRecords).toList();
    await _save(updated);
    state = AsyncData(updated);
    return true;
  }

  /// يحذف سجل بالـ ID.
  Future<void> delete(String id) async {
    final current = await future;
    final updated = current.where((r) => r.id != id).toList();
    await _save(updated);
    state = AsyncData(updated);
  }

  /// يمسح كل السجلات.
  Future<void> clearAll() async {
    await _save([]);
    state = const AsyncData([]);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  String _defaultLabel() {
    final now = DateTime.now();
    return 'راتب ${now.day}/${now.month}/${now.year}';
  }

  Future<List<SalaryRecord>> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHistoryKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SalaryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<SalaryRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kHistoryKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}

final historyNotifierProvider =
    AsyncNotifierProvider<HistoryNotifier, List<SalaryRecord>>(
  HistoryNotifier.new,
);