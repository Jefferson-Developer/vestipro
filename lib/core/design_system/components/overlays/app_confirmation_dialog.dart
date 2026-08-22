import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';

/// The single official way to ask for explicit confirmation before an
/// irreversible action (delete client, remove user, cancel order, delete a
/// product image, ...). No feature may replace this with a snackbar or a
/// single-tap gesture — destructive actions always require this dialog.
///
/// [AppConfirmationDialog] never decides *whether* the action is allowed —
/// that decision belongs to the domain/BLoC layer, before this dialog is
/// even shown (e.g. don't call [show] at all if the user lacks permission).
/// It only presents [message] and collects the user's explicit choice: it
/// resolves to `true` only when the user taps [confirmLabel], and to
/// `false` for every other way of leaving the dialog (the cancel button,
/// tapping the barrier, or pressing Esc) — so an accidental dismissal can
/// never be mistaken for a confirmed destructive action.
///
/// ```dart
/// final confirmed = await AppConfirmationDialog.show(
///   context: context,
///   title: 'Excluir cliente?',
///   message: 'Esta ação remove o cliente e seu histórico de pedidos. '
///       'Não é possível desfazer.',
///   confirmLabel: 'Excluir',
/// );
/// if (confirmed) {
///   bloc.add(DeleteClient(clientId));
/// }
/// ```
abstract final class AppConfirmationDialog {
  const AppConfirmationDialog._();

  /// Opens the dialog and resolves to `true` only if [confirmLabel] was
  /// tapped; resolves to `false` for every other way of closing it.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
    bool isConfirmLoading = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _AppConfirmationDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isConfirmLoading: isConfirmLoading,
      ),
    );
    return result ?? false;
  }
}

class _AppConfirmationDialogContent extends StatelessWidget {
  const _AppConfirmationDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isConfirmLoading,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isConfirmLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMobile = context.breakpoint == AppBreakpoint.mobile;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.spacing16 : AppSpacing.spacing24,
        vertical: AppSpacing.spacing24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: colors.error),
                  const SizedBox(width: AppSpacing.spacing12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing12),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.spacing12,
                runSpacing: AppSpacing.spacing12,
                children: <Widget>[
                  AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  AppButton(
                    label: confirmLabel,
                    variant: AppButtonVariant.destructive,
                    isLoading: isConfirmLoading,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
