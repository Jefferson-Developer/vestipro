import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import 'app_input_decoration.dart';

/// The standard single/multi-line text field for the Design System. Wraps
/// [TextFormField] so it composes with [Form]/[FormField] validation while
/// keeping every visual token (border, radius, color, spacing, typography)
/// sourced from `design_system/foundations/`.
///
/// Purely presentational: validation *messages* are computed by the caller
/// (BLoC/form logic) and passed via [errorText]/[validator] — this widget
/// never decides whether a value is valid.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.isDisabled = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;

  /// Shown right below the field, in the error color — never a raw
  /// exception/technical string, always a message already translated by
  /// the caller.
  final String? errorText;

  /// Renders a `*` next to [label] (never color-only: it is always paired
  /// with the literal asterisk glyph).
  final bool isRequired;
  final bool isDisabled;
  final int maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final bool autofocus;
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
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
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
