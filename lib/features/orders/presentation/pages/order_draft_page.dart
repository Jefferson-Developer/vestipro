import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../customers/customers.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/order_draft_bloc.dart';
import '../bloc/order_draft_event.dart';
import '../bloc/order_draft_state.dart';
import '../bloc/order_items_grid_cubit.dart';
import '../widgets/order_items_grid.dart';

/// "Novo pedido" screen (EPIC-13, TASK-096/TASK-097): seller picks a customer
/// from their carteira, the resulting `Order` draft is created and persisted
/// 100% offline; every further edit (notes, item quantity/removal) autosaves
/// with a visible pending/saving/saved/failed indicator — never silently —
/// and totals recompute in real time from `Order.itemsSubtotal` as items
/// added from the catalog (TASK-097) come and go.
class OrderDraftPage extends StatelessWidget {
  const OrderDraftPage({
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.permissionService,
    required this.createBloc,
    required this.createCustomerPortfolioBloc,
    required this.createOrderItemsGridCubit,
    this.draftId,
    this.onContinueToProducts,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String sellerId;
  final PermissionService permissionService;
  final OrderDraftBloc Function() createBloc;
  final CustomerPortfolioBloc Function() createCustomerPortfolioBloc;

  /// Builds one `OrderItemsGridCubit` per product card shown on the items
  /// list (TASK-098) — a fresh instance every time, mirroring
  /// `createBloc`/`createCustomerPortfolioBloc`'s own factory-per-use
  /// convention, since each product's color/size grid needs its own
  /// independent load lifecycle.
  final OrderItemsGridCubit Function() createOrderItemsGridCubit;

  /// When provided, resumes that exact draft instead of starting from the
  /// customer-picker step.
  final String? draftId;

  /// Called once the seller taps "Adicionar produtos" with the ready
  /// `Order` draft — expected to navigate to the catalog/product-picking
  /// flow (TASK-097, EPIC-13) and resolve only once the seller comes back
  /// here. Items added while away are persisted directly to the same local
  /// draft (`AddItemsToOrderDraftUseCase`), not through this bloc's
  /// in-memory state, so as soon as the returned future completes this page
  /// re-dispatches `OrderDraftStarted` to reload them.
  final Future<void> Function(Order order)? onContinueToProducts;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: sellerId,
      capability: Capability.orderCreate,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<OrderDraftBloc>(
          create: (_) => createBloc()
            ..add(
              OrderDraftStarted(
                organizationId: organizationId,
                companyId: companyId,
                sellerId: sellerId,
                draftId: draftId,
              ),
            ),
          child: _OrderDraftView(
            organizationId: organizationId,
            companyId: companyId,
            sellerId: sellerId,
            permissionService: permissionService,
            createCustomerPortfolioBloc: createCustomerPortfolioBloc,
            createOrderItemsGridCubit: createOrderItemsGridCubit,
            onContinueToProducts: onContinueToProducts,
          ),
        );
      },
    );
  }
}

class _OrderDraftView extends StatelessWidget {
  const _OrderDraftView({
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.permissionService,
    required this.createCustomerPortfolioBloc,
    required this.createOrderItemsGridCubit,
    this.onContinueToProducts,
  });

