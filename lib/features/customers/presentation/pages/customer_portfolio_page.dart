import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_portfolio_filters.dart';
import '../../domain/value_objects/customer_status.dart';
import '../bloc/customer_portfolio_bloc.dart';
import '../bloc/customer_portfolio_event.dart';
import '../bloc/customer_portfolio_state.dart';
import '../bloc/customer_segment_bloc.dart';
import '../bloc/customer_segment_event.dart';
import '../widgets/customer_portfolio_map_view.dart';
import '../widgets/customer_segment_quick_filters.dart';

/// Local UI preference (TASK-176), never persisted/synced: which
/// visualization of the same carteira the mobile breakpoint currently shows.
/// Tablet/desktop always render both side by side (see
/// `_CustomerPortfolioScaffoldState.build`), so this only matters on mobile.
enum _CustomerPortfolioViewMode { list, map }

class CustomerPortfolioPage extends StatelessWidget {
  const CustomerPortfolioPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialSearchQuery = '',
    this.initialFilters = CustomerPortfolioFilters.empty,
    this.onCustomerSelected,
    this.onUrlStateChanged,
    this.createSegmentBloc,
    this.onImportRequested,
    this.onPlanVisitRouteRequested,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final CustomerPortfolioBloc Function() createBloc;
  final String initialSearchQuery;
  final CustomerPortfolioFilters initialFilters;
  final ValueChanged<Customer>? onCustomerSelected;
  final void Function(String searchQuery, CustomerPortfolioFilters filters)?
  onUrlStateChanged;

  /// Optional (TASK-053): when provided, mounts the saved-segment quick
  /// filters above the carteira filters. Kept optional so existing call
  /// sites that do not wire a [CustomerSegmentBloc] keep working unchanged.
  final CustomerSegmentBloc Function()? createSegmentBloc;

  /// Navigates to `CustomerImportRoute` (TASK-167). Optional so existing
  /// call sites keep compiling unchanged; when provided, an "Importar
  /// clientes" action renders in the page header, itself gated by
  /// `Capability.customerImport`.
  final VoidCallback? onImportRequested;

  /// Navigates to `VisitRouteRoute` (TASK-177). Optional/`null`-safe so
  /// existing call sites keep compiling unchanged; when provided, a
  /// "Roteirizar visitas" action renders in the page header, gated by the
  /// same `Capability.customerView` the carteira itself already requires
  /// (planning a visit route is just another view over the seller's own
  /// visible carteira, not a distinct admin capability).
  final VoidCallback? onPlanVisitRouteRequested;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.customerView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        final scaffold = BlocProvider<CustomerPortfolioBloc>(
          create: (_) => createBloc()
            ..add(
              CustomerPortfolioStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
                searchQuery: initialSearchQuery,
                filters: initialFilters,
              ),
            ),
          child: _CustomerPortfolioScaffold(
            onCustomerSelected: onCustomerSelected,
            onUrlStateChanged: onUrlStateChanged,
            userId: userId,
            hasSegments: createSegmentBloc != null,
            onImportRequested: onImportRequested,
            onPlanVisitRouteRequested: onPlanVisitRouteRequested,
            permissionService: permissionService,
            organizationId: organizationId,
          ),
        );

        final buildSegmentBloc = createSegmentBloc;
        if (buildSegmentBloc == null) return scaffold;
        return BlocProvider<CustomerSegmentBloc>(
          create: (_) => buildSegmentBloc()
            ..add(
              CustomerSegmentsStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            ),
          child: scaffold,
        );
      },
    );
  }
}

class _CustomerPortfolioScaffold extends StatefulWidget {
  const _CustomerPortfolioScaffold({
    required this.userId,
    required this.hasSegments,
    this.onCustomerSelected,
    this.onUrlStateChanged,
    this.onImportRequested,
    this.onPlanVisitRouteRequested,
    this.permissionService,
    this.organizationId,
  });

