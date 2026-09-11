import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../domain/entities/line_sheet.dart';
import '../cubit/line_sheet_cubit.dart';
import '../cubit/line_sheet_state.dart';
import '../widgets/line_sheet_order_form_grid.dart';

class LineSheetPage extends StatelessWidget {
  const LineSheetPage({
    required this.createCubit,
    this.onAddItemsToOrder,
    super.key,
  });

  final LineSheetCubit Function() createCubit;
  final void Function(
    List<OrderItem> items,
    Map<String, Object?> lineSheetVersionSnapshot,
  )?
  onAddItemsToOrder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LineSheetCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(cubit.load());
        return cubit;
      },
      child: _LineSheetView(onAddItemsToOrder: onAddItemsToOrder),
    );
  }
}

class _LineSheetView extends StatelessWidget {
  const _LineSheetView({this.onAddItemsToOrder});

  final void Function(
    List<OrderItem> items,
    Map<String, Object?> lineSheetVersionSnapshot,
  )?
  onAddItemsToOrder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<LineSheetCubit, LineSheetState>(
          builder: (context, state) {
            return switch (state.status) {
              LineSheetLoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LineSheetLoadStatus.forbidden => const AppEmptyState(
                icon: Icons.lock_outline,
                title: 'Line sheet restrito',
                description:
                    'Este link nao libera produtos, precos ou estoque para este perfil.',
              ),
              LineSheetLoadStatus.failure => AppErrorState(
                title: 'Nao foi possivel carregar o line sheet',
                message: state.failure?.message ?? 'Tente novamente em breve.',
                retryLabel: 'Tentar novamente',
                onRetry: () => context.read<LineSheetCubit>().load(),
              ),
              LineSheetLoadStatus.ready => _LineSheetReadyView(
                state: state,
                onAddItemsToOrder: onAddItemsToOrder,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _LineSheetReadyView extends StatelessWidget {
  const _LineSheetReadyView({required this.state, this.onAddItemsToOrder});

  final LineSheetState state;
  final void Function(
    List<OrderItem> items,
    Map<String, Object?> lineSheetVersionSnapshot,
  )?
  onAddItemsToOrder;

  @override
  Widget build(BuildContext context) {
    final view = state.view!;
    final draft = state.draft!;
    final lineSheet = view.lineSheet;
    final colors = context.colors;
    final currency = NumberFormat.simpleCurrency(
      locale: Intl.getCurrentLocale(),
    );
    final updatedAt = DateFormat.yMd(
      Intl.getCurrentLocale(),
    ).add_Hm().format(lineSheet.updatedAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Wrap(
            spacing: AppSpacing.spacing12,
            runSpacing: AppSpacing.spacing12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      lineSheet.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      'Colecao ${lineSheet.collectionId} | versao ${lineSheet.version} | atualizado $updatedAt',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<LineSheetViewMode>(
                segments: const <ButtonSegment<LineSheetViewMode>>[
                  ButtonSegment<LineSheetViewMode>(
                    value: LineSheetViewMode.visual,
                    icon: Icon(Icons.view_module_outlined),
                    label: Text('Visual'),
                  ),
                  ButtonSegment<LineSheetViewMode>(
                    value: LineSheetViewMode.orderForm,
                    icon: Icon(Icons.grid_on_outlined),
                    label: Text('Order form'),
                  ),
                ],
                selected: <LineSheetViewMode>{state.viewMode},
                onSelectionChanged: (selection) =>
                    context.read<LineSheetCubit>().changeMode(selection.single),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: state.viewMode == LineSheetViewMode.visual
              ? _VisualLineSheet(view: view, currency: currency)
              : _OrderFormLineSheet(state: state, currency: currency),
        ),
        Material(
          elevation: 4,
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Wrap(
              spacing: AppSpacing.spacing16,
              runSpacing: AppSpacing.spacing8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${draft.totalPieces} pecas | ${currency.format(draft.totalAmount)}',
                  key: const Key('line_sheet_order_form_totals'),
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                AppButton(
                  label: 'Adicionar ao pedido',
                  leadingIcon: Icons.add_shopping_cart_outlined,
                  onPressed: draft.totalPieces == 0
                      ? null
                      : () => onAddItemsToOrder?.call(
                          draft.toOrderItems(),
                          draft.versionSnapshot(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VisualLineSheet extends StatelessWidget {
  const _VisualLineSheet({required this.view, required this.currency});

  final LineSheetView view;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final entries = List<LineSheetProductEntry>.of(
      view.lineSheet.productEntries,
    )..sort((a, b) => a.editorialOrder.compareTo(b.editorialOrder));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spacing12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final photo = entry.product.principalPhoto;
        final imageUrl = photo?.thumbnailUrl ?? photo?.url;
        final availableLabel = entry.hasAvailableVariants
            ? '${entry.availabilityByVariantId.length} variantes'
            : 'Sem variantes disponiveis';
        return InkWell(
          onTap: () =>
              context.read<LineSheetCubit>().viewProduct(entry.product.id),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.radius8),
                child: SizedBox(
                  width: 96,
                  height: 128,
                  child: imageUrl == null
                      ? ColoredBox(
                          color: context.colors.surfaceContainer,
                          child: const Icon(Icons.image_outlined),
                        )
                      : Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: AppSpacing.spacing8,
                      runSpacing: AppSpacing.spacing4,
                      children: <Widget>[
                        Text(
                          entry.product.reference,
                          style: AppTypography.labelMedium.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                        if (entry.highlight)
                          const AppStatusBadge(
                            label: 'Destaque',
                            variant: AppStatusBadgeVariant.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      entry.product.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing8),
                    Wrap(
                      spacing: AppSpacing.spacing8,
                      runSpacing: AppSpacing.spacing8,
                      children: <Widget>[
                        if (view.canViewPrices && entry.unitPrice != null)
                          AppStatusBadge(
                            label: currency.format(entry.unitPrice),
                            variant: AppStatusBadgeVariant.info,
                          ),
                        if (view.canViewStock)
                          AppStatusBadge(
                            label: availableLabel,
                            variant: entry.hasAvailableVariants
                                ? AppStatusBadgeVariant.success
                                : AppStatusBadgeVariant.warning,
                          ),
                        for (final tag in entry.tags.take(3))
                          AppStatusBadge(
                            label: tag,
                            variant: AppStatusBadgeVariant.neutral,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderFormLineSheet extends StatelessWidget {
  const _OrderFormLineSheet({required this.state, required this.currency});

  final LineSheetState state;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final entries = List<LineSheetProductEntry>.of(
      state.view!.lineSheet.productEntries,
    )..sort((a, b) => a.editorialOrder.compareTo(b.editorialOrder));
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spacing24),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final productTotal = state.draft!.cells.values
            .where((cell) => cell.productId == entry.product.id)
            .fold<double>(0, (sum, cell) => sum + cell.subtotal);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${entry.product.reference} - ${entry.product.name}',
                    style: AppTypography.titleMedium.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                Text(
                  currency.format(productTotal),
                  key: Key('line_sheet_product_total_${entry.product.id}'),
                  style: AppTypography.labelLarge.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing8),
            LineSheetOrderFormGrid(
              entry: entry,
              draft: state.draft!,
              showStock: state.view!.canViewStock,
              onQuantityChanged: (variantId, quantity) =>
                  context.read<LineSheetCubit>().changeQuantity(
                    entry: entry,
                    variantId: variantId,
                    quantity: quantity,
                  ),
            ),
          ],
        );
      },
    );
  }
}
