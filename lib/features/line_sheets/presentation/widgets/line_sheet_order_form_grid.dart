import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../../domain/entities/line_sheet.dart';
import '../../domain/entities/line_sheet_order_form.dart';

class LineSheetOrderFormGrid extends StatelessWidget {
  const LineSheetOrderFormGrid({
    required this.entry,
    required this.draft,
    required this.showStock,
    required this.onQuantityChanged,
    super.key,
  });

  final LineSheetProductEntry entry;
  final LineSheetOrderFormDraft draft;
  final bool showStock;
  final void Function(String variantId, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final columns = entry.orderedSizes
        .map((size) => AppSizeGridColumn(id: size.id, label: size.label))
        .toList(growable: false);
    final rows = entry.colors
        .map((color) {
          final cells = <Object, AppSizeGridCell>{};
          for (final size in entry.orderedSizes) {
            final variant = entry.variantForCell(
              colorId: color.id,
              sizeId: size.id,
            );
            if (variant == null) continue;
            final availability = entry.availabilityByVariantId[variant.id];
            cells[size.id] = AppSizeGridCell(
              quantity: draft.cells[variant.id]?.quantity ?? 0,
              availability: _cellAvailability(availability),
              availabilityLabel: showStock
                  ? _availabilityLabel(availability)
                  : null,
            );
          }
          return AppSizeGridRow(
            id: color.id,
            label: color.name,
            colorSwatch: Color(
              0xFF000000 | int.parse(color.hex.value.substring(1), radix: 16),
            ),
            cells: cells,
          );
        })
        .toList(growable: false);

    return AppSizeGrid(
      columns: columns,
      rows: rows,
      rowTotalLabel: 'Total cor',
      grandTotalLabel: 'Total produto',
      onQuantityChanged: (colorId, sizeId, quantity) {
        final variant = entry.variantForCell(
          colorId: colorId.toString(),
          sizeId: sizeId.toString(),
        );
        if (variant == null) return;
        onQuantityChanged(variant.id, quantity);
      },
    );
  }

  AppSizeGridCellAvailability _cellAvailability(
    VariantAvailability? availability,
  ) {
    return switch (availability?.status) {
      VariantAvailabilityStatus.futureStock =>
        AppSizeGridCellAvailability.futureStock,
      VariantAvailabilityStatus.unavailable =>
        AppSizeGridCellAvailability.unavailable,
      _ => AppSizeGridCellAvailability.readyStock,
    };
  }

  String? _availabilityLabel(VariantAvailability? availability) {
    if (availability == null) return null;
    return switch (availability.status) {
      VariantAvailabilityStatus.readyStock =>
        availability.availableQuantity == null
            ? 'Pronta entrega'
            : 'Pronta entrega: ${availability.availableQuantity}',
      VariantAvailabilityStatus.futureStock =>
        availability.futureAvailableQuantity == null
            ? 'Estoque futuro'
            : 'Estoque futuro: ${availability.futureAvailableQuantity}',
      VariantAvailabilityStatus.unavailable => 'Indisponivel',
    };
  }
}
