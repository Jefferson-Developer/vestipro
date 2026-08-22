import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import 'app_input_decoration.dart';

/// A numeric text field: brings up the numeric keyboard on mobile and only
/// accepts digits (plus, optionally, a single decimal separator) — used for
/// quantities, grade totals and monetary amounts across the app.
///
/// Presentational only: this widget filters *keystrokes* to numeric
/// characters, it never parses/validates business quantities (stock,
/// pricing, grade limits) — that stays in the caller's BLoC/domain layer.
class AppNumberField extends StatelessWidget {
  const AppNumberField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.isDisabled = false,
    this.allowDecimal = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final bool isDisabled;

  /// Allows a single `.` or `,` decimal separator (money, weight). Defaults
  /// to `false` (integer-only: quantities, grade counts).
  final bool allowDecimal;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      enabled: !isDisabled,
      child: TextFormField(
        controller: controller,
        enabled: !isDisabled,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        inputFormatters: <TextInputFormatter>[
          if (allowDecimal)
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
          else
            FilteringTextInputFormatter.digitsOnly,
        ],
        textInputAction: textInputAction,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        focusNode: focusNode,
        autofocus: autofocus,
        style: AppTypography.bodyLarge.copyWith(color: colors.onSurface),
        decoration: buildAppInputDecoration(
          colors: colors,
          label: label,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          isRequired: isRequired,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
