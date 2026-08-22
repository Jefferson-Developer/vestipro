import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';

/// A single action rendered in an [AppModal]'s footer.
///
/// [AppModal] never decides *what* [onPressed] does — it only renders the
/// button and forwards the tap. Whether the modal should close after the
/// tap (immediately, or later once an async operation succeeds) is a
/// decision the caller makes inside [onPressed] itself, typically by
/// calling `Navigator.of(context).pop()` when appropriate.
@immutable
class AppModalAction {
  const AppModalAction({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
}

/// The generic overlay every dialog-shaped flow in VestiPro must reuse:
/// title, configurable body and up to two footer actions
/// ([primaryAction]/[secondaryAction]), sized by breakpoint (a comfortable
/// fixed width on tablet/desktop/Web, near full-width on mobile).
///
/// [AppModal] carries no business logic: it only presents [body] and
/// forwards taps on its actions/close button. Closes on Esc and returns
/// focus to whatever triggered it for free, since it is built on top of
/// [showDialog]/[ModalRoute] — the same mechanism the framework already
/// uses to manage focus and the default dismiss shortcut for every route.
///
/// ```dart
/// AppModal.show<void>(
///   context: context,
///   title: 'Detalhes do pedido',
///   body: OrderSummary(order: order),
///   secondaryAction: AppModalAction(
///     label: 'Fechar',
///     onPressed: () => Navigator.of(context).pop(),
///   ),
/// );
/// ```
abstract final class AppModal {
  const AppModal._();

  /// Opens the modal and resolves once it is dismissed. Resolves with
  /// `null` if closed via the close button, the barrier, or Esc, and with
  /// whatever a caller-provided action pops the route with otherwise.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget body,
    AppModalAction? primaryAction,
    AppModalAction? secondaryAction,
    bool isDismissible = true,
    bool showCloseButton = true,
    String closeSemanticLabel = 'Fechar',
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (dialogContext) => _AppModalContent(
        title: title,
        body: body,
        primaryAction: primaryAction,
        secondaryAction: secondaryAction,
        showCloseButton: showCloseButton,
        closeSemanticLabel: closeSemanticLabel,
      ),
    );
  }
}

class _AppModalContent extends StatelessWidget {
  const _AppModalContent({
    required this.title,
    required this.body,
    required this.primaryAction,
    required this.secondaryAction,
    required this.showCloseButton,
    required this.closeSemanticLabel,
  });

  final String title;
  final Widget body;
  final AppModalAction? primaryAction;
  final AppModalAction? secondaryAction;
  final bool showCloseButton;
  final String closeSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = context.breakpoint == AppBreakpoint.mobile;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.spacing16 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 480,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (showCloseButton)
                    AppIconButton(
                      icon: Icons.close,
                      semanticLabel: closeSemanticLabel,
                      variant: AppButtonVariant.text,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Flexible(child: SingleChildScrollView(child: body)),
              if (primaryAction != null || secondaryAction != null) ...<Widget>[
                const SizedBox(height: AppSpacing.spacing24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.spacing12,
                  runSpacing: AppSpacing.spacing12,
                  children: <Widget>[
                    if (secondaryAction != null)
                      AppButton(
                        label: secondaryAction!.label,
                        variant: secondaryAction!.variant,
                        isLoading: secondaryAction!.isLoading,
                        isDisabled: secondaryAction!.isDisabled,
                        onPressed: secondaryAction!.onPressed,
                      ),
                    if (primaryAction != null)
                      AppButton(
                        label: primaryAction!.label,
                        variant: primaryAction!.variant,
                        isLoading: primaryAction!.isLoading,
                        isDisabled: primaryAction!.isDisabled,
                        onPressed: primaryAction!.onPressed,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
