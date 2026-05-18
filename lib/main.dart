import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netpay_ksa/app.dart';
import 'package:netpay_ksa/core/bootstrap/app_initializer.dart';
import 'package:netpay_ksa/core/constants/app_constants.dart';

/// نقطة الدخول — NetPay KSA
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
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      await AppInitializer.init();

      if (!AppInitializer.isInitialized) {
        throw StateError('فشلت تهيئة NetPay KSA — راجع AppInitializer');
      }

      if (kDebugMode) {
        debugPrint(
          '🚀 ${AppConstants.appNameEn} v${AppConstants.appVersion} — جاهز',
        );
      }

      runApp(
        const ProviderScope(
          child: NetPayApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('═══ NetPay KSA — خطأ غير متوقع ═══');
      debugPrint('$error\n$stack');
    },
  );
}
