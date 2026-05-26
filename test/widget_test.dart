import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/features/splash/presentation/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_utils/create_localized_test_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({
      AppConstants.prefOnboardingDone: true,
      AppConstants.prefThemeMode: ThemeMode.light.index,
    });
    await AppInitializer.init();
  });

  testWidgets('Splash screen shows NetGulf branding', (tester) async {
    const homeLabel = 'Home';
    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: AppRoutes.splashName,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          builder: (context, state) => const Scaffold(body: Text(homeLabel)),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: AppRoutes.onboardingName,
          builder: (context, state) => const Scaffold(body: Text('Onboarding')),
        ),
      ],
    );

    await tester.pumpWidget(
      createLocalizedTestWidget(routerConfig: router),
    );

    await tester.pump();

    expect(find.text(AppConstants.appNameEn), findsOneWidget);
    expect(find.text(AppConstants.appNameAr), findsOneWidget);
    expect(find.text(AppConstants.appTaglineAr), findsOneWidget);

    await tester.pump(AppConstants.splashDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.text(homeLabel), findsOneWidget);
  });
}