  final String organizationId;
  final String companyId;
  final String sellerId;
  final PermissionService permissionService;
  final CustomerPortfolioBloc Function() createCustomerPortfolioBloc;
  final OrderItemsGridCubit Function() createOrderItemsGridCubit;
  final Future<void> Function(Order order)? onContinueToProducts;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDraftBloc, OrderDraftState>(
      // Starting a draft for a picked customer can fail (permission denied,
      // no active branch/price list/payment term configured) while staying
      // in `awaitingCustomer` so the seller can just pick another customer
      // — that failure must still never be silent (AGENTS.md), so it is
      // surfaced here as a snackbar instead of losing it.
      listenWhen: (previous, current) =>
          current.loadStatus == OrderDraftLoadStatus.awaitingCustomer &&
          current.failure != null &&
          previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      builder: (context, state) {
        if (state.loadStatus == OrderDraftLoadStatus.awaitingCustomer) {
          // Reuses the carteira search/filters/pagination as-is (TASK-051)
          // instead of a second customer-search implementation — a customer
          // outside the seller's carteira never appears here to begin with.
          return CustomerPortfolioPage(
            organizationId: organizationId,
            companyId: companyId,
            userId: sellerId,
            permissionService: permissionService,
            createBloc: createCustomerPortfolioBloc,
            onCustomerSelected: (customer) => context
                .read<OrderDraftBloc>()
                .add(OrderDraftCustomerSelected(customer)),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Novo pedido')),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OrderDraftState state) {
    switch (state.loadStatus) {
      case OrderDraftLoadStatus.initial:
      case OrderDraftLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case OrderDraftLoadStatus.failure:
        return AppErrorState(
          title: 'Não foi possível iniciar o pedido',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: () => context.read<OrderDraftBloc>().add(
            OrderDraftStarted(
              organizationId: organizationId,
              companyId: companyId,
              sellerId: sellerId,
            ),
          ),
        );
      case OrderDraftLoadStatus.ready:
        return _OrderDraftSummary(
          state: state,
          organizationId: organizationId,
          createOrderItemsGridCubit: createOrderItemsGridCubit,
          onContinueToProducts: onContinueToProducts,
        );
      case OrderDraftLoadStatus.awaitingCustomer:
        // Handled by `_OrderDraftView.build` itself before reaching here.
        return const SizedBox.shrink();
    }
  }
}

class _OrderDraftSummary extends StatefulWidget {
  const _OrderDraftSummary({
    required this.state,
    required this.organizationId,
    required this.createOrderItemsGridCubit,
    this.onContinueToProducts,
  });

  final OrderDraftState state;
  final String organizationId;
  final OrderItemsGridCubit Function() createOrderItemsGridCubit;
  final Future<void> Function(Order order)? onContinueToProducts;

  @override
  State<_OrderDraftSummary> createState() => _OrderDraftSummaryState();
}

class _OrderDraftSummaryState extends State<_OrderDraftSummary> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.state.order?.notes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _OrderDraftSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final notes = widget.state.order?.notes ?? '';
    if (_notesController.text != notes) {
      _notesController.text = notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.state.order;
    if (order == null) return const SizedBox.shrink();
    final defaults = widget.state.defaults;
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Resumo do pedido', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.spacing16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.radius8),
              border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SummaryRow(label: 'Cliente', value: order.customerId),
                _SummaryRow(
                  label: 'Unidade',
                  value: defaults?.branch.name ?? order.branchId,
                ),
                _SummaryRow(
                  label: 'Tabela de preço',
                  value: defaults?.priceList.name ?? order.priceListId,
                ),
                _SummaryRow(
                  label: 'Condição de pagamento',
                  value: defaults?.paymentTerm.name ?? order.paymentTermId,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            controller: _notesController,
            label: 'Observação',
            hintText: 'Observações do pedido (opcional)',
            semanticLabel: 'Observação do pedido',
            maxLines: 3,
            onChanged: (value) => context.read<OrderDraftBloc>().add(
              OrderDraftNotesChanged(value),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          _AutoSaveIndicator(state: widget.state),
          const SizedBox(height: AppSpacing.spacing24),
          AppButton(
            label: 'Adicionar produtos',
            leadingIcon: Icons.add_shopping_cart_outlined,
            onPressed: widget.onContinueToProducts == null
                ? null
                : () => _continueToProducts(context, order),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          _OrderItemsSection(
            state: widget.state,
            organizationId: widget.organizationId,
            createOrderItemsGridCubit: widget.createOrderItemsGridCubit,
          ),
        ],
      ),
    );
  }

  /// Awaits the catalog/product-picking flow (TASK-097) and reloads the
  /// draft once the seller comes back — items added there were persisted
  /// directly to the local draft (`AddItemsToOrderDraftUseCase`), not
  /// through this screen's own `OrderDraftBloc` instance, so a plain reload
  /// (same as resuming an existing draft) is what actually shows them.
  Future<void> _continueToProducts(BuildContext context, Order order) async {
    final bloc = context.read<OrderDraftBloc>();
    await widget.onContinueToProducts!(order);
    if (!context.mounted) return;
    bloc.add(
      OrderDraftStarted(
        organizationId: widget.state.organizationId,
        companyId: widget.state.companyId,
        sellerId: widget.state.sellerId,
        draftId: order.id,
      ),
    );
  }
}

/// "Itens do pedido" (TASK-097/TASK-098): every `OrderItem` already on the
/// draft, grouped by product and shown as a color x size grid
/// (`OrderItemsGrid`) whenever the product itself has already been resolved
/// (`OrderDraftState.productsById`) — every cell filled or edited there
/// generates or updates the matching `OrderItem` straight on
/// `OrderDraftBloc` (TASK-098). A product not yet resolved (e.g. right after
/// coming back from the catalog, before `_resolveProductNames` finishes)
/// falls back to the plain quantity-stepper row TASK-097 already shipped,
/// never blocking the list on that lookup. The running
/// `Order.itemsSubtotal` stays always visible — a provisional, items-only
/// subtotal, never the order's final total (that is the commercial
/// summary's own job, TASK-099).
class _OrderItemsSection extends StatelessWidget {
  const _OrderItemsSection({
    required this.state,
    required this.organizationId,
    required this.createOrderItemsGridCubit,
  });

  final OrderDraftState state;
  final String organizationId;
  final OrderItemsGridCubit Function() createOrderItemsGridCubit;

  @override
  Widget build(BuildContext context) {
    final order = state.order;
    if (order == null) return const SizedBox.shrink();
    final colors = context.colors;
    final items = order.items;
    final itemsByProduct = <String, List<OrderItem>>{};
    for (final item in items) {
      itemsByProduct.putIfAbsent(item.productId, () => <OrderItem>[]).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Itens do pedido', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.spacing8),
        if (items.isEmpty)
          const AppEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Nenhum produto adicionado ainda',
            description:
                'Toque em "Adicionar produtos" para escolher variantes no '
                'catálogo.',
          )
        else ...<Widget>[
          for (final entry in itemsByProduct.entries) ...<Widget>[
            _OrderProductItemsCard(
              productId: entry.key,
              items: entry.value,
              product: state.productsById[entry.key],
              organizationId: organizationId,
              createOrderItemsGridCubit: createOrderItemsGridCubit,
            ),
            const SizedBox(height: AppSpacing.spacing8),
          ],
          const SizedBox(height: AppSpacing.spacing8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Subtotal dos itens',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              Text(
                _formatCurrency(order.itemsSubtotal),
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Total oficial exibido no resumo comercial do pedido.',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
        ],
      ],
    );
  }
}

/// One product's card inside the items list (TASK-098): renders the
/// color x size grid (`OrderItemsGrid`) once [product] is resolved, or the
/// plain per-item rows (TASK-097) while it is not.
class _OrderProductItemsCard extends StatelessWidget {
  const _OrderProductItemsCard({
    required this.productId,
    required this.items,
    required this.product,
    required this.organizationId,
    required this.createOrderItemsGridCubit,
  });

