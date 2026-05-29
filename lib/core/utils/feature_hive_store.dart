import 'package:hive_flutter/hive_flutter.dart';

/// فتح صندوق Hive لكل ميزة عند الحاجة (بدون تعديل AppInitializer).
abstract final class FeatureHiveStore {
  FeatureHiveStore._();

  static Future<Box<dynamic>> open(String boxName) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<dynamic>(boxName);
    }
    return Hive.box<dynamic>(boxName);
  }

  static Future<void> put(String boxName, String key, Object? value) async {
    final box = await open(boxName);
    await box.put(key, value);
  }

  static Future<T?> get<T>(String boxName, String key) async {
    final box = await open(boxName);
    return box.get(key) as T?;
  }
}
