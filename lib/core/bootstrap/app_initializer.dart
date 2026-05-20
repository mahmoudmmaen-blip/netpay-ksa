import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/services/admob_service.dart';
import 'package:netgulf/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// تهيئة الخدمات المحلية قبل [runApp] — Offline First.
///
/// الترتيب: Hive → صناديق التخزين → SharedPreferences.
abstract final class AppInitializer {
  AppInitializer._();

  static SharedPreferences? _prefs;
  static bool _hiveReady = false;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;
  static bool get isHiveReady => _hiveReady;

  static SharedPreferences get prefs {
    final p = _prefs;
    if (p == null) {
      throw StateError(
        'استدعِ AppInitializer.init() من main() قبل استخدام prefs.',
      );
    }
    return p;
  }

  /// تهيئة كاملة — آمنة للاستدعاء مرة واحدة فقط.
  static Future<void> init() async {
    if (_initialized) return;

    await _initHive();
    await _openHiveBoxes();
    await _initPreferences();
    await AdMobService.initialize();
    await NotificationService.instance.initialize();

    // TODO: تسجيل Hive TypeAdapters عند إضافة موديلات History

    _initialized = true;

    if (kDebugMode) {
      debugPrint(
        '✓ ${AppConstants.appNameEn} — Hive:$_hiveReady | prefs:ready',
      );
    }
  }

  static Future<void> dispose() async {
    if (_hiveReady) {
      await Hive.close();
      _hiveReady = false;
    }
    _prefs = null;
    _initialized = false;
  }

  // ── Hive ───────────────────────────────────────────────────────────────────

  static Future<void> _initHive() async {
    try {
      await Hive.initFlutter();
      _hiveReady = true;
    } catch (e, st) {
      _hiveReady = false;
      if (kDebugMode) {
        debugPrint('Hive.initFlutter: $e\n$st');
      }
    }
  }

  static Future<void> _openHiveBoxes() async {
    if (!_hiveReady) return;

    try {
      await Future.wait([
        Hive.openBox<dynamic>(AppConstants.hiveBoxSettings),
        Hive.openBox<dynamic>(AppConstants.hiveBoxHistory),
      ]);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Hive.openBox: $e\n$st');
      }
    }
  }

  static Box<dynamic>? get settingsBox {
    if (!_hiveReady || !Hive.isBoxOpen(AppConstants.hiveBoxSettings)) {
      return null;
    }
    return Hive.box<dynamic>(AppConstants.hiveBoxSettings);
  }

  static Box<dynamic>? get historyBox {
    if (!_hiveReady || !Hive.isBoxOpen(AppConstants.hiveBoxHistory)) {
      return null;
    }
    return Hive.box<dynamic>(AppConstants.hiveBoxHistory);
  }

  // ── SharedPreferences ────────────────────────────────────────────────────

  static Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }
}
