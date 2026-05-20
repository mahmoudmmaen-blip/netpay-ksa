import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/domain/gulf_country.dart';

/// الدولة المختارة على الشاشة الرئيسية.
final gulfCountryProvider =
    NotifierProvider<GulfCountryNotifier, GulfCountry>(GulfCountryNotifier.new);

class GulfCountryNotifier extends Notifier<GulfCountry> {
  @override
  GulfCountry build() => _readPersisted();

  GulfCountry _readPersisted() {
    try {
      final index =
          AppInitializer.prefs.getInt(AppConstants.prefGulfCountry) ?? 0;
      if (index >= 0 && index < GulfCountry.values.length) {
        return GulfCountry.values[index];
      }
    } catch (_) {
      // prefs not ready
    }
    return GulfCountry.saudiArabia;
  }

  Future<void> setCountry(GulfCountry country) async {
    if (state == country) return;
    state = country;
    try {
      await AppInitializer.prefs.setInt(
        AppConstants.prefGulfCountry,
        country.index,
      );
    } catch (_) {
      // ignore persistence errors
    }
  }
}
