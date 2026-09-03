import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../orders/domain/entities/order_list_filters.dart';
import '../../domain/entities/sales_dashboard_filters.dart';
import '../../domain/entities/sales_dashboard_group_row.dart';
import '../../domain/entities/sales_dashboard_kpi.dart';
import '../../domain/entities/sales_dashboard_snapshot.dart';
import '../../domain/value_objects/sales_dashboard_comparison_mode.dart';
import '../../domain/value_objects/sales_dashboard_group_dimension.dart';
import '../../domain/value_objects/sales_dashboard_sort_field.dart';
import '../bloc/sales_dashboard_bloc.dart';
import '../bloc/sales_dashboard_event.dart';
import '../bloc/sales_dashboard_state.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);
final NumberFormat _integerFormat = NumberFormat.decimalPattern('pt_BR');
final DateFormat _monthLabelFormat = DateFormat('MMMM/yyyy', 'pt_BR');
final DateFormat _dayLabelFormat = DateFormat('dd/MM');

const String _noTeamOptionValue = '';

/// Sales Dashboard (TASK-135, EPIC-17): "análise detalhada de pedidos e
/// faturamento, com comparação temporal e capacidade de drill-down até o
/// pedido individual" — faturamento/quantidade vendida/pedidos/ticket
/// médio/desconto médio/margem/peças por pedido/produtos por pedido (com
/// comparação MoM e YoY), um gráfico de tendência diária e uma tabela de
/// agrupamento (por vendedor/cliente/produto/categoria) com drill-down até a
/// lista de pedidos que a compõe.
///
/// Reads exclusively from [SalesDashboardBloc] (`AggregationRepository`,
/// TASK-133 — never a raw query). Gated behind [Capability
/// .reportViewSensitive] — same capability/company-team scoping shape
/// [ExecutiveDashboardPage] already uses; see [SalesDashboardBloc]'s own
/// docs for the documented SALES_REP access gap.
class SalesDashboardPage extends StatelessWidget {
  const SalesDashboardPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.initialFilters,
    required this.onDrillDownToOrders,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final SalesDashboardBloc Function() createBloc;
  final SalesDashboardFilters initialFilters;

  /// Called when the caller drills down from an aggregated KPI/row into the
  /// orders composing it — the composition root (`bootstrap.dart`) decides
  /// the actual navigation (always into the existing `OrderListRoute`,
  /// TASK-102), same "this page never hard-codes another feature's route"
  /// contract `ExecutiveDashboardPage.onOpenOpportunityCenter` already sets.
  final ValueChanged<OrderListFilters> onDrillDownToOrders;

  /// Called whenever [SalesDashboardFilters] change, so the host can mirror
  /// them into the URL (Flutter Web deep link) — same contract
  /// `ExecutiveDashboardPage.onUrlStateChanged` already sets.
  final void Function(SalesDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<SalesDashboardBloc>(
          create: (_) => createBloc()
            ..add(
              SalesDashboardStarted(
                organizationId: organizationId,
                userId: userId,
                initialFilters: initialFilters,
              ),
            ),
          child: _SalesDashboardView(
            onDrillDownToOrders: onDrillDownToOrders,
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _SalesDashboardView extends StatelessWidget {
  const _SalesDashboardView({
    required this.onDrillDownToOrders,
    this.onUrlStateChanged,
  });

  final ValueChanged<OrderListFilters> onDrillDownToOrders;
  final void Function(SalesDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesDashboardBloc, SalesDashboardState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) => onUrlStateChanged?.call(state.filters),
      builder: (context, state) {
        final bloc = context.read<SalesDashboardBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Dashboard de vendas',
            filtersTitle: 'Filtros do dashboard de vendas',
            filtersBuilder: (_) => _SalesDashboardFiltersForm(
              state: state,
              onChanged: (filters) =>
                  bloc.add(SalesDashboardFiltersChanged(filters)),
            ),
            content: _SalesDashboardContent(
              state: state,
              onRetry: () => bloc.add(const SalesDashboardRetried()),
              onGroupRowsRetry: () =>
                  bloc.add(const SalesDashboardGroupRowsRetried()),
              onSortChanged: (field, descending) => bloc.add(
                SalesDashboardFiltersChanged(
                  state.filters.copyWith(
                    sortField: field,
                    sortDescending: descending,
                  ),
                ),
              ),
              onDrillDownToOrders: onDrillDownToOrders,
            ),
          ),
        );
      },
    );
  }
}

