import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';

/// The filter/tag chip reused across catalog, client and report screens:
/// selectable (toggles [onSelected]) and/or removable (shows a trailing "x"
/// that calls [onRemove]) — a chip can be either, both or neither,
/// depending on what the caller passes.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onRemove,
    this.leadingIcon,
    this.isDisabled = false,
  });

  final String label;
  final bool selected;

  /// If set, tapping the chip body toggles [selected] (caller decides the
  /// next value and rebuilds).
  final ValueChanged<bool>? onSelected;

  /// If set, renders a trailing "x" that removes the chip.
  final VoidCallback? onRemove;
  final IconData? leadingIcon;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isInteractive = !isDisabled;

    final background = selected
        ? colors.primaryContainer
        : colors.surfaceContainer;
    final foreground = selected ? colors.primary : colors.onSurface;
    final borderColor = selected ? colors.primary : colors.outline;

    final chip = Container(
      decoration: BoxDecoration(
        color: isInteractive ? background : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: isInteractive ? borderColor : colors.disabled,
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            Icon(
              leadingIcon,
              size: AppIconSizes.sm,
              color: isInteractive ? foreground : colors.disabled,
            ),
            const SizedBox(width: AppSpacing.spacing8),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isInteractive ? foreground : colors.disabled,
            ),
          ),
          if (onRemove != null) ...<Widget>[
            const SizedBox(width: AppSpacing.spacing8),
            GestureDetector(
              onTap: isInteractive ? onRemove : null,
              child: Semantics(
                label: 'Remover $label',
                button: true,
                child: Icon(
                  Icons.close,
                  size: AppIconSizes.sm,
                  color: isInteractive ? foreground : colors.disabled,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      label: label,
      selected: selected,
      enabled: isInteractive,
      button: onSelected != null,
      child: onSelected == null
          ? chip
          : InkWell(
              onTap: isInteractive ? () => onSelected!(!selected) : null,
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: chip,
            ),
    );
  }
}
