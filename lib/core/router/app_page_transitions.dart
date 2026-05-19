import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:netgulf/core/constants/app_constants.dart';

/// انتقالات صفحات مخصّصة — Splash → Home بسلاسة.
abstract final class AppPageTransitions {
  AppPageTransitions._();

  /// fade + slide خفيف من الأسفل (مناسب لـ RTL).
  static CustomTransitionPage<T> fadeSlide<T>({
    required LocalKey key,
    required Widget child,
    Duration? duration,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration:
          duration ?? AppConstants.routeTransitionDuration,
      reverseTransitionDuration:
          AppConstants.routeReverseTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// انتقال بسيط للـ Splash (بدون حركة دخول قوية).
  static CustomTransitionPage<T> splash<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: AppConstants.routeTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
    );
  }
}
