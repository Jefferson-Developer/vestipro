import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';

/// Shared [InputDecoration] builder for every text-entry component
/// (`AppTextField`, `AppNumberField`, `AppSearchField`) so border, radius,
/// spacing, color and typography never drift between them.
///
/// Internal to `design_system/components/inputs/`: not exported from
/// `design_system.dart` — features consume the field widgets, never this
/// helper directly.
InputDecoration buildAppInputDecoration({
  required AppColors colors,
  required String? label,
  required String? hintText,
  required String? helperText,
  required String? errorText,
  required bool isRequired,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final borderRadius = BorderRadius.circular(AppRadius.radius8);

  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: borderRadius,
    borderSide: BorderSide(color: color),
  );

  return InputDecoration(
    label: label == null
        ? null
        : RichText(
            text: TextSpan(
              text: label,
              style: AppTypography.labelMedium.copyWith(
                color: colors.onSurface,
              ),
              children: isRequired
                  ? <InlineSpan>[
                      TextSpan(
                        text: ' *',
                        style: AppTypography.labelMedium.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ]
                  : const <InlineSpan>[],
            ),
          ),
    hintText: hintText,
    helperText: helperText,
    errorText: errorText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: colors.surfaceContainer,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.spacing16,
      vertical: AppSpacing.spacing12,
    ),
    border: border(colors.outline),
    enabledBorder: border(colors.outline),
    focusedBorder: border(colors.primary),
    disabledBorder: border(colors.disabled),
    errorBorder: border(colors.error),
    focusedErrorBorder: border(colors.error),
  );
}
