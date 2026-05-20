import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_typography.dart';

/// رقم متحرك — عدّ تدريجي مع تدرج ذهبي اختياري.
class AnimatedCurrencyText extends StatefulWidget {
  const AnimatedCurrencyText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 650),
    this.goldGradient = true,
    this.textAlign = TextAlign.center,
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle? style;
  final Duration duration;
  final bool goldGradient;
  final TextAlign textAlign;

  @override
  State<AnimatedCurrencyText> createState() => _AnimatedCurrencyTextState();
}

class _AnimatedCurrencyTextState extends State<AnimatedCurrencyText> {
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
    _to = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimatedCurrencyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value;
      _to = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ??
        AppTypography.displayNumber(
          size: 44,
          color: AppColors.goldBright,
        );

    return TweenAnimationBuilder<double>(
      key: ValueKey(_to),
      tween: Tween(begin: _from, end: _to),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final text = widget.formatter(animated);
        final textWidget = Text(
          text,
          textAlign: widget.textAlign,
          style: baseStyle.copyWith(
            fontFamily: GoogleFonts.cairo().fontFamily,
          ),
        );

        if (!widget.goldGradient) return textWidget;

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF4D6),
              AppColors.goldBright,
              AppColors.gold,
            ],
          ).createShader(bounds),
          child: textWidget,
        );
      },
    );
  }
}
