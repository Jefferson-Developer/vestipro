import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/customer_dashboard_filters.dart';
import '../../domain/entities/customer_dashboard_ranking_row.dart';
import '../../domain/entities/customer_dashboard_snapshot.dart';
import '../../domain/entities/executive_dashboard_metric.dart';
import '../../domain/value_objects/customer_dashboard_sort_field.dart';
import '../bloc/customer_dashboard_bloc.dart';
import '../bloc/customer_dashboard_event.dart';
import '../bloc/customer_dashboard_state.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);
final DateFormat _monthLabelFormat = DateFormat('MMMM/yyyy', 'pt_BR');

const String _noTeamOptionValue = '';

/// Customer Dashboard (TASK-136, EPIC-17): "análise de carteira, retenção,
/// ativação e ranking de clientes" — clientes ativos/novos/reativados, taxa
/// de recompra, frequência média de compra, churn, cobertura de carteira e
/// positivação, mais um ranking de clientes por faturamento/frequência/
/// ticket médio com drill-down até o detalhe do cliente 360 (TASK-052).
///
/// Reads exclusively from [CustomerDashboardBloc] (`AggregationRepository`,
/// TASK-133, e `PositivacaoRepository`, TASK-117 — never uma consulta bruta
/// a `orders`/`customers`). Gated behind [Capability.reportViewSensitive] —
/// mesma capability que [SalesDashboardPage]/[ExecutiveDashboardPage] já
/// exigem; ver os próprios docs de [CustomerDashboardBloc] para a lacuna
/// documentada de acesso do SALES_REP.
class CustomerDashboardPage extends StatelessWidget {
  const CustomerDashboardPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.initialFilters,
    required this.onDrillDownToCustomer,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final CustomerDashboardBloc Function() createBloc;
  final CustomerDashboardFilters initialFilters;

  /// Called when the caller drills down from a ranking row into the
  /// customer's own 360 detail (TASK-052) — the composition root
  /// (`bootstrap.dart`) decides the actual navigation, same "this page never
  /// hard-codes another feature's route" contract
  /// `SalesDashboardPage.onDrillDownToOrders` already sets.
  final ValueChanged<String> onDrillDownToCustomer;

  /// Called whenever [CustomerDashboardFilters] change, so the host can
  /// mirror them into the URL (Flutter Web deep link) — same contract
  /// `SalesDashboardPage.onUrlStateChanged` already sets.
  final void Function(CustomerDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<CustomerDashboardBloc>(
          create: (_) => createBloc()
            ..add(
              CustomerDashboardStarted(
                organizationId: organizationId,
                userId: userId,
                initialFilters: initialFilters,
              ),
            ),
          child: _CustomerDashboardView(
            onDrillDownToCustomer: onDrillDownToCustomer,
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _CustomerDashboardView extends StatelessWidget {
  const _CustomerDashboardView({
    required this.onDrillDownToCustomer,
    this.onUrlStateChanged,
  });

  final ValueChanged<String> onDrillDownToCustomer;
  final void Function(CustomerDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerDashboardBloc, CustomerDashboardState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) => onUrlStateChanged?.call(state.filters),
      builder: (context, state) {
        final bloc = context.read<CustomerDashboardBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Dashboard de clientes',
            filtersTitle: 'Filtros do dashboard de clientes',
            filtersBuilder: (_) => _CustomerDashboardFiltersForm(
              state: state,
              onChanged: (filters) =>
                  bloc.add(CustomerDashboardFiltersChanged(filters)),
            ),
            content: _CustomerDashboardContent(
              state: state,
              onRetry: () => bloc.add(const CustomerDashboardRetried()),
              onRankingRetry: () =>
                  bloc.add(const CustomerDashboardRankingRetried()),
              onSortChanged: (field, descending) => bloc.add(
                CustomerDashboardFiltersChanged(
                  state.filters.copyWith(
                    sortField: field,
                    sortDescending: descending,
                  ),
                ),
              ),
              onLoadMoreRanking: () =>
                  bloc.add(const CustomerDashboardRankingPageRequested()),
              onDrillDownToCustomer: onDrillDownToCustomer,
            ),
          ),
        );
      },
    );
  }
}

