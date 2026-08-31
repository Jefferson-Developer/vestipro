import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_list_filters.dart';
import '../../domain/value_objects/order_status.dart';
import '../../domain/value_objects/order_sync_status.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';

/// Pedidos listing/tracking page (TASK-102): status/período/cliente/vendedor
/// filters, a debounced quick search, cursor pagination and a dedicated
/// section for orders still pending sync on this device — gated by
/// [Capability.orderView]. Cards on mobile / dense table on desktop-Web come
/// from [AppDataTable] itself, same precedent `AuditLogPage`/
/// `StockAlertsPage` already establish for this exact screen shape.
///
/// Whether the "vendedor" filter renders at all is resolved once, up front,
/// from [Capability.orderApprove] — today granted to exactly
/// OWNER/ADMIN/SALES_MANAGER, the same roles `OrderVisibilityService` ever
/// lets see another seller's orders — the same "UI only shows/enables,
/// never authorizes" contract every other RBAC gate in VestiPro follows:
/// `ListOrdersUseCase`/`firestore.rules` re-validate the same seller-scope
/// decision independently.
class OrderListPage extends StatelessWidget {
  const OrderListPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialSearchQuery = '',
    this.initialFilters = OrderListFilters.empty,
    this.onOrderDraftSelected,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final OrderListBloc Function() createBloc;
  final String initialSearchQuery;
  final OrderListFilters initialFilters;

  /// Called when the seller taps "Continuar edição" on a locally pending
  /// order — always navigates back into the existing order draft flow
  /// (TASK-096's `OrderDraftRoute`, resumed by [Order.id]), never a
  /// bespoke edit screen of its own.
  final ValueChanged<Order>? onOrderDraftSelected;

  /// Called whenever the effective search/filters change, so the host can
  /// mirror them into the URL (Flutter Web deep link) — same contract
  /// `CustomerPortfolioPage.onUrlStateChanged` already sets.
  final void Function(String searchQuery, OrderListFilters filters)?
  onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.orderView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return _OrderListPermissionsGate(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
          permissionService: permissionService,
          createBloc: createBloc,
          initialSearchQuery: initialSearchQuery,
          initialFilters: initialFilters,
          onOrderDraftSelected: onOrderDraftSelected,
          onUrlStateChanged: onUrlStateChanged,
        );
      },
    );
  }
}

