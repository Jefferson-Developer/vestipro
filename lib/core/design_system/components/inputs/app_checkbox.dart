import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The standard checkbox for the Design System, always paired with a label
/// (e.g. "Li e aceito os Termos de Uso"): [AppCheckbox] never renders a bare
/// checkbox without one, so every usage stays accessible and consistent.
///
/// Purely presentational — like [AppTextField], it never decides *why* the
/// value is required or invalid; a caller (BLoC/form logic) drives
/// [value]/[onChanged] and surfaces [errorText] itself (see
/// `features/authentication/presentation/widgets/sign_up_form.dart`, the
/// terms-of-service acceptance checkbox from TASK-035).
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.labelWidget,
    this.errorText,
    this.isDisabled = false,
    this.semanticLabel,
  });

  final bool value;

  /// `null` disables the whole control, mirroring [Checkbox.onChanged].
  final ValueChanged<bool>? onChanged;

  /// Rendered next to the checkbox. May contain an [InlineSpan] (e.g. a
  /// tappable link) when built with [RichText]-compatible content by the
  /// caller through [labelWidget] instead of [label].
  final String label;

  /// Overrides [label] with a richer widget (e.g. a [Text.rich] embedding a
  /// tappable link to the Terms of Service). When null, [label] is rendered
  /// as plain text.
  final Widget? labelWidget;

  /// Shown below the row, in the error color — same contract as
  /// [AppTextField.errorText]: always an already-translated message, never a
  /// raw code.
  final String? errorText;

  final bool isDisabled;
  final String? semanticLabel;

  bool get _isInteractive => !isDisabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelStyle = AppTypography.bodyMedium.copyWith(
      color: _isInteractive ? colors.onSurface : colors.disabled,
    );

    return Semantics(
      label: semanticLabel ?? label,
      checked: value,
      enabled: _isInteractive,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: _isInteractive ? () => onChanged!(!value) : null,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.spacing4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Checkbox(
                    value: value,
                    onChanged: _isInteractive
                        ? (checked) => onChanged!(checked ?? false)
                        : null,
                    activeColor: colors.primary,
                    checkColor: colors.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.spacing8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.spacing12),
                      child: labelWidget ?? Text(label, style: labelStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.spacing48,
                top: AppSpacing.spacing4,
              ),
              child: Text(
                errorText!,
                style: AppTypography.bodySmall.copyWith(color: colors.error),
              ),
            ),
        ],
      ),
    );
  }
}
