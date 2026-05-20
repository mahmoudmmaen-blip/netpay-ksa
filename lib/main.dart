import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/app.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// نقطة الدخول — NetGulf
Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );

      await AppInitializer.init();

      if (!AppInitializer.isInitialized) {
        throw StateError('فشلت تهيئة NetGulf — راجع AppInitializer');
      }

      if (kDebugMode) {
        debugPrint(
          '🚀 ${AppConstants.appNameEn} v${AppConstants.appVersion} — جاهز',
        );
      }

      // الثيم: AppTheme.light/dark + themeModeProvider (افتراضي ThemeMode.system)
      runApp(
        const ProviderScope(
          child: NetGulfApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('═══ NetGulf — خطأ غير متوقع ═══');
      debugPrint('$error\n$stack');
    },
  );
}