class _OrderListPermissionsGate extends StatefulWidget {
  const _OrderListPermissionsGate({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.initialSearchQuery,
    required this.initialFilters,
    this.onOrderDraftSelected,
    this.onUrlStateChanged,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final OrderListBloc Function() createBloc;
  final String initialSearchQuery;
  final OrderListFilters initialFilters;
  final ValueChanged<Order>? onOrderDraftSelected;
  final void Function(String searchQuery, OrderListFilters filters)?
  onUrlStateChanged;

  @override
  State<_OrderListPermissionsGate> createState() =>
      _OrderListPermissionsGateState();
}

class _OrderListPermissionsGateState extends State<_OrderListPermissionsGate> {
  late final Future<bool> _canFilterByOtherSellers;

  @override
  void initState() {
    super.initState();
    _canFilterByOtherSellers = widget.permissionService
        .hasPermission(
          organizationId: widget.organizationId,
          userId: widget.userId,
          capability: Capability.orderApprove,
        )
        .then(
          (result) => result.fold(
            onSuccess: (granted) => granted,
            onFailure: (_) => false,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canFilterByOtherSellers,
      builder: (context, snapshot) {
        final canFilterByOtherSellers = snapshot.data ?? false;
        return BlocProvider<OrderListBloc>(
          create: (_) => widget.createBloc()
            ..add(
              OrderListStarted(
                organizationId: widget.organizationId,
                companyId: widget.companyId,
                userId: widget.userId,
              ),
            ),
          child: _OrderListScaffold(
            canFilterByOtherSellers: canFilterByOtherSellers,
            onOrderDraftSelected: widget.onOrderDraftSelected,
            onUrlStateChanged: widget.onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _OrderListScaffold extends StatelessWidget {
  const _OrderListScaffold({
    required this.canFilterByOtherSellers,
    this.onOrderDraftSelected,
    this.onUrlStateChanged,
  });

  final bool canFilterByOtherSellers;
  final ValueChanged<Order>? onOrderDraftSelected;
  final void Function(String searchQuery, OrderListFilters filters)?
  onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderListBloc, OrderListState>(
      listenWhen: (previous, current) =>
          onUrlStateChanged != null &&
          (previous.filters != current.filters ||
              previous.searchQuery != current.searchQuery),
      listener: (context, state) =>
          onUrlStateChanged!(state.searchQuery, state.filters),
      child: BlocBuilder<OrderListBloc, OrderListState>(
        builder: (context, state) {
          return Scaffold(
            body: AppAdminPageLayout(
              title: 'Pedidos',
              filtersTitle: 'Filtros de pedidos',
              filtersBuilder: (_) => _OrderListFilters(
                state: state,
                canFilterByOtherSellers: canFilterByOtherSellers,
              ),
              content: _OrderListContent(
                state: state,
                onOrderDraftSelected: onOrderDraftSelected,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderListContent extends StatefulWidget {
  const _OrderListContent({required this.state, this.onOrderDraftSelected});

  final OrderListState state;
  final ValueChanged<Order>? onOrderDraftSelected;

  @override
  State<_OrderListContent> createState() => _OrderListContentState();
}

class _OrderListContentState extends State<_OrderListContent> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = context.read<OrderListBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.localPendingOrders.isNotEmpty) ...<Widget>[
          _LocalPendingOrdersSection(
            orders: state.localPendingOrders,
            onOrderSelected: widget.onOrderDraftSelected,
          ),
          const SizedBox(height: AppSpacing.spacing24),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppDataTable<Order>(
                  status: _tableStatus(state),
                  rows: state.orders,
                  rowIdBuilder: (order) => order.id,
                  emptyTitle: 'Nenhum pedido encontrado',
                  emptyDescription:
                      'Ajuste os filtros ou aguarde novos pedidos serem enviados.',
                  errorTitle: 'Não foi possível carregar os pedidos',
                  errorMessage:
                      state.failure?.message ?? 'Tente novamente em breve.',
                  retryLabel: 'Tentar novamente',
                  onRetry: () => bloc.add(const OrderListRetried()),
                  mobileCardTitleBuilder: (context, order) =>
                      Text(order.orderNumber ?? order.id),
                  columns: <AppDataColumn<Order>>[
                    AppDataColumn(
                      label: 'Nº do pedido',
                      cellBuilder: (context, order) =>
                          Text(order.orderNumber ?? '—'),
                    ),
                    AppDataColumn(
                      label: 'Cliente',
                      cellBuilder: (context, order) => Text(order.customerId),
                    ),
                    AppDataColumn(
                      label: 'Vendedor',
                      cellBuilder: (context, order) => Text(order.sellerId),
                    ),
                    AppDataColumn(
                      label: 'Status',
                      cellBuilder: (context, order) =>
                          _OrderStatusBadge(status: order.status),
                    ),
                    AppDataColumn(
                      label: 'Data',
                      cellBuilder: (context, order) =>
                          Text(_dateTimeLabel(order.createdAt)),
                    ),
                    AppDataColumn(
                      label: 'Itens',
                      numeric: true,
                      cellBuilder: (context, order) =>
                          Text('${order.itemCount}'),
                    ),
                  ],
                ),
                if (state.loadStatus == OrderListLoadStatus.ready) ...[
                  const SizedBox(height: AppSpacing.spacing8),
                  AppPagination(
                    hasMore: state.hasMore,
                    isLoadingMore: state.isLoadingMore,
                    onLoadMore: () =>
                        bloc.add(const OrderListNextPageRequested()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  AppDataTableStatus _tableStatus(OrderListState state) {
    return switch (state.loadStatus) {
      OrderListLoadStatus.initial ||
      OrderListLoadStatus.loading => AppDataTableStatus.loading,
      OrderListLoadStatus.failure => AppDataTableStatus.error,
      OrderListLoadStatus.ready || OrderListLoadStatus.loadingMore =>
        state.orders.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }
}

class _LocalPendingOrdersSection extends StatelessWidget {
  const _LocalPendingOrdersSection({
    required this.orders,
    this.onOrderSelected,
  });

  final List<Order> orders;
  final ValueChanged<Order>? onOrderSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.warning.withValues(alpha: 0.08),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.warning.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.cloud_off_outlined, color: colors.warning),
              const SizedBox(width: AppSpacing.spacing8),
              Expanded(
                child: Text(
                  'Pendentes de sincronização (${orders.length})',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Ainda só existem neste dispositivo — serão enviados assim que a '
            'conexão for restabelecida.',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
              child: _LocalPendingOrderRow(
                order: order,
                onSelected: onOrderSelected == null
                    ? null
                    : () => onOrderSelected!(order),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocalPendingOrderRow extends StatelessWidget {
  const _LocalPendingOrderRow({required this.order, this.onSelected});

  final Order order;
  final VoidCallback? onSelected;

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
                  'Cliente ${order.customerId}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Wrap(
                  spacing: AppSpacing.spacing8,
                  runSpacing: AppSpacing.spacing8,
                  children: <Widget>[
                    _OrderStatusBadge(status: order.status),
                    _OrderSyncStatusBadge(syncStatus: order.syncStatus),
                  ],
                ),
              ],
            ),
          ),
          if (onSelected != null)
            AppButton(
              label: 'Continuar edição',
              variant: AppButtonVariant.secondary,
              onPressed: onSelected,
            ),
        ],
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: orderStatusLabel(status),
      variant: _orderStatusVariant(status),
      icon: _orderStatusIcon(status),
    );
  }
}

class _OrderSyncStatusBadge extends StatelessWidget {
  const _OrderSyncStatusBadge({required this.syncStatus});

  final OrderSyncStatus syncStatus;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: orderSyncStatusLabel(syncStatus),
      variant: _orderSyncStatusVariant(syncStatus),
      icon: _orderSyncStatusIcon(syncStatus),
    );
  }
}

class _OrderListFilters extends StatefulWidget {
  const _OrderListFilters({
    required this.state,
    required this.canFilterByOtherSellers,
  });

  final OrderListState state;
  final bool canFilterByOtherSellers;

  @override
  State<_OrderListFilters> createState() => _OrderListFiltersState();
}

class _OrderListFiltersState extends State<_OrderListFilters> {
  late final TextEditingController _searchController;
  late final TextEditingController _customerController;
  late final TextEditingController _sellerController;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  String? _periodError;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
    _customerController = TextEditingController(
      text: widget.state.filters.customerId ?? '',
    );
    _sellerController = TextEditingController(
      text: widget.state.filters.sellerIds.isEmpty
          ? ''
          : widget.state.filters.sellerIds.first,
    );
    _fromController = TextEditingController(
      text: _dateInputLabel(widget.state.filters.from),
    );
    _toController = TextEditingController(
      text: _dateInputLabel(widget.state.filters.to),
    );
  }

  @override
  void didUpdateWidget(covariant _OrderListFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.searchQuery != widget.state.searchQuery &&
        _searchController.text != widget.state.searchQuery) {
      _searchController.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerController.dispose();
    _sellerController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderListBloc>();
    final colors = context.colors;
    final filters = widget.state.filters;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTextField(
            key: const ValueKey('order_list_search_filter'),
            controller: _searchController,
            label: 'Busca rápida',
            hintText: 'Número do pedido ou cliente',
            semanticLabel: 'Buscar pedido por número ou cliente',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) => bloc.add(OrderListSearchChanged(value)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            'Status',
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              AppFilterChip(
                label: 'Todos',
                selected: filters.status == null,
                onSelected: (selected) {
                  if (selected) {
                    _applyFilters(context, filters.copyWith(clearStatus: true));
                  }
                },
              ),
              for (final status in OrderStatus.values)
                AppFilterChip(
                  label: orderStatusLabel(status),
                  selected: filters.status == status,
                  onSelected: (selected) {
                    _applyFilters(
                      context,
                      selected
                          ? filters.copyWith(status: status)
                          : filters.copyWith(clearStatus: true),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            'Período',
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppTextField(
            key: const ValueKey('order_list_from_filter'),
            controller: _fromController,
            label: 'De',
            hintText: 'AAAA-MM-DD',
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppTextField(
            key: const ValueKey('order_list_to_filter'),
            controller: _toController,
            label: 'Até',
            hintText: 'AAAA-MM-DD',
            keyboardType: TextInputType.datetime,
          ),
          if (_periodError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              _periodError!,
              style: AppTypography.bodySmall.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            key: const ValueKey('order_list_customer_filter'),
            controller: _customerController,
            label: 'Cliente',
            hintText: 'ID do cliente',
            prefixIcon: const Icon(Icons.storefront_outlined),
          ),
          if (widget.canFilterByOtherSellers) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing16),
            AppTextField(
              key: const ValueKey('order_list_seller_filter'),
              controller: _sellerController,
              label: 'Vendedor',
              hintText: 'ID do vendedor',
              prefixIcon: const Icon(Icons.badge_outlined),
              semanticLabel: 'Filtrar por vendedor',
            ),
          ],
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Aplicar',
            leadingIcon: Icons.check_outlined,
            onPressed: () => _applyTextFilters(context, filters),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppButton(
            label: 'Limpar filtros',
            leadingIcon: Icons.clear_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled: !widget.state.hasActiveFilters,
            onPressed: () {
              setState(() => _periodError = null);
              _searchController.clear();
              _customerController.clear();
              _sellerController.clear();
              _fromController.clear();
              _toController.clear();
              bloc.add(const OrderListFiltersCleared());
            },
          ),
        ],
      ),
    );
  }

  void _applyTextFilters(BuildContext context, OrderListFilters filters) {
    final from = _parseDate(_fromController.text);
    final to = _parseDate(_toController.text, endOfDay: true);
    if (from == _invalidDate || to == _invalidDate) {
      setState(() {
        _periodError = 'Use datas válidas no formato AAAA-MM-DD.';
      });
      return;
    }
    if (from != null && to != null && from.isAfter(to)) {
      setState(() {
        _periodError = 'A data inicial deve ser anterior à data final.';
      });
      return;
    }
    setState(() => _periodError = null);

    final sellerId = widget.canFilterByOtherSellers
        ? _sellerController.text.trim()
        : '';
    _applyFilters(
      context,
      filters.copyWith(
        customerId: _customerController.text,
        sellerIds: sellerId.isEmpty ? const <String>{} : <String>{sellerId},
        from: from,
        clearFrom: from == null,
        to: to,
        clearTo: to == null,
      ),
    );
  }

  void _applyFilters(BuildContext context, OrderListFilters filters) {
    context.read<OrderListBloc>().add(OrderListFiltersChanged(filters));
  }
}

final DateTime _invalidDate = DateTime.utc(1);

DateTime? _parseDate(String value, {bool endOfDay = false}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split('-');
  if (parts.length != 3) return _invalidDate;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return _invalidDate;

  final parsed = endOfDay
      ? DateTime(year, month, day, 23, 59, 59, 999)
      : DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return _invalidDate;
  }
  return parsed;
}

String _dateInputLabel(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}

/// Human-readable label for [OrderStatus] (`tasks.md`, seção 9.1) — reused
/// by the filter chips and every status badge so they never drift apart.
String orderStatusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.draft => 'Rascunho',
    OrderStatus.pendingSync => 'Pendente de envio',
    OrderStatus.submitted => 'Enviado',
    OrderStatus.underReview => 'Em análise',
    OrderStatus.approved => 'Aprovado',
    OrderStatus.rejected => 'Rejeitado',
    OrderStatus.processing => 'Em processamento',
    OrderStatus.invoiced => 'Faturado',
    OrderStatus.partiallyInvoiced => 'Faturado parcialmente',
    OrderStatus.shipped => 'Expedido',
    OrderStatus.delivered => 'Entregue',
    OrderStatus.cancelled => 'Cancelado',
  };
}

AppStatusBadgeVariant _orderStatusVariant(OrderStatus status) {
  return switch (status) {
    OrderStatus.draft ||
    OrderStatus.pendingSync => AppStatusBadgeVariant.neutral,
    OrderStatus.submitted ||
    OrderStatus.underReview ||
    OrderStatus.processing => AppStatusBadgeVariant.info,
    OrderStatus.approved ||
    OrderStatus.invoiced ||
    OrderStatus.partiallyInvoiced ||
    OrderStatus.shipped ||
    OrderStatus.delivered => AppStatusBadgeVariant.success,
    OrderStatus.rejected ||
    OrderStatus.cancelled => AppStatusBadgeVariant.error,
  };
}

IconData _orderStatusIcon(OrderStatus status) {
  return switch (status) {
    OrderStatus.draft => Icons.edit_note_outlined,
    OrderStatus.pendingSync => Icons.cloud_upload_outlined,
    OrderStatus.submitted => Icons.send_outlined,
    OrderStatus.underReview => Icons.hourglass_top_outlined,
    OrderStatus.approved => Icons.check_circle_outline,
    OrderStatus.rejected => Icons.cancel_outlined,
    OrderStatus.processing => Icons.settings_outlined,
    OrderStatus.invoiced ||
    OrderStatus.partiallyInvoiced => Icons.receipt_long_outlined,
    OrderStatus.shipped => Icons.local_shipping_outlined,
    OrderStatus.delivered => Icons.inventory_2_outlined,
    OrderStatus.cancelled => Icons.block_outlined,
  };
}

/// Human-readable label for [OrderSyncStatus] — always paired with an icon
/// (never color-only, `AppStatusBadge`'s own contract) so a pedido pending
/// sync is never confused with one already confirmed by the server.
String orderSyncStatusLabel(OrderSyncStatus syncStatus) {
  return switch (syncStatus) {
    OrderSyncStatus.pending => 'Pendente de sincronização',
    OrderSyncStatus.syncing => 'Sincronizando',
    OrderSyncStatus.synced => 'Sincronizado',
    OrderSyncStatus.failed => 'Falha ao sincronizar',
    OrderSyncStatus.conflict => 'Conflito de sincronização',
  };
}

AppStatusBadgeVariant _orderSyncStatusVariant(OrderSyncStatus syncStatus) {
  return switch (syncStatus) {
    OrderSyncStatus.pending ||
    OrderSyncStatus.syncing => AppStatusBadgeVariant.warning,
    OrderSyncStatus.synced => AppStatusBadgeVariant.success,
    OrderSyncStatus.failed ||
    OrderSyncStatus.conflict => AppStatusBadgeVariant.error,
  };
}

IconData _orderSyncStatusIcon(OrderSyncStatus syncStatus) {
  return switch (syncStatus) {
    OrderSyncStatus.pending => Icons.cloud_queue_outlined,
    OrderSyncStatus.syncing => Icons.sync_outlined,
    OrderSyncStatus.synced => Icons.cloud_done_outlined,
    OrderSyncStatus.failed => Icons.cloud_off_outlined,
    OrderSyncStatus.conflict => Icons.report_gmailerrorred_outlined,
  };
}
