import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/product_color.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/order_items_grid_cubit.dart';
import '../bloc/order_items_grid_state.dart';

/// One product's color x size grid inside the order draft screen (EPIC-13,
/// TASK-098) — reuses `AppSizeGrid`, the very same Design System component
/// `CommercialSizeGrid` (TASK-073) and `ProductDetailPage` (TASK-078/097)
/// already render, so quantity entry, totals per color/size/product,
/// keyboard navigation and availability indicators behave identically
/// everywhere a color x size grid is shown in the app.
///
/// Fully controlled by [items]: every cell's quantity comes straight from
/// the `OrderItem`s already on the draft (matched by `OrderItem.variantId`),
/// never from a second, parallel copy of the quantity — so a lost
/// connection while typing never loses data, the same "100% estado local do
/// rascunho" contract `OrderDraftBloc` already guarantees. [onQuantityChanged]
/// only ever reports `(variantId, quantity)`, letting the caller
/// (`OrderDraftBloc`, via `OrderDraftItemVariantQuantityChanged`) decide
/// whether that generates a brand new item or updates one already there.
class OrderItemsGrid extends StatefulWidget {
  const OrderItemsGrid({
    required this.organizationId,
    required this.product,
    required this.items,
    required this.onQuantityChanged,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final Product product;

  /// Every `OrderItem` already on the draft for [product] — items for other
  /// products are simply not in this list, never filtered here.
  final List<OrderItem> items;
  final void Function(String variantId, int quantity) onQuantityChanged;
  final OrderItemsGridCubit Function() createCubit;

  @override
  State<OrderItemsGrid> createState() => _OrderItemsGridState();
}

class _OrderItemsGridState extends State<OrderItemsGrid> {
  late final OrderItemsGridCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.createCubit();
    unawaited(
      _cubit.load(
        organizationId: widget.organizationId,
        product: widget.product,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderItemsGridCubit>.value(
      value: _cubit,
      child: BlocBuilder<OrderItemsGridCubit, OrderItemsGridState>(
        builder: (context, state) {
          return switch (state.loadStatus) {
            OrderItemsGridLoadStatus.loading => const AppSkeleton(height: 220),
            OrderItemsGridLoadStatus.failure => AppErrorState(
              title: 'Não foi possível carregar a grade',
              message: state.failure?.message ?? 'Tente novamente em breve.',
            ),
            OrderItemsGridLoadStatus.ready => _OrderItemsGridReady(
              state: state,
              items: widget.items,
              onQuantityChanged: widget.onQuantityChanged,
            ),
          };
        },
      ),
    );
  }
}

class _OrderItemsGridReady extends StatelessWidget {
  const _OrderItemsGridReady({
    required this.state,
    required this.items,
    required this.onQuantityChanged,
  });

  final OrderItemsGridState state;
  final List<OrderItem> items;
  final void Function(String variantId, int quantity) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final product = state.product;
    if (product == null ||
        state.variants.isEmpty ||
        state.orderedSizes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.grid_on_outlined,
        title: 'Grade indisponível',
        description: 'Este produto ainda não tem variantes geradas.',
      );
    }

    final columns = state.orderedSizes
        .map((size) => AppSizeGridColumn(id: size.id, label: size.label))
        .toList(growable: false);
    final rows = state.orderedColors
        .map(_rowForColor)
        .where((row) => row.cells.isNotEmpty)
        .toList(growable: false);

    return Semantics(
      label: 'Grade de ${product.name}',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            product.name,
            style: AppTypography.titleMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppSizeGrid(
            columns: columns,
            rows: rows,
            rowTotalLabel: 'Total cor',
            grandTotalLabel: 'Total do produto',
            onQuantityChanged: (rowId, columnId, quantity) {
              final variant = state.variantForCell(
                colorId: rowId.toString(),
                sizeId: columnId.toString(),
              );
              if (variant == null) return;
              onQuantityChanged(variant.id, quantity);
            },
          ),
        ],
      ),
    );
  }

  AppSizeGridRow _rowForColor(ProductColor color) {
    final cells = <Object, AppSizeGridCell>{};
    for (final size in state.orderedSizes) {
      final variant = state.variantForCell(colorId: color.id, sizeId: size.id);
      if (variant == null) continue;
      cells[size.id] = AppSizeGridCell(
        quantity: _quantityForVariant(variant.id),
        availability: _availabilityFor(
          state.availabilityForVariant(variant).status,
        ),
        availabilityLabel: _availabilityLabelFor(
          state.availabilityForVariant(variant),
        ),
      );
    }

    return AppSizeGridRow(
      id: color.id,
      label: color.name,
      colorSwatch: _colorFromHex(color.hex.value),
      cells: cells,
    );
  }

  /// Reads the already-typed quantity straight from [items] (matched by
  /// `OrderItem.variantId`) — `0` when the variant is not yet on the draft,
  /// never a second, parallel quantity store.
  int _quantityForVariant(String variantId) {
    for (final item in items) {
      if (item.variantId == variantId) return item.quantity;
    }
    return 0;
  }

  AppSizeGridCellAvailability _availabilityFor(
    VariantAvailabilityStatus availability,
  ) {
    return switch (availability) {
      VariantAvailabilityStatus.readyStock =>
        AppSizeGridCellAvailability.readyStock,
      VariantAvailabilityStatus.futureStock =>
        AppSizeGridCellAvailability.futureStock,
      VariantAvailabilityStatus.unavailable =>
        AppSizeGridCellAvailability.unavailable,
    };
  }

  String? _availabilityLabelFor(VariantAvailability availability) {
    return switch (availability.status) {
      VariantAvailabilityStatus.readyStock =>
        availability.availableQuantity == null
            ? null
            : 'Pronta entrega: ${availability.availableQuantity}',
      VariantAvailabilityStatus.futureStock => _futureStockLabel(availability),
      VariantAvailabilityStatus.unavailable => 'Indisponível',
    };
  }

  String _futureStockLabel(VariantAvailability availability) {
    final quantityLabel = availability.futureAvailableQuantity == null
        ? 'Estoque futuro'
        : 'Previsão: ${availability.futureAvailableQuantity} un.';
    if (availability.futureAvailableAt == null) {
      return quantityLabel;
    }
    final locale = Intl.getCurrentLocale();
    final formattedDate = DateFormat.yMd(locale).format(
      DateTime(
        availability.futureAvailableAt!.year,
        availability.futureAvailableAt!.month,
        availability.futureAvailableAt!.day,
      ),
    );
    return '$quantityLabel em $formattedDate';
  }

  Color _colorFromHex(String value) {
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }
}
