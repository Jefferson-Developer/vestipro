import 'dart:async';

import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import 'app_button.dart';

/// The icon-only variant of [AppButton]: same variants, loading and
/// double-tap protection, but a single [icon] instead of a label — so a
/// mandatory [semanticLabel] is required for screen readers, since there is
/// no visible text to fall back to.
///
/// ```dart
/// AppIconButton(
///   icon: Icons.call,
///   semanticLabel: 'Ligar para o cliente',
///   onPressed: () => launchDialer(client.phone),
/// )
/// ```
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.variant = AppButtonVariant.text,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final IconData icon;

  /// Required accessibility label — an icon-only button has no other way to
  /// announce its purpose to a screen reader.
  final String semanticLabel;

  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
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
    final Color foreground;
    final Color? background;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        foreground = colors.onPrimary;
        background = colors.primary;
      case AppButtonVariant.destructive:
        foreground = colors.onPrimary;
        background = colors.error;
      case AppButtonVariant.secondary:
        foreground = colors.primary;
        background = colors.surfaceContainer;
      case AppButtonVariant.text:
        foreground = colors.onSurface;
        background = null;
    }
    final resolvedForeground = _isInteractive ? foreground : colors.disabled;

    final onTap = _isInteractive && !_tapLocked ? _handleTap : null;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: _isInteractive,
      child: Tooltip(
        message: widget.semanticLabel,
        child: SizedBox(
          width: AppSpacing.spacing48,
          height: AppSpacing.spacing48,
          child: Material(
            color: background,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: AppIconSizes.md,
                        height: AppIconSizes.md,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            resolvedForeground,
                          ),
                        ),
                      )
                    : Icon(
                        widget.icon,
                        size: AppIconSizes.lg,
                        color: resolvedForeground,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
