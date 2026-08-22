import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../overlays/app_tooltip.dart';

/// Whether an [AppColorSwatchOption] can currently be added to an order.
enum AppColorAvailability {
  /// Ships from stock on hand.
  readyStock,

  /// Only available from a future stock arrival.
  futureStock,

  /// Cannot be sold right now.
  unavailable,
}

/// A single selectable color of a product.
///
/// [previewImageUrl] and [availability] travel with the option (not just
/// [color]/[label]) so that, when the caller's `onSelected` handler runs,
/// it already has everything it needs to update its own product gallery
/// and availability display for the newly-selected color — [
/// AppColorSwatchSelector] itself never renders a gallery or decides
/// availability; it only offers the option and reports the pick.
@immutable
class AppColorSwatchOption {
  const AppColorSwatchOption({
    required this.id,
    required this.label,
    required this.color,
    this.previewImageUrl,
    this.availability = AppColorAvailability.readyStock,
  });

  /// Stable identity (e.g. the color/variant id), used to know which option
  /// is [AppColorSwatchSelector.selectedId].
  final Object id;

  /// The color's display name (e.g. "Azul marinho"). Always shown as text —
  /// swatches never rely on the color chip alone to identify a color.
  final String label;

  final Color color;

  /// The product photo for this color, if the caller wants
  /// [AppColorSwatchSelector.onSelected] to be able to update a gallery.
  final String? previewImageUrl;

  final AppColorAvailability availability;
}

/// The color swatch picker every catalog/product-detail/order screen reuses
/// to choose which color of a product to view or add.
///
/// Fully controlled: [selectedId] and [options] are always supplied by the
/// caller, and [onSelected] only reports the full [AppColorSwatchOption] the
/// user picked (never just an id) — the caller's screen/BLoC is the one
/// that reacts by swapping its gallery image and availability copy for that
/// color. "Indisponível" is never communicated by color alone: an
/// unavailable swatch always also renders a crossed-out icon and exposes an
/// "indisponível" accessibility/tooltip label.
///
/// ```dart
/// AppColorSwatchSelector(
///   options: state.colors,
///   selectedId: state.selectedColorId,
///   onSelected: (option) => bloc.add(ColorSelected(option.id)),
/// )
/// ```
class AppColorSwatchSelector extends StatelessWidget {
  const AppColorSwatchSelector({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.unavailableLabel = 'Indisponível',
    this.futureStockLabel = 'Estoque futuro',
    this.semanticLabel = 'Cor',
  });

  final List<AppColorSwatchOption> options;

  /// The currently-selected option's [AppColorSwatchOption.id], or `null` if
  /// none is selected yet.
  final Object? selectedId;

  final ValueChanged<AppColorSwatchOption> onSelected;
  final String unavailableLabel;
  final String futureStockLabel;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: Wrap(
        spacing: AppSpacing.spacing12,
        runSpacing: AppSpacing.spacing12,
        children: options
            .map((option) => _buildSwatch(context, option))
            .toList(growable: false),
      ),
    );
  }

  Widget _buildSwatch(BuildContext context, AppColorSwatchOption option) {
    final colors = context.colors;
    final isSelected = option.id == selectedId;
    final isUnavailable =
        option.availability == AppColorAvailability.unavailable;
    final isFutureStock =
        option.availability == AppColorAvailability.futureStock;

    final availabilityLabel = switch (option.availability) {
      AppColorAvailability.readyStock => null,
      AppColorAvailability.futureStock => futureStockLabel,
      AppColorAvailability.unavailable => unavailableLabel,
    };

    final semanticsLabel = <String>[
      option.label,
      ?availabilityLabel,
      if (isSelected) 'selecionado',
    ].join(', ');

    final swatch = Container(
      width: AppSpacing.spacing40,
      height: AppSpacing.spacing40,
      decoration: BoxDecoration(
        color: option.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colors.primary : colors.outline,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: isUnavailable
          ? Icon(
              Icons.block,
              size: AppIconSizes.md,
              color: colors.onSurface.withValues(alpha: 0.7),
            )
          : isFutureStock
          ? Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.schedule,
                size: AppIconSizes.sm,
                color: colors.warning,
              ),
            )
          : null,
    );

    final tooltipMessage = availabilityLabel == null
        ? option.label
        : '${option.label} · $availabilityLabel';

    return Semantics(
      label: semanticsLabel,
      button: true,
      selected: isSelected,
      enabled: !isUnavailable,
      child: AppTooltip(
        message: tooltipMessage,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isUnavailable ? null : () => onSelected(option),
          child: swatch,
        ),
      ),
    );
  }
}
