import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';

/// The bottom sheet every mobile "filters/options/contextual actions" flow
/// must reuse (catalog filters, order actions, quick pickers), instead of a
/// bespoke [showModalBottomSheet] call per feature.
///
/// Height adapts to [builder]'s content (never forced to a fixed/full-screen
/// size), supports the platform's default drag-to-dismiss gesture, and
/// closes on Esc on Web/desktop for free, since it is built on top of
/// [showModalBottomSheet]/[ModalRoute].
///
/// [AppBottomSheet] carries no business logic and, per the Design System's
/// rules, must never be the only confirmation step for a destructive action
/// — pair it with [AppConfirmationDialog] when [builder] exposes one.
///
/// ```dart
/// AppBottomSheet.show<void>(
///   context: context,
///   title: 'Filtrar clientes',
///   builder: (context) => ClientFiltersForm(),
/// );
/// ```
abstract final class AppBottomSheet {
  const AppBottomSheet._();

  /// Opens the sheet and resolves once it is dismissed, with whatever value
  /// [builder]'s content pops the route with (or `null` if dismissed via the
  /// drag handle, the close button, the barrier or Esc).
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showCloseButton = true,
    String closeSemanticLabel = 'Fechar',

    /// Identifies the sheet's inner content widget, mainly so tests/goldens
    /// can locate it precisely (it hugs its content's height, unlike the
    /// framework's [BottomSheet], which spans the full route height).
    Key? contentKey,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AppBottomSheetContent(
        repaintBoundaryKey: contentKey,
        title: title,
        showCloseButton: showCloseButton,
        closeSemanticLabel: closeSemanticLabel,
        child: builder(sheetContext),
      ),
    );
  }
}

class _AppBottomSheetContent extends StatelessWidget {
  const _AppBottomSheetContent({
    this.repaintBoundaryKey,
    required this.title,
    required this.showCloseButton,
    required this.closeSemanticLabel,
    required this.child,
  });

  final Key? repaintBoundaryKey;
  final String? title;
  final bool showCloseButton;
  final String closeSemanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Wrapped in its own [RepaintBoundary] (rather than relying on
    // whichever ancestor layer the modal route happens to composite into)
    // so this card's own bounds — not the full, mostly-transparent route
    // height above it — are what a golden/screenshot test captures.
    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: Material(
        color: colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.radius16),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: AppSpacing.spacing8),
                Center(
                  child: Container(
                    width: AppSpacing.spacing32,
                    height: AppSpacing.spacing4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                if (title != null || showCloseButton)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.spacing24,
                      AppSpacing.spacing12,
                      AppSpacing.spacing12,
                      0,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (title != null)
                          Expanded(
                            child: Text(
                              title!,
                              style: AppTypography.titleMedium.copyWith(
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
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.spacing24,
                    AppSpacing.spacing8,
                    AppSpacing.spacing24,
                    AppSpacing.spacing24,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
