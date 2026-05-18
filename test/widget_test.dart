import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpay_ksa/core/constants/app_constants.dart';
import 'package:netpay_ksa/features/splash/presentation/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Splash screen shows NetPay branding', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    await tester.pump();

    expect(find.text('NetPay KSA'), findsOneWidget);
    expect(find.text('نت باي السعودية'), findsOneWidget);

    // إنهاء مؤقت الانتقال في Splash (2.2 ثانية)
    await tester.pump(AppConstants.splashDisplayDuration);
  });
}