class _CustomerDashboardFiltersForm extends StatefulWidget {
  const _CustomerDashboardFiltersForm({
    required this.state,
    required this.onChanged,
  });

  final CustomerDashboardState state;
  final ValueChanged<CustomerDashboardFilters> onChanged;

  @override
  State<_CustomerDashboardFiltersForm> createState() =>
      _CustomerDashboardFiltersFormState();
}

class _CustomerDashboardFiltersFormState
    extends State<_CustomerDashboardFiltersForm> {
  late final TextEditingController _segmentController = TextEditingController(
    text: widget.state.filters.segment ?? '',
  );

  @override
  void dispose() {
    _segmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final filters = state.filters;
    final onChanged = widget.onChanged;
    final now = DateTime.now();
    final nextMonth = DateTime.utc(filters.year, filters.month + 1);
    final nextMonthFilters = filters.copyWith(
      year: nextMonth.year,
      month: nextMonth.month,
    );
    final isNextMonthInTheFuture = nextMonthFilters.isAfter(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Período de referência', style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.spacing8),
        Row(
          children: <Widget>[
            AppIconButton(
              icon: Icons.chevron_left,
              semanticLabel: 'Mês anterior',
              onPressed: () => onChanged(filters.previousMonth),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthLabel(filters),
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            AppIconButton(
              icon: Icons.chevron_right,
              semanticLabel: 'Próximo mês',
              onPressed: isNextMonthInTheFuture
                  ? null
                  : () {
                      final next = DateTime.utc(
                        filters.year,
                        filters.month + 1,
                      );
                      onChanged(
                        filters.copyWith(year: next.year, month: next.month),
                      );
                    },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing16),
        if (state.companyOptions.length > 1) ...<Widget>[
          AppDropdown<String>(
            options: <AppDropdownOption<String>>[
              for (final option in state.companyOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            selectedValues: <String>{filters.companyId},
            onChanged: (values) =>
                onChanged(filters.copyWith(companyId: values.first)),
            closeSemanticLabel: 'Fechar seleção de empresa',
            label: 'Empresa',
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        if (state.teamOptions.isNotEmpty) ...<Widget>[
          AppDropdown<String>(
            options: <AppDropdownOption<String>>[
              const AppDropdownOption(
                value: _noTeamOptionValue,
                label: 'Toda a empresa',
              ),
              for (final option in state.teamOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            selectedValues: <String>{filters.teamId ?? _noTeamOptionValue},
            onChanged: (values) {
              final selected = values.first;
              onChanged(
                selected == _noTeamOptionValue
                    ? filters.copyWith(clearTeamId: true)
                    : filters.copyWith(teamId: selected),
              );
            },
            closeSemanticLabel: 'Fechar seleção de equipe',
            label: 'Equipe',
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'A tabela de ranking de clientes não é restrita por equipe hoje '
            '(a agregação por cliente não carrega vendedor/equipe).',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        Text('Segmento do cliente', style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.spacing8),
        AppTextField(
          controller: _segmentController,
          label: 'Filtrar por segmento (opcional)',
          onSubmitted: (value) {
            final trimmed = value.trim();
            onChanged(
              trimmed.isEmpty
                  ? filters.copyWith(clearSegment: true)
                  : filters.copyWith(segment: trimmed),
            );
          },
        ),
      ],
    );
  }

  String _monthLabel(CustomerDashboardFilters filters) {
    final label = _monthLabelFormat.format(
      DateTime.utc(filters.year, filters.month),
    );
    return label[0].toUpperCase() + label.substring(1);
  }
}

class _CustomerDashboardContent extends StatelessWidget {
  const _CustomerDashboardContent({
    required this.state,
    required this.onRetry,
    required this.onRankingRetry,
    required this.onSortChanged,
    required this.onLoadMoreRanking,
    required this.onDrillDownToCustomer,
  });

  final CustomerDashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onRankingRetry;
  final void Function(CustomerDashboardSortField field, bool descending)
  onSortChanged;
  final VoidCallback onLoadMoreRanking;
  final ValueChanged<String> onDrillDownToCustomer;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CustomerDashboardStatus.initial:
      case CustomerDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CustomerDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso ao dashboard de clientes',
          description:
              'Você não tem permissão para ver esta análise de carteira de '
              'clientes. Fale com um administrador caso acredite que isso é '
              'um engano.',
        );
      case CustomerDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o dashboard de clientes',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
        );
      case CustomerDashboardStatus.ready:
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _CustomerDashboardBody(
          state: state,
          snapshot: snapshot,
          onRankingRetry: onRankingRetry,
          onSortChanged: onSortChanged,
          onLoadMoreRanking: onLoadMoreRanking,
          onDrillDownToCustomer: onDrillDownToCustomer,
        );
    }
  }
}

class _CustomerDashboardBody extends StatelessWidget {
  const _CustomerDashboardBody({
    required this.state,
    required this.snapshot,
    required this.onRankingRetry,
    required this.onSortChanged,
    required this.onLoadMoreRanking,
    required this.onDrillDownToCustomer,
  });

  final CustomerDashboardState state;
  final CustomerDashboardSnapshot snapshot;
  final VoidCallback onRankingRetry;
  final void Function(CustomerDashboardSortField field, bool descending)
  onSortChanged;
  final VoidCallback onLoadMoreRanking;
  final ValueChanged<String> onDrillDownToCustomer;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Todos os valores abaixo referem-se a ${filters.monthKey} '
            '(${filters.companyId}'
            '${filters.teamId != null ? ' · equipe ${filters.teamId}' : ''}).',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Wrap(
            spacing: AppSpacing.spacing16,
            runSpacing: AppSpacing.spacing16,
            children: _kpiCards(),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text('Ranking de clientes', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.spacing8),
          _CustomerDashboardRankingTable(
            filters: filters,
            status: state.rankingStatus,
            rows: state.visibleRankingRows,
            hasMore: state.hasMoreRankingRows,
            failureMessage: state.rankingFailure?.message,
            onRetry: onRankingRetry,
            onSortChanged: onSortChanged,
            onLoadMore: onLoadMoreRanking,
            onDrillDownToCustomer: onDrillDownToCustomer,
          ),
        ],
      ),
    );
  }

  List<Widget> _kpiCards() {
    return <Widget>[
      _metricCard(
        label: 'Clientes ativos',
        metric: snapshot.activeCustomers,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.groups_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Clientes novos',
        metric: snapshot.newCustomers,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.person_add_alt_outlined,
        notCalculatedLabel: 'Cálculo ainda não disponível',
      ),
      _metricCard(
        label: 'Clientes reativados',
        metric: snapshot.reactivatedCustomers,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.replay_outlined,
        notCalculatedLabel: 'Cálculo ainda não disponível',
      ),
      _metricCard(
        label: 'Taxa de recompra',
        metric: snapshot.repurchaseRatePercentage,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.repeat_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Frequência média de compra',
        metric: snapshot.averagePurchaseFrequency,
        format: (value) => '${value.toStringAsFixed(1)} pedidos/cliente',
        icon: Icons.event_repeat_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Churn',
        metric: snapshot.churnPercentage,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.trending_down,
        notCalculatedLabel: 'Sem base de comparação no mês anterior',
      ),
      _metricCard(
        label: 'Cobertura de carteira',
        metric: snapshot.portfolioCoverage,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.folder_shared_outlined,
        trendLabel: 'vs. mês anterior',
      ),
      _metricCard(
        label: 'Positivação',
        metric: snapshot.positivacaoPercentage,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.percent_outlined,
        trendLabel: 'vs. mês anterior',
      ),
    ];
  }

  Widget _metricCard({
    required String label,
    required ExecutiveDashboardMetric metric,
    required String Function(double) format,
    required IconData icon,
    String? trendLabel,
    String notCalculatedLabel = 'Cálculo ainda não disponível',
  }) {
    final value = switch (metric.status) {
      ExecutiveDashboardMetricStatus.available => format(metric.value!),
      ExecutiveDashboardMetricStatus.notCalculated => notCalculatedLabel,
      ExecutiveDashboardMetricStatus.failed => 'Indisponível no momento',
    };
    final change = metric.changePercentage;
    return SizedBox(
      width: 240,
      child: AppKpiCard(
        label: label,
        value: value,
        icon: icon,
        trend: change == null
            ? AppKpiTrend.neutral
            : (change >= 0 ? AppKpiTrend.up : AppKpiTrend.down),
        trendPercentage: metric.isAvailable ? change : null,
        trendLabel: metric.isAvailable && change != null ? trendLabel : null,
        semanticLabel: metric.status == ExecutiveDashboardMetricStatus.failed
            ? '$label: não foi possível carregar (${metric.failureMessage})'
            : null,
      ),
    );
  }
}

class _CustomerDashboardRankingTable extends StatelessWidget {
  const _CustomerDashboardRankingTable({
    required this.filters,
    required this.status,
    required this.rows,
    required this.hasMore,
    required this.failureMessage,
    required this.onRetry,
    required this.onSortChanged,
    required this.onLoadMore,
    required this.onDrillDownToCustomer,
  });

  final CustomerDashboardFilters filters;
  final CustomerDashboardRankingStatus status;
  final List<CustomerDashboardRankingRow> rows;
  final bool hasMore;
  final String? failureMessage;
  final VoidCallback onRetry;
  final void Function(CustomerDashboardSortField field, bool descending)
  onSortChanged;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onDrillDownToCustomer;

  int get _sortColumnIndex => switch (filters.sortField) {
    CustomerDashboardSortField.revenue => 1,
    CustomerDashboardSortField.frequency => 2,
    CustomerDashboardSortField.averageTicket => 3,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDataTable<CustomerDashboardRankingRow>(
          status: switch (status) {
            CustomerDashboardRankingStatus.loading =>
              AppDataTableStatus.loading,
            CustomerDashboardRankingStatus.error => AppDataTableStatus.error,
            CustomerDashboardRankingStatus.ready =>
              rows.isEmpty ? AppDataTableStatus.empty : AppDataTableStatus.idle,
          },
          rows: rows,
          rowIdBuilder: (row) => row.customerId,
          emptyTitle: 'Nenhum cliente com pedido neste período',
          emptyDescription:
              'Ajuste os filtros ou aguarde novos pedidos serem processados.',
          errorTitle: 'Não foi possível carregar o ranking de clientes',
          errorMessage: failureMessage ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: !filters.sortDescending,
          onSort: (columnIndex, ascending) {
            final field = switch (columnIndex) {
              2 => CustomerDashboardSortField.frequency,
              3 => CustomerDashboardSortField.averageTicket,
              _ => CustomerDashboardSortField.revenue,
            };
            onSortChanged(field, !ascending);
          },
          mobileCardTitleBuilder: (context, row) => Text(row.customerName),
          columns: <AppDataColumn<CustomerDashboardRankingRow>>[
            AppDataColumn(
              label: 'Cliente',
              cellBuilder: (context, row) => Text(row.customerName),
            ),
            AppDataColumn(
              label: 'Faturamento',
              numeric: true,
              sortable: true,
              cellBuilder: (context, row) =>
                  Text(_currencyFormat.format(row.revenueNet)),
            ),
            AppDataColumn(
              label: 'Pedidos',
              numeric: true,
              sortable: true,
              cellBuilder: (context, row) => Text('${row.orderCount}'),
            ),
            AppDataColumn(
              label: 'Ticket médio',
              numeric: true,
              sortable: true,
              cellBuilder: (context, row) =>
                  Text(_currencyFormat.format(row.averageTicket)),
            ),
            AppDataColumn(
              label: 'Segmento',
              cellBuilder: (context, row) => Text(row.segment ?? '—'),
            ),
          ],
          rowActions: <AppDataTableAction<CustomerDashboardRankingRow>>[
            AppDataTableAction<CustomerDashboardRankingRow>(
              icon: Icons.person_search_outlined,
              semanticLabel: 'Ver detalhe do cliente',
              onPressed: (row) => onDrillDownToCustomer(row.customerId),
            ),
          ],
        ),
        if (status == CustomerDashboardRankingStatus.ready &&
            hasMore) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing16),
          Center(
            child: AppButton(
              label: 'Carregar mais clientes',
              semanticLabel: 'Carregar mais clientes no ranking',
              variant: AppButtonVariant.secondary,
              onPressed: onLoadMore,
            ),
          ),
        ],
      ],
    );
  }
}
