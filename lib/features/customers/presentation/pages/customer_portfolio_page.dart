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

class CustomerPortfolioPage extends StatelessWidget {
  const CustomerPortfolioPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialSearchQuery = '',
    this.initialFilters = CustomerPortfolioFilters.empty,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final CustomerPortfolioBloc Function() createBloc;
  final String initialSearchQuery;
  final CustomerPortfolioFilters initialFilters;
  final void Function(String searchQuery, CustomerPortfolioFilters filters)?
  onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.customerView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<CustomerPortfolioBloc>(
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
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _CustomerPortfolioScaffold extends StatelessWidget {
  const _CustomerPortfolioScaffold({this.onUrlStateChanged});

  final void Function(String searchQuery, CustomerPortfolioFilters filters)?
  onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerPortfolioBloc, CustomerPortfolioState>(
      listenWhen: (previous, current) =>
          previous.searchQuery != current.searchQuery ||
          previous.filters != current.filters,
      listener: (context, state) =>
          onUrlStateChanged?.call(state.searchQuery, state.filters),
      child: BlocBuilder<CustomerPortfolioBloc, CustomerPortfolioState>(
        builder: (context, state) {
          return Scaffold(
            body: AppAdminPageLayout(
              title: 'Carteira de clientes',
              filtersTitle: 'Filtros da carteira',
              filtersBuilder: (_) => _PortfolioFilters(state: state),
              content: _PortfolioContent(state: state),
            ),
          );
        },
      ),
    );
  }
}

class _PortfolioContent extends StatefulWidget {
  const _PortfolioContent({required this.state});

  final CustomerPortfolioState state;

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
              return _CustomerPortfolioCard(customer: state.customers[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _PortfolioFilters extends StatefulWidget {
  const _PortfolioFilters({required this.state});

  final CustomerPortfolioState state;

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
  const _CustomerPortfolioCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
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