  final String productId;
  final List<OrderItem> items;
  final Product? product;
  final String organizationId;
  final OrderItemsGridCubit Function() createOrderItemsGridCubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedProduct = product;

    return Container(
      key: ValueKey('order_item_product_$productId'),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: resolvedProduct == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final item in items) ...<Widget>[
                  _OrderItemRow(item: item, productName: productId),
                  const SizedBox(height: AppSpacing.spacing8),
                ],
              ],
            )
          : OrderItemsGrid(
              key: ValueKey('order_items_grid_$productId'),
              organizationId: organizationId,
              product: resolvedProduct,
              items: items,
              createCubit: createOrderItemsGridCubit,
              onQuantityChanged: (variantId, quantity) =>
                  context.read<OrderDraftBloc>().add(
                    OrderDraftItemVariantQuantityChanged(
                      productId: productId,
                      variantId: variantId,
                      quantity: quantity,
                    ),
                  ),
            ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.productName});

  final OrderItem item;
  final String productName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  productName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  '${_formatCurrency(item.unitPrice)} · un.  ·  '
                  'Subtotal: ${_formatCurrency(item.subtotal)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          AppQuantityStepper(
            quantity: item.quantity,
            minQuantity: 0,
            semanticLabel: 'Quantidade de $productName',
            onChanged: (quantity) => context.read<OrderDraftBloc>().add(
              OrderDraftItemQuantityChanged(
                itemId: item.id,
                quantity: quantity,
              ),
            ),
          ),
          AppIconButton(
            icon: Icons.delete_outline,
            semanticLabel: 'Remover $productName do pedido',
            onPressed: () => context.read<OrderDraftBloc>().add(
              OrderDraftItemRemoved(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(value);
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoSaveIndicator extends StatelessWidget {
  const _AutoSaveIndicator({required this.state});

  final OrderDraftState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.saveStatus) {
      OrderDraftSaveStatus.idle => const SizedBox.shrink(),
      OrderDraftSaveStatus.saving => const AppStatusBadge(
        label: 'Salvando...',
        variant: AppStatusBadgeVariant.info,
        icon: Icons.cloud_sync_outlined,
      ),
      OrderDraftSaveStatus.saved => const AppStatusBadge(
        label: 'Rascunho salvo',
        variant: AppStatusBadgeVariant.success,
        icon: Icons.check_circle_outline,
      ),
      OrderDraftSaveStatus.failure => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppStatusBadge(
            label: 'Falha ao salvar o rascunho',
            variant: AppStatusBadgeVariant.error,
            icon: Icons.error_outline,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          AppButton(
            label: 'Tentar novamente',
            variant: AppButtonVariant.text,
            onPressed: () => context.read<OrderDraftBloc>().add(
              const OrderDraftAutoSaveRetried(),
            ),
          ),
        ],
      ),
    };
  }
}