  final String userId;
  final bool hasSegments;
  final ValueChanged<Customer>? onCustomerSelected;
  final void Function(String searchQuery, CustomerPortfolioFilters filters)?
  onUrlStateChanged;
  final VoidCallback? onPlanVisitRouteRequested;

  /// Navigates to `CustomerImportRoute` (TASK-167). Optional/`null`-safe so
  /// existing call sites that do not wire it keep compiling unchanged;
  /// gated below by `Capability.customerImport` via [permissionService]
  /// (`AGENTS.md`: UI-side gating never replaces the server-side one, only
  /// improves UX by hiding an action the caller cannot use anyway).
  final VoidCallback? onImportRequested;
  final PermissionService? permissionService;
  final String? organizationId;

  @override
  State<_CustomerPortfolioScaffold> createState() =>
      _CustomerPortfolioScaffoldState();
}

class _CustomerPortfolioScaffoldState
    extends State<_CustomerPortfolioScaffold> {
  var _viewMode = _CustomerPortfolioViewMode.list;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerPortfolioBloc, CustomerPortfolioState>(
      listenWhen: (previous, current) =>
          previous.searchQuery != current.searchQuery ||
          previous.filters != current.filters,
      listener: (context, state) =>
          widget.onUrlStateChanged?.call(state.searchQuery, state.filters),
      child: BlocBuilder<CustomerPortfolioBloc, CustomerPortfolioState>(
        builder: (context, state) {
          // TASK-176: a single `AppResponsiveBuilder` (this page's own
          // available width, not the window) is the one source of truth
          // both the header toggle and the content area resolve against —
          // never two independent breakpoint reads that could disagree.
          return AppResponsiveBuilder(
            builder: (context, breakpoint) {
              return Scaffold(
                body: AppAdminPageLayout(
                  title: 'Carteira de clientes',
                  actions: _buildActions(breakpoint),
                  filtersTitle: 'Filtros da carteira',
                  filtersBuilder: (_) => _PortfolioFilters(
                    state: state,
                    userId: widget.userId,
                    hasSegments: widget.hasSegments,
                  ),
                  content: _PortfolioAndMapContent(
                    state: state,
                    breakpoint: breakpoint,
                    viewMode: _viewMode,
                    onCustomerSelected: widget.onCustomerSelected,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(AppBreakpoint breakpoint) {
    final actions = <Widget>[];
    // TASK-176: the mobile breakpoint shows one view at a time (tela cheia),
    // so it needs an explicit toggle. Tablet/desktop always render list and
    // map side by side (`_PortfolioAndMapContent`), so the toggle would have
    // nothing to switch between and stays hidden there.
    if (breakpoint == AppBreakpoint.mobile) {
      final showsMap = _viewMode == _CustomerPortfolioViewMode.map;
      actions.add(
        AppIconButton(
          icon: showsMap ? Icons.view_list_outlined : Icons.map_outlined,
          semanticLabel: showsMap
              ? 'Ver carteira em lista'
              : 'Ver carteira no mapa',
          onPressed: () => setState(() {
            _viewMode = showsMap
                ? _CustomerPortfolioViewMode.list
                : _CustomerPortfolioViewMode.map;
          }),
        ),
      );
      actions.add(const SizedBox(width: AppSpacing.spacing8));
    }

    final onPlanVisitRoute = widget.onPlanVisitRouteRequested;
    if (onPlanVisitRoute != null) {
      actions.add(
        AppButton(
          label: 'Roteirizar visitas',
          variant: AppButtonVariant.secondary,
          leadingIcon: Icons.alt_route,
          onPressed: onPlanVisitRoute,
        ),
      );
      actions.add(const SizedBox(width: AppSpacing.spacing8));
    }

    final onImport = widget.onImportRequested;
    final service = widget.permissionService;
    final orgId = widget.organizationId;
    if (onImport == null || service == null || orgId == null) {
      return actions;
    }
    actions.add(
      PermissionBuilder(
        permissionService: service,
        organizationId: orgId,
        userId: widget.userId,
        capability: Capability.customerImport,
        builder: (context, granted) {
          if (!granted) return const SizedBox.shrink();
          return AppButton(
            label: 'Importar clientes',
            variant: AppButtonVariant.secondary,
            leadingIcon: Icons.upload_file_outlined,
            onPressed: onImport,
          );
        },
      ),
    );
    return actions;
  }
}

/// TASK-176: decides — from the [breakpoint] the page's own
/// `AppResponsiveBuilder` already resolved (same source the header toggle
/// reads, so the two can never disagree) — whether the carteira map renders
/// as its own full-screen mode (mobile, following [viewMode]) or permanently
/// side by side with the list (tablet/desktop/large desktop).
class _PortfolioAndMapContent extends StatelessWidget {
  const _PortfolioAndMapContent({
    required this.state,
    required this.breakpoint,
    required this.viewMode,
    this.onCustomerSelected,
  });

  final CustomerPortfolioState state;
  final AppBreakpoint breakpoint;
  final _CustomerPortfolioViewMode viewMode;
  final ValueChanged<Customer>? onCustomerSelected;

  @override
  Widget build(BuildContext context) {
    final list = _PortfolioContent(
      state: state,
      onCustomerSelected: onCustomerSelected,
    );
    final map = _CustomerMapAutoLoader(
      state: state,
      child: CustomerPortfolioMapView(
        customers: state.customers,
        onCustomerSelected: onCustomerSelected,
      ),
    );

    if (breakpoint == AppBreakpoint.mobile) {
      return viewMode == _CustomerPortfolioViewMode.map ? map : list;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: list),
        const SizedBox(width: AppSpacing.spacing16),
        Expanded(child: map),
      ],
    );
  }
}

/// TASK-176: the map wants the *whole* filtered carteira plotted at once —
/// unlike the list, it cannot meaningfully paginate by scroll. Reuses the
/// same `CustomerPortfolioBloc`/`ListCustomerPortfolioUseCase` the list view
/// already drives (never a second query): while mounted, it keeps
/// dispatching [CustomerPortfolioNextPageRequested] until [state.hasMore] is
/// `false`, exactly like scrolling the list to the bottom would.
class _CustomerMapAutoLoader extends StatefulWidget {
  const _CustomerMapAutoLoader({required this.state, required this.child});

  final CustomerPortfolioState state;
  final Widget child;

  @override
  State<_CustomerMapAutoLoader> createState() => _CustomerMapAutoLoaderState();
}

class _CustomerMapAutoLoaderState extends State<_CustomerMapAutoLoader> {
  @override
  void initState() {
    super.initState();
    _requestNextPageIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _CustomerMapAutoLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requestNextPageIfNeeded();
  }

  void _requestNextPageIfNeeded() {
    final state = widget.state;
    if (!state.hasMore || state.isLoadingMore || state.isInitialLoading) {
      return;
    }
    // Deferred to the next frame so this never dispatches a bloc event from
    // within another widget's build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerPortfolioBloc>().add(
        const CustomerPortfolioNextPageRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PortfolioContent extends StatefulWidget {
  const _PortfolioContent({required this.state, this.onCustomerSelected});

  final CustomerPortfolioState state;
  final ValueChanged<Customer>? onCustomerSelected;

  @override
  State<_PortfolioContent> createState() => _PortfolioContentState();
}

class _PortfolioContentState extends State<_PortfolioContent> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_requestNextPageNearEnd);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_requestNextPageNearEnd)
      ..dispose();
    super.dispose();
  }

  void _requestNextPageNearEnd() {
    if (_scrollController.position.extentAfter < 420) {
      context.read<CustomerPortfolioBloc>().add(
        const CustomerPortfolioNextPageRequested(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.status == CustomerPortfolioLoadStatus.failure) {
      return AppErrorState(
        title: 'Nao foi possivel carregar a carteira',
        message: state.failure?.message ?? 'Tente novamente em breve.',
        retryLabel: 'Tentar novamente',
        onRetry: () => context.read<CustomerPortfolioBloc>().add(
          const CustomerPortfolioRetried(),
        ),
      );
    }
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.customers.isEmpty) {
      return const AppEmptyState(
        title: 'Nenhum cliente na carteira',
        description: 'Ajuste os filtros ou revise os vinculos de carteira.',
        icon: Icons.storefront_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.isFromLocalCache) const _OfflineCacheBanner(),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            itemCount: state.customers.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.spacing12),
            itemBuilder: (context, index) {
              if (index >= state.customers.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.spacing16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _CustomerPortfolioCard(
                customer: state.customers[index],
                onTap: widget.onCustomerSelected == null
                    ? null
                    : () => widget.onCustomerSelected!(state.customers[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PortfolioFilters extends StatefulWidget {
  const _PortfolioFilters({
    required this.state,
    required this.userId,
    required this.hasSegments,
  });

  final CustomerPortfolioState state;
  final String userId;
  final bool hasSegments;

  @override
  State<_PortfolioFilters> createState() => _PortfolioFiltersState();
}

class _PortfolioFiltersState extends State<_PortfolioFilters> {
  late final TextEditingController _searchController;
  late final TextEditingController _statesController;
  late final TextEditingController _potentialsController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.state.searchQuery);
    _statesController = TextEditingController(
      text: widget.state.filters.stateCodes.join(', '),
    );
    _potentialsController = TextEditingController(
      text: widget.state.filters.potentials.join(', '),
    );
  }

  @override
  void didUpdateWidget(covariant _PortfolioFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_searchController, widget.state.searchQuery);
    _syncController(
      _statesController,
      widget.state.filters.stateCodes.join(', '),
    );
    _syncController(
      _potentialsController,
      widget.state.filters.potentials.join(', '),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _statesController.dispose();
    _potentialsController.dispose();
    super.dispose();
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CustomerPortfolioBloc>();
    final filters = widget.state.filters;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.hasSegments) ...<Widget>[
            CustomerSegmentQuickFilters(userId: widget.userId),
            const Divider(),
            const SizedBox(height: AppSpacing.spacing16),
          ],
          AppTextField(
            controller: _searchController,
            label: 'Busca',
            hintText: 'Nome ou documento',
            semanticLabel: 'Buscar cliente por nome ou documento',
            prefixIcon: const Icon(Icons.search),
            onChanged: (value) =>
                bloc.add(CustomerPortfolioSearchChanged(value)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<CustomerStatus>(
            multiple: true,
            label: 'Status',
            hintText: 'Todos',
            semanticLabel: 'Filtrar por status',
            closeSemanticLabel: 'Fechar filtro de status',
            enableSearch: false,
            options: CustomerStatus.values
                .map(
                  (status) => AppDropdownOption<CustomerStatus>(
                    value: status,
                    label: _statusLabel(status),
                  ),
                )
                .toList(growable: false),
            selectedValues: filters.statuses,
            onChanged: (selected) =>
                _changeFilters(filters.copyWith(statuses: selected)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            controller: _statesController,
            label: 'Regiao/UF',
            hintText: 'Ex.: SP, SC',
            semanticLabel: 'Filtrar por UF',
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _applyTextFilters(),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            controller: _potentialsController,
            label: 'Potencial',
            hintText: 'Ex.: Alto, Medio',
            semanticLabel: 'Filtrar por potencial',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _applyTextFilters(),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<CustomerLastPurchaseFilter>(
            label: 'Ultima compra',
            hintText: 'Qualquer compra',
            semanticLabel: 'Filtrar por ultima compra',
            closeSemanticLabel: 'Fechar filtro de ultima compra',
            enableSearch: false,
            options: CustomerLastPurchaseFilter.values
                .map(
                  (filter) => AppDropdownOption<CustomerLastPurchaseFilter>(
                    value: filter,
                    label: filter.label,
                  ),
                )
                .toList(growable: false),
            selectedValues: <CustomerLastPurchaseFilter>{filters.lastPurchase},
            onChanged: (selected) =>
                _changeFilters(filters.copyWith(lastPurchase: selected.first)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Aplicar filtros',
            leadingIcon: Icons.tune,
            variant: AppButtonVariant.secondary,
            onPressed: _applyTextFilters,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppButton(
            label: 'Limpar',
            leadingIcon: Icons.clear,
            variant: AppButtonVariant.text,
            onPressed: () {
              _statesController.clear();
              _potentialsController.clear();
              _searchController.clear();
              bloc
                ..add(const CustomerPortfolioSearchChanged(''))
                ..add(
                  const CustomerPortfolioFiltersChanged(
                    CustomerPortfolioFilters.empty,
                  ),
                );
            },
          ),
        ],
      ),
    );
  }

  void _applyTextFilters() {
    _changeFilters(
      widget.state.filters.copyWith(
        stateCodes: _csvSet(_statesController.text),
        potentials: _csvSet(_potentialsController.text),
      ),
    );
  }

  void _changeFilters(CustomerPortfolioFilters filters) {
    context.read<CustomerPortfolioBloc>().add(
      CustomerPortfolioFiltersChanged(filters),
    );
  }

  Set<String> _csvSet(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  String _statusLabel(CustomerStatus status) {
    return switch (status) {
      CustomerStatus.active => 'Ativo',
      CustomerStatus.inactive => 'Inativo',
      CustomerStatus.prospect => 'Prospect',
      CustomerStatus.blocked => 'Bloqueado',
    };
  }
}

class _OfflineCacheBanner extends StatelessWidget {
  const _OfflineCacheBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.warning.withValues(alpha: 0.14),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.warning.withValues(alpha: 0.34)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off_outlined, color: colors.warning),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              'Exibindo dados locais da carteira.',
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerPortfolioCard extends StatelessWidget {
  const _CustomerPortfolioCard({required this.customer, this.onTap});

  final Customer customer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              AppStatusBadge(
                label: _statusLabel(customer.status),
                variant: _statusVariant(customer.status),
              ),
              AppStatusBadge(
                label: customer.potential?.trim().isEmpty ?? true
                    ? 'Potencial nao informado'
                    : 'Potencial ${customer.potential}',
                variant: AppStatusBadgeVariant.info,
                icon: Icons.trending_up,
              ),
              AppStatusBadge(
                label: _lastPurchaseLabel(customer.lastPurchaseAt),
                variant: AppStatusBadgeVariant.neutral,
                icon: Icons.shopping_bag_outlined,
              ),
            ],
          );
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                customer.displayName,
                style: AppTypography.titleMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Text(
                customer.document.formatted,
                style: AppTypography.bodyMedium.copyWith(color: colors.outline),
              ),
            ],
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                const SizedBox(height: AppSpacing.spacing12),
                details,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: title),
              const SizedBox(width: AppSpacing.spacing16),
              Flexible(child: details),
            ],
          );
        },
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: 'Abrir visao 360 de ${customer.displayName}',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        onTap: onTap,
        child: card,
      ),
    );
  }

  String _statusLabel(CustomerStatus status) {
    return switch (status) {
      CustomerStatus.active => 'Ativo',
      CustomerStatus.inactive => 'Inativo',
      CustomerStatus.prospect => 'Prospect',
      CustomerStatus.blocked => 'Bloqueado',
    };
  }

  AppStatusBadgeVariant _statusVariant(CustomerStatus status) {
    return switch (status) {
      CustomerStatus.active => AppStatusBadgeVariant.success,
      CustomerStatus.inactive => AppStatusBadgeVariant.neutral,
      CustomerStatus.prospect => AppStatusBadgeVariant.info,
      CustomerStatus.blocked => AppStatusBadgeVariant.error,
    };
  }

  String _lastPurchaseLabel(DateTime? date) {
    if (date == null) return 'Sem compra';
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    return 'Ultima compra $day/$month/${localDate.year}';
  }
}
