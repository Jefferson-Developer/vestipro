import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product_color.dart';
import '../../domain/entities/variant_availability.dart';
import '../../domain/value_objects/variant_availability_status.dart';
import '../bloc/commercial_size_grid_bloc.dart';
import '../bloc/commercial_size_grid_event.dart';
import '../bloc/commercial_size_grid_state.dart';

class CommercialSizeGrid extends StatelessWidget {
  const CommercialSizeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommercialSizeGridBloc, CommercialSizeGridState>(
      builder: (context, state) {
        return switch (state.loadStatus) {
          CommercialSizeGridLoadStatus.loading => const AppSkeleton(
            height: 260,
          ),
          CommercialSizeGridLoadStatus.failure => AppErrorState(
            title: 'Nao foi possivel carregar a grade',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          ),
          CommercialSizeGridLoadStatus.ready => _CommercialSizeGridReady(
            state: state,
          ),
        };
      },
    );
  }
}

class _CommercialSizeGridReady extends StatelessWidget {
  const _CommercialSizeGridReady({required this.state});

  final CommercialSizeGridState state;

  @override
  Widget build(BuildContext context) {
    final product = state.product;
    if (product == null ||
        state.variants.isEmpty ||
        state.orderedSizes.isEmpty) {
      return const AppEmptyState(
        icon: Icons.grid_on_outlined,
        title: 'Grade indisponivel',
        description:
            'Gere as variantes do produto antes de digitar quantidades.',
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
      label: 'Grade comercial de ${product.name}',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.spacing12,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              Text(
                product.name,
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              AppStatusBadge(
                label: 'Total ${state.totalQuantity}',
                variant: AppStatusBadgeVariant.info,
              ),
            ],
          ),
          if (!state.isOnline) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            AppStatusBadge(
              label: 'Offline: quantidades salvas neste dispositivo',
              variant: AppStatusBadgeVariant.warning,
              icon: Icons.cloud_off_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.spacing12),
          AppSizeGrid(
            columns: columns,
            rows: rows,
            rowTotalLabel: 'Total cor',
            grandTotalLabel: 'Total do produto',
            onQuantityChanged: (rowId, columnId, quantity) {
              context.read<CommercialSizeGridBloc>().add(
                CommercialSizeGridQuantityChanged(
                  colorId: rowId.toString(),
                  sizeId: columnId.toString(),
                  quantity: quantity,
                ),
              );
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
        quantity: state.quantityForVariant(variant),
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
      VariantAvailabilityStatus.unavailable => 'Indisponivel',
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
