import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';

/// حقل راتب/بدل — زجاجي مع عملة.
class HomeSalaryField extends StatefulWidget {
  const HomeSalaryField({
    super.key,
    required this.label,
    required this.value,
    required this.currencySymbol,
    required this.onChanged,
    this.countryFlag,
  });

  final String label;
  final double value;
  final String currencySymbol;
  final ValueChanged<double> onChanged;
  final String? countryFlag;

  @override
  State<HomeSalaryField> createState() => _HomeSalaryFieldState();
}

class _HomeSalaryFieldState extends State<HomeSalaryField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant HomeSalaryField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value || _focusNode.hasFocus) return;
    final formatted = _format(widget.value);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) => v > 0 ? v.toStringAsFixed(0) : '';

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 16,
        highlighted: focused,
        blur: focused ? 14 : 10,
        padding: EdgeInsets.zero,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              color: focused
                  ? AppColors.emeraldLight
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            suffixText: widget.currencySymbol,
            suffixStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              color: AppColors.goldBright,
            ),
            prefixIcon: widget.countryFlag != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        widget.countryFlag!,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                : Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: focused
                        ? AppColors.emeraldLight
                        : AppColors.emerald.withValues(alpha: 0.7),
                  ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (t) => widget.onChanged(double.tryParse(t) ?? 0),
        ),
      ),
    );
  }
}
