import 'dart:async';

import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// Visual intent of an [AppButton]. Every variant maps to Design System
/// color tokens only — never to a hardcoded [Color].
enum AppButtonVariant {
  /// The main call-to-action of a screen (filled, `colors.primary`).
  primary,

  /// A secondary action, still important but not the main one (outlined).
  secondary,

  /// A low-emphasis action, usually paired with a primary/secondary button
  /// (no fill, no border).
  text,

  /// An irreversible/dangerous action (delete, cancel order, block client).
  destructive,
}

/// The single button component every feature must reuse for a labeled
/// action — primary, secondary, text and destructive are all the same
/// widget with a different [AppButtonVariant], so behavior (loading,
/// disabled, double-tap protection, minimum touch target) never drifts
/// between them.
///
/// [AppButton] never calls a repository/BLoC itself: [onPressed] is a plain
/// callback and [isLoading]/[isDisabled] are driven by whatever state the
/// caller (a `BlocBuilder`, typically) is in.
///
/// ```dart
/// AppButton(
///   label: 'Enviar pedido',
///   isLoading: state.isSubmitting,
///   onPressed: state.isSubmitting ? null : () => bloc.add(SubmitOrder()),
/// )
/// ```
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.expand = false,
    this.semanticLabel,
  });

  /// The visible text of the button. Always passed by the caller
  /// (i18n-ready) — never hardcoded inside the Design System.
  final String label;

  /// Called on tap. Ignored while [isLoading] or [isDisabled] is `true`, or
  /// while a previous tap is still being debounced internally.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;

  /// Optional icon rendered before [label].
  final IconData? leadingIcon;

  /// Shows a spinner in place of [label] (same footprint, no resizing) and
  /// blocks further taps — including the internal double-tap guard, so a
  /// caller does not have to also flip [isDisabled] while loading.
  final bool isLoading;

  final bool isDisabled;

  /// Stretches the button to the full width of its parent. Useful for
  /// stacked mobile forms/bottom sheets.
  final bool expand;

  /// Overrides the label as the accessibility announcement, for cases where
  /// [label] alone is ambiguous out of context.
  final String? semanticLabel;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  // Guards against a genuine double-tap firing [onPressed] twice before the
  // caller has had a chance to flip [AppButton.isLoading]/[isDisabled] in
  // response to the first tap.
  bool _tapLocked = false;
  Timer? _unlockTimer;

  bool get _isInteractive =>
      !widget.isLoading && !widget.isDisabled && widget.onPressed != null;

  void _handleTap() {
    if (!_isInteractive || _tapLocked) {
      return;
    }
    setState(() => _tapLocked = true);
    widget.onPressed?.call();
    _unlockTimer?.cancel();
    _unlockTimer = Timer(AppDurations.fast, () {
      if (mounted) {
        setState(() => _tapLocked = false);
      }
    });
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = _resolveStyle(colors);
    final onTap = _isInteractive && !_tapLocked ? _handleTap : null;

    final content = _AppButtonContent(
      label: widget.label,
      leadingIcon: widget.leadingIcon,
      isLoading: widget.isLoading,
      foreground: style.foreground,
    );

    Widget button;
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: onTap,
          style: style.buttonStyle,
          child: content,
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: onTap,
          style: style.buttonStyle,
          child: content,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: onTap,
          style: style.buttonStyle,
          child: content,
        );
    }

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: true,
      enabled: _isInteractive,
      child: widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }

  _AppButtonResolvedStyle _resolveStyle(AppColors colors) {
    final minimumSize = const Size(AppSpacing.spacing48, AppSpacing.spacing48);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.radius8),
    );
    final padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.spacing24,
      vertical: AppSpacing.spacing12,
    );
    final textStyle = AppTypography.labelLarge;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _AppButtonResolvedStyle(
          foreground: colors.onPrimary,
          buttonStyle: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            disabledBackgroundColor: colors.disabled,
            disabledForegroundColor: colors.onPrimary,
            minimumSize: minimumSize,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
            elevation: 0,
            animationDuration: AppDurations.fast,
          ),
        );
      case AppButtonVariant.destructive:
        return _AppButtonResolvedStyle(
          foreground: colors.onPrimary,
          buttonStyle: ElevatedButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onPrimary,
            disabledBackgroundColor: colors.disabled,
            disabledForegroundColor: colors.onPrimary,
            minimumSize: minimumSize,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
            elevation: 0,
            animationDuration: AppDurations.fast,
          ),
        );
      case AppButtonVariant.secondary:
        return _AppButtonResolvedStyle(
          foreground: colors.primary,
          buttonStyle: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            disabledForegroundColor: colors.disabled,
            side: BorderSide(
              color: _isInteractive ? colors.primary : colors.disabled,
            ),
            minimumSize: minimumSize,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
            animationDuration: AppDurations.fast,
          ),
        );
      case AppButtonVariant.text:
        return _AppButtonResolvedStyle(
          foreground: colors.primary,
          buttonStyle: TextButton.styleFrom(
            foregroundColor: colors.primary,
            disabledForegroundColor: colors.disabled,
            minimumSize: minimumSize,
            padding: padding,
            shape: shape,
            textStyle: textStyle,
            animationDuration: AppDurations.fast,
          ),
        );
    }
  }
}

class _AppButtonResolvedStyle {
  const _AppButtonResolvedStyle({
    required this.foreground,
    required this.buttonStyle,
  });

  final Color foreground;
  final ButtonStyle buttonStyle;
}

/// The button's inner row (icon + label), with the loading spinner rendered
/// on top of a fully-transparent copy of the same row so the button never
/// changes size when [isLoading] toggles.
class _AppButtonContent extends StatelessWidget {
  const _AppButtonContent({
    required this.label,
    required this.leadingIcon,
    required this.isLoading,
    required this.foreground,
  });

  final String label;
  final IconData? leadingIcon;
  final bool isLoading;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (leadingIcon != null) ...<Widget>[
          Icon(leadingIcon, size: AppIconSizes.md),
          const SizedBox(width: AppSpacing.spacing8),
        ],
        Text(label),
      ],
    );

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Opacity(opacity: isLoading ? 0 : 1, child: row),
        if (isLoading)
          SizedBox(
            width: AppIconSizes.md,
            height: AppIconSizes.md,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
      ],
    );
  }
}