class _SalesDashboardFiltersForm extends StatelessWidget {
  const _SalesDashboardFiltersForm({
    required this.state,
    required this.onChanged,
  });

  final SalesDashboardState state;
  final ValueChanged<SalesDashboardFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
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
                  : () => onChanged(nextMonthFilters),
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
          const SizedBox(height: AppSpacing.spacing16),
        ],
        Text(
          'Agrupar tabela por',
          style: AppTypography.labelLarge.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            for (final dimension in SalesDashboardGroupDimension.values)
              AppFilterChip(
                label: _groupDimensionLabel(dimension),
                selected: filters.groupDimension == dimension,
                onSelected: (selected) {
                  if (selected) {
                    onChanged(filters.copyWith(groupDimension: dimension));
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Text(
          'Comparar tabela com',
          style: AppTypography.labelLarge.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            AppFilterChip(
              label: 'Mês anterior',
              selected:
                  filters.comparisonMode ==
                  SalesDashboardComparisonMode.previousMonth,
              onSelected: (selected) {
                if (selected) {
                  onChanged(
                    filters.copyWith(
                      comparisonMode:
                          SalesDashboardComparisonMode.previousMonth,
                    ),
                  );
                }
              },
            ),
            AppFilterChip(
              label: 'Mesmo mês do ano anterior',
              selected:
                  filters.comparisonMode ==
                  SalesDashboardComparisonMode.previousYear,
              onSelected: (selected) {
                if (selected) {
                  onChanged(
                    filters.copyWith(
                      comparisonMode: SalesDashboardComparisonMode.previousYear,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  String _monthLabel(SalesDashboardFilters filters) {
    final label = _monthLabelFormat.format(
      DateTime.utc(filters.year, filters.month),
    );
    return label[0].toUpperCase() + label.substring(1);
  }
}

String _groupDimensionLabel(SalesDashboardGroupDimension dimension) {
  return switch (dimension) {
    SalesDashboardGroupDimension.seller => 'Vendedor',
    SalesDashboardGroupDimension.customer => 'Cliente',
    SalesDashboardGroupDimension.product => 'Produto',
    SalesDashboardGroupDimension.category => 'Categoria',
  };
}

class _SalesDashboardContent extends StatelessWidget {
  const _SalesDashboardContent({
    required this.state,
    required this.onRetry,
    required this.onGroupRowsRetry,
    required this.onSortChanged,
    required this.onDrillDownToOrders,
  });

  final SalesDashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onGroupRowsRetry;
  final void Function(SalesDashboardSortField field, bool descending)
  onSortChanged;
  final ValueChanged<OrderListFilters> onDrillDownToOrders;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SalesDashboardStatus.initial:
      case SalesDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case SalesDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso ao dashboard de vendas',
          description:
              'Você não tem permissão para ver esta análise de pedidos e '
              'faturamento. Fale com um administrador caso acredite que isso '
              'é um engano.',
        );
      case SalesDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o dashboard de vendas',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
        );
      case SalesDashboardStatus.ready:
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _SalesDashboardBody(
          filters: state.filters,
          snapshot: snapshot,
          groupRowsStatus: state.groupRowsStatus,
          groupRows: state.groupRows,
          groupRowsFailure: state.groupRowsFailure,
          onGroupRowsRetry: onGroupRowsRetry,
          onSortChanged: onSortChanged,
          onDrillDownToOrders: onDrillDownToOrders,
        );
    }
  }
}

class _SalesDashboardBody extends StatelessWidget {
  const _SalesDashboardBody({
    required this.filters,
    required this.snapshot,
    required this.groupRowsStatus,
    required this.groupRows,
    required this.groupRowsFailure,
    required this.onGroupRowsRetry,
    required this.onSortChanged,
    required this.onDrillDownToOrders,
  });

  final SalesDashboardFilters filters;
  final SalesDashboardSnapshot snapshot;
  final SalesDashboardGroupRowsStatus groupRowsStatus;
  final List<SalesDashboardGroupRow> groupRows;
  final Object? groupRowsFailure;
  final VoidCallback onGroupRowsRetry;
  final void Function(SalesDashboardSortField field, bool descending)
  onSortChanged;
  final ValueChanged<OrderListFilters> onDrillDownToOrders;

  @override
  Widget build(BuildContext context) {
    final periodEndInclusive = filters.periodEnd.subtract(
      const Duration(milliseconds: 1),
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Todos os valores abaixo referem-se a '
                  '${filters.monthKey} (${filters.companyId}'
                  '${filters.teamId != null ? ' · equipe ${filters.teamId}' : ''}).',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.outline,
                  ),
                ),
              ),
              AppButton(
                label: 'Ver pedidos do período',
                semanticLabel: 'Ver pedidos do período filtrado',
                variant: AppButtonVariant.secondary,
                leadingIcon: Icons.receipt_long_outlined,
                onPressed: () => onDrillDownToOrders(
                  OrderListFilters(
                    from: filters.periodStart,
                    to: periodEndInclusive,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Wrap(
            spacing: AppSpacing.spacing16,
            runSpacing: AppSpacing.spacing16,
            children: _kpiCards(),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Este gráfico responde: o faturamento diário está subindo ou '
            'caindo ao longo do mês filtrado?',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppManagementChart(
            type: AppChartType.line,
            series: <AppChartSeries>[
              AppChartSeries(
                label: 'Faturamento diário',
                points: <AppChartPoint>[
                  for (final point in snapshot.revenueTrend)
                    AppChartPoint(
                      x: point.day.day.toDouble(),
                      y: point.value,
                      label: _dayLabelFormat.format(point.day),
                    ),
                ],
              ),
            ],
            valueFormatter: (value) => _currencyFormat.format(value),
            emptyDescription:
                'Ainda não há faturamento registrado neste período.',
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Detalhamento por ${_groupDimensionLabel(filters.groupDimension).toLowerCase()}',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          _SalesDashboardGroupTable(
            filters: filters,
            status: groupRowsStatus,
            rows: groupRows,
            failureMessage: groupRowsFailure == null
                ? null
                : '$groupRowsFailure',
            onRetry: onGroupRowsRetry,
            onSortChanged: onSortChanged,
            onDrillDownToOrders: onDrillDownToOrders,
          ),
        ],
      ),
    );
  }

  List<Widget> _kpiCards() {
    return <Widget>[
      _SalesKpiCard(
        label: 'Faturamento',
        kpi: snapshot.revenue,
        format: _currencyFormat.format,
        icon: Icons.payments_outlined,
      ),
      _SalesKpiCard(
        label: 'Pedidos',
        kpi: snapshot.orders,
        format: (value) => _integerFormat.format(value),
        icon: Icons.receipt_long_outlined,
      ),
      _SalesKpiCard(
        label: 'Ticket médio',
        kpi: snapshot.averageTicket,
        format: _currencyFormat.format,
        icon: Icons.local_offer_outlined,
      ),
      _SalesKpiCard(
        label: 'Quantidade vendida',
        kpi: snapshot.itemQuantity,
        format: (value) => _integerFormat.format(value),
        icon: Icons.inventory_2_outlined,
      ),
      _SalesKpiCard(
        label: 'Desconto médio',
        kpi: snapshot.discountAverage,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.percent_outlined,
      ),
      _SalesKpiCard(
        label: 'Margem',
        kpi: snapshot.margin,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.pie_chart_outline,
        notCalculatedLabel: 'Sem dado de custo/margem disponível',
      ),
      _SalesKpiCard(
        label: 'Peças por pedido',
        kpi: snapshot.piecesPerOrder,
        format: (value) => value.toStringAsFixed(1),
        icon: Icons.checkroom_outlined,
      ),
      _SalesKpiCard(
        label: 'Produtos por pedido',
        kpi: snapshot.productsPerOrder,
        format: (value) => value.toStringAsFixed(1),
        icon: Icons.category_outlined,
        notCalculatedLabel: 'Cálculo ainda não disponível',
      ),
    ];
  }
}

/// KPI card showing both MoM and YoY comparison at once (seção 12.2: "com
/// comparação MoM e YoY") — deliberately not [AppKpiCard] itself, which only
/// ever renders one trend row; mirrors the exact same container styling
/// (`AppSpacing`/`AppRadius`/`AppTypography` tokens) so it reads as the same
/// component family.
class _SalesKpiCard extends StatelessWidget {
  const _SalesKpiCard({
    required this.label,
    required this.kpi,
    required this.format,
    required this.icon,
    this.notCalculatedLabel = 'Cálculo ainda não disponível',
  });

  final String label;
  final SalesDashboardKpi kpi;
  final String Function(double) format;
  final IconData icon;
  final String notCalculatedLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = switch (kpi.status) {
      SalesDashboardKpiStatus.available => format(kpi.value!),
      SalesDashboardKpiStatus.notCalculated => notCalculatedLabel,
      SalesDashboardKpiStatus.failed => 'Indisponível no momento',
    };
    return SizedBox(
      width: 240,
      child: Semantics(
        label: kpi.status == SalesDashboardKpiStatus.failed
            ? '$label: não foi possível carregar (${kpi.failureMessage})'
            : '$label: $value',
        container: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.radius16),
            border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ),
                  Icon(icon, size: AppIconSizes.lg, color: colors.outline),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                value,
                style: AppTypography.headlineMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
              if (kpi.isAvailable) ...<Widget>[
                _trendRow(
                  colors,
                  label: 'MoM',
                  percentage: kpi.momChangePercentage,
                ),
                _trendRow(
                  colors,
                  label: 'YoY',
                  percentage: kpi.yoyChangePercentage,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _trendRow(
    AppColors colors, {
    required String label,
    required double? percentage,
  }) {
    if (percentage == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.spacing4),
        child: Text(
          '$label: sem comparação disponível',
          style: AppTypography.bodySmall.copyWith(color: colors.outline),
        ),
      );
    }
    final isUp = percentage >= 0;
    final color = isUp ? colors.success : colors.error;
    final sign = isUp ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spacing4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: AppIconSizes.sm,
            color: color,
          ),
          const SizedBox(width: AppSpacing.spacing4),
          Text(
            '$label $sign${percentage.toStringAsFixed(1)}%',
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SalesDashboardGroupTable extends StatelessWidget {
  const _SalesDashboardGroupTable({
    required this.filters,
    required this.status,
    required this.rows,
    required this.failureMessage,
    required this.onRetry,
    required this.onSortChanged,
    required this.onDrillDownToOrders,
  });

  final SalesDashboardFilters filters;
  final SalesDashboardGroupRowsStatus status;
  final List<SalesDashboardGroupRow> rows;
  final String? failureMessage;
  final VoidCallback onRetry;
  final void Function(SalesDashboardSortField field, bool descending)
  onSortChanged;
  final ValueChanged<OrderListFilters> onDrillDownToOrders;

  /// Only `seller`/`customer` rows map onto an `OrderListFilters` field
  /// (`sellerIds`/`customerId`) — `product`/`category` rows have no
  /// equivalent filter on `Order` today (no per-item index), so drill-down
  /// is not offered for them, a documented gap (see
  /// `SalesDashboardBloc`/the task's own CONCLUIDA doc) rather than a raw
  /// client-side scan of every order's line items.
  bool get _supportsDrillDown =>
      filters.groupDimension == SalesDashboardGroupDimension.seller ||
      filters.groupDimension == SalesDashboardGroupDimension.customer;

  int get _sortColumnIndex => switch (filters.sortField) {
    SalesDashboardSortField.label => 0,
    SalesDashboardSortField.revenue => 1,
    SalesDashboardSortField.orders => 2,
    SalesDashboardSortField.quantity => 3,
  };

  @override
  Widget build(BuildContext context) {
    final comparisonLabel =
        filters.comparisonMode == SalesDashboardComparisonMode.previousMonth
        ? 'vs. mês anterior'
        : 'vs. mesmo mês/ano anterior';

    return AppDataTable<SalesDashboardGroupRow>(
      status: switch (status) {
        SalesDashboardGroupRowsStatus.loading => AppDataTableStatus.loading,
        SalesDashboardGroupRowsStatus.error => AppDataTableStatus.error,
        SalesDashboardGroupRowsStatus.ready =>
          rows.isEmpty ? AppDataTableStatus.empty : AppDataTableStatus.idle,
      },
      rows: rows,
      rowIdBuilder: (row) => row.scopeId,
      emptyTitle: 'Nenhum dado para este agrupamento/período',
      emptyDescription:
          'Ajuste os filtros ou aguarde novos pedidos serem processados.',
      errorTitle: 'Não foi possível carregar o detalhamento',
      errorMessage: failureMessage ?? 'Tente novamente em breve.',
      retryLabel: 'Tentar novamente',
      onRetry: onRetry,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: !filters.sortDescending,
      onSort: (columnIndex, ascending) {
        final field = switch (columnIndex) {
          0 => SalesDashboardSortField.label,
          1 => SalesDashboardSortField.revenue,
          2 => SalesDashboardSortField.orders,
          _ => SalesDashboardSortField.quantity,
        };
        onSortChanged(field, !ascending);
      },
      mobileCardTitleBuilder: (context, row) => Text(row.label),
      columns: <AppDataColumn<SalesDashboardGroupRow>>[
        AppDataColumn(
          label: _groupDimensionLabel(filters.groupDimension),
          sortable: true,
          cellBuilder: (context, row) => Text(row.label),
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
          cellBuilder: (context, row) =>
              Text(_integerFormat.format(row.orderCount)),
        ),
        AppDataColumn(
          label: 'Itens',
          numeric: true,
          sortable: true,
          cellBuilder: (context, row) =>
              Text(_integerFormat.format(row.itemQuantity)),
        ),
        AppDataColumn(
          label: 'Ticket médio',
          numeric: true,
          cellBuilder: (context, row) =>
              Text(_currencyFormat.format(row.averageTicket)),
        ),
        AppDataColumn(
          label: 'Desconto',
          numeric: true,
          cellBuilder: (context, row) =>
              Text(_currencyFormat.format(row.discountAmount)),
        ),
        AppDataColumn(
          label: 'Crescimento ($comparisonLabel)',
          numeric: true,
          cellBuilder: (context, row) => _GrowthCell(row: row),
        ),
      ],
      rowActions: !_supportsDrillDown
          ? const <AppDataTableAction<SalesDashboardGroupRow>>[]
          : <AppDataTableAction<SalesDashboardGroupRow>>[
              AppDataTableAction<SalesDashboardGroupRow>(
                icon: Icons.receipt_long_outlined,
                semanticLabel: 'Ver pedidos deste agrupamento',
                onPressed: (row) => onDrillDownToOrders(
                  OrderListFilters(
                    customerId:
                        filters.groupDimension ==
                            SalesDashboardGroupDimension.customer
                        ? row.scopeId
                        : null,
                    sellerIds:
                        filters.groupDimension ==
                            SalesDashboardGroupDimension.seller
                        ? <String>{row.scopeId}
                        : const <String>{},
                    from: filters.periodStart,
                    to: filters.periodEnd.subtract(
                      const Duration(milliseconds: 1),
                    ),
                  ),
                ),
              ),
            ],
    );
  }
}

class _GrowthCell extends StatelessWidget {
  const _GrowthCell({required this.row});

  final SalesDashboardGroupRow row;

  @override
  Widget build(BuildContext context) {
    final percentage = row.changePercentage;
    final absolute = row.changeAbsolute;
    if (percentage == null || absolute == null) {
      return Text(
        'Novo no período',
        style: AppTypography.bodySmall.copyWith(color: context.colors.outline),
      );
    }
    final isUp = percentage >= 0;
    final color = isUp ? context.colors.success : context.colors.error;
    final sign = isUp ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$sign${percentage.toStringAsFixed(1)}%',
          style: AppTypography.labelMedium.copyWith(color: color),
        ),
        Text(
          '$sign${_currencyFormat.format(absolute)}',
          style: AppTypography.bodySmall.copyWith(color: color),
        ),
      ],
    );
  }
}
