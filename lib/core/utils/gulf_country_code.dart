import 'package:netgulf/core/domain/gulf_country.dart';

/// رمز ISO مختصر لقواعد البدلات والمقارنة.
String gulfCountryCode(GulfCountry country) => switch (country) {
      GulfCountry.saudiArabia => 'SA',
      GulfCountry.uae => 'AE',
      GulfCountry.oman => 'OM',
      GulfCountry.qatar => 'QA',
      GulfCountry.bahrain => 'BH',
      GulfCountry.kuwait => 'KW',
    };

GulfCountry? gulfCountryFromCode(String code) => switch (code.toUpperCase()) {
      'SA' => GulfCountry.saudiArabia,
      'AE' => GulfCountry.uae,
      'OM' => GulfCountry.oman,
      'QA' => GulfCountry.qatar,
      'BH' => GulfCountry.bahrain,
      'KW' => GulfCountry.kuwait,
      _ => null,
    };
