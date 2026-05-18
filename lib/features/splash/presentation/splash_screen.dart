import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpay_ksa/core/constants/app_constants.dart';
import 'package:netpay_ksa/core/router/app_routes.dart';
import 'package:netpay_ksa/core/theme/app_colors.dart';
import 'package:netpay_ksa/core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.splashLogoAnimationDuration,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    unawaited(_navigateToHome());
  }

  Future<void> _navigateToHome() async {
    await Future<void>.delayed(AppConstants.splashDisplayDuration);
    if (!mounted) return;

    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    // replace = انتقال سلس بدون إبقاء Splash في المكدس
    context.replaceNamed(AppRoutes.homeName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.splashGradient(brightness),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(size: 112),
                    const SizedBox(height: 28),
                    Text(
                      AppConstants.appNameEn,
                      style: GoogleFonts.cairo(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkOnSurface
                            : AppColors.lightOnSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.goldGradient.createShader(bounds),
                      child: Text(
                        AppConstants.appNameAr,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppConstants.appTaglineAr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color:
                            isDark ? AppColors.darkMuted : AppColors.lightMuted,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
