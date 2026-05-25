import 'package:flutter/material.dart';

/// انتقالات مشتركة للشاشة الرئيسية — Shared home screen transitions.
abstract final class HomePageTransitions {
  HomePageTransitions._();

  static const switchDuration = Duration(milliseconds: 360);
  static const switchCurve = Curves.easeOutCubic;

  /// تلاشي + انزلاق عمودي — fade + vertical slide.
  static Widget fadeSlide(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: switchCurve)),
        child: child,
      ),
    );
  }

  /// تلاشي + انزلاق أفقي — fade + horizontal slide (country switch).
  static Widget fadeSlideHorizontal(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: switchCurve)),
        child: child,
      ),
    );
  }
}
