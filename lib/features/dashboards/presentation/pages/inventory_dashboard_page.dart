import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../inventory/domain/entities/stock_alert.dart';
import '../../../inventory/domain/value_objects/stock_alert_level.dart';
import '../../../inventory/domain/value_objects/stock_alert_transition_type.dart';
import '../../domain/entities/executive_dashboard_metric.dart';
import '../../domain/entities/inventory_dashboard_filters.dart';
import '../../domain/entities/inventory_dashboard_snapshot.dart';
import '../../domain/entities/inventory_dashboard_stalled_product_row.dart';
import '../bloc/inventory_dashboard_bloc.dart';
import '../bloc/inventory_dashboard_event.dart';
import '../bloc/inventory_dashboard_state.dart';

final DateFormat _monthLabelFormat = DateFormat('MMMM/yyyy', 'pt_BR');

const String _noOptionValue = '';
const List<int> _stalledThresholdOptions = <int>[30, 60, 90];

/// Inventory Dashboard (TASK-139, EPIC-17): "cobertura, sell-through,
/// produtos parados e alertas de ruptura consolidados" — uma visão única da
/// saúde do inventário, sem o gestor precisar checar múltiplas telas
/// separadas.
///
/// Reads exclusively from [InventoryDashboardBloc]
/// (`GetStockTurnoverMetricsUseCase`/TASK-094 e `ListStockAlertsUseCase`/
/// TASK-093 — never a raw query against `orders`/`products`/`stockAlerts`).
/// Gated behind [Capability.reportViewSensitive] — mesma capability que todo
/// outro dashboard do EPIC-17 já exige.
///
/// **Lacunas documentadas** (ver `LoadInventoryDashboardSnapshotUseCase`'s
/// own docs e
/// `docs/tasks/TASK-139-implementar-dashboard-de-estoque-CONCLUIDA.md`):
/// nem `StockTurnoverMetricSnapshot` (TASK-094) nem `StockAlert` (TASK-093)
/// carregam uma dimensão de categoria — o filtro por categoria narrows
/// apenas a listagem de "produtos parados", nunca as KPIs de
/// cobertura/sell-through/giro nem os alertas consolidados. Cobertura/giro
/// por depósito e por coleção nunca são combinados (a TASK-094 não sustenta
/// um escopo produto+depósito nem coleção+depósito).
class InventoryDashboardPage extends StatelessWidget {
  const InventoryDashboardPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.initialFilters,
    required this.onDrillDownToProduct,
    this.onUrlStateChanged,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final InventoryDashboardBloc Function() createBloc;
  final InventoryDashboardFilters initialFilters;

  /// Called when the caller drills down from an alerta/produto parado into
  /// the produto's own detalhe de estoque por variante (TASK-078/TASK-090)
  /// — the composition root (`bootstrap.dart`) decides the actual
  /// navigation, same "this page never hard-codes another feature's route"
  /// contract `ProductDashboardPage.onDrillDownToProduct` already sets.
  final ValueChanged<String> onDrillDownToProduct;

  /// Called whenever [InventoryDashboardFilters] change, so the host can
  /// mirror them into the URL (Flutter Web deep link) — same contract
  /// `ProductDashboardPage.onUrlStateChanged` already sets.
  final void Function(InventoryDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<InventoryDashboardBloc>(
          create: (_) => createBloc()
            ..add(
              InventoryDashboardStarted(
                organizationId: organizationId,
                userId: userId,
                initialFilters: initialFilters,
              ),
            ),
          child: _InventoryDashboardView(
            onDrillDownToProduct: onDrillDownToProduct,
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _InventoryDashboardView extends StatelessWidget {
  const _InventoryDashboardView({
    required this.onDrillDownToProduct,
    this.onUrlStateChanged,
  });

  final ValueChanged<String> onDrillDownToProduct;
  final void Function(InventoryDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryDashboardBloc, InventoryDashboardState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) => onUrlStateChanged?.call(state.filters),
      builder: (context, state) {
        final bloc = context.read<InventoryDashboardBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Dashboard de estoque',
            filtersTitle: 'Filtros do dashboard de estoque',
            filtersBuilder: (_) => _InventoryDashboardFiltersForm(
              state: state,
              onChanged: (filters) =>
                  bloc.add(InventoryDashboardFiltersChanged(filters)),
            ),
            content: _InventoryDashboardContent(
              state: state,
              onRetry: () => bloc.add(const InventoryDashboardRetried()),
              onStalledProductsRetry: () =>
                  bloc.add(const InventoryDashboardStalledProductsRetried()),
              onLoadMoreStalledProducts: () => bloc.add(
                const InventoryDashboardStalledProductsPageRequested(),
              ),
              onDrillDownToProduct: onDrillDownToProduct,
            ),
          ),
        );
      },
    );
  }
}

class _InventoryDashboardFiltersForm extends StatelessWidget {
  const _InventoryDashboardFiltersForm({
    required this.state,
    required this.onChanged,
  });

  final InventoryDashboardState state;
  final ValueChanged<InventoryDashboardFilters> onChanged;

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
        if (state.warehouseOptions.isNotEmpty) ...<Widget>[
          AppDropdown<String>(
            options: <AppDropdownOption<String>>[
              const AppDropdownOption(
                value: _noOptionValue,
                label: 'Todos os depósitos',
              ),
              for (final option in state.warehouseOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            selectedValues: <String>{filters.warehouseId ?? _noOptionValue},
            onChanged: (values) {
              final selected = values.first;
              onChanged(
                selected == _noOptionValue
                    ? filters.copyWith(clearWarehouseId: true)
                    : filters.copyWith(warehouseId: selected),
              );
            },
            closeSemanticLabel: 'Fechar seleção de depósito',
            label: 'Depósito',
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        if (state.collectionOptions.isNotEmpty) ...<Widget>[
          AppDropdown<String>(
            options: <AppDropdownOption<String>>[
              const AppDropdownOption(
                value: _noOptionValue,
                label: 'Todas as coleções',
              ),
              for (final option in state.collectionOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            selectedValues: <String>{filters.collectionId ?? _noOptionValue},
            onChanged: (values) {
              final selected = values.first;
              onChanged(
                selected == _noOptionValue
                    ? filters.copyWith(clearCollectionId: true)
                    : filters.copyWith(collectionId: selected),
              );
            },
            closeSemanticLabel: 'Fechar seleção de coleção',
            label: 'Coleção',
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        if (state.categoryOptions.isNotEmpty) ...<Widget>[
          AppDropdown<String>(
            options: <AppDropdownOption<String>>[
              const AppDropdownOption(
                value: _noOptionValue,
                label: 'Todas as categorias',
              ),
              for (final option in state.categoryOptions)
                AppDropdownOption(value: option.id, label: option.name),
            ],
            selectedValues: <String>{filters.categoryId ?? _noOptionValue},
            onChanged: (values) {
              final selected = values.first;
              onChanged(
                selected == _noOptionValue
                    ? filters.copyWith(clearCategoryId: true)
                    : filters.copyWith(categoryId: selected),
              );
            },
            closeSemanticLabel: 'Fechar seleção de categoria',
            label: 'Categoria',
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        Text(
          'Produto parado a partir de (dias sem giro)',
          style: AppTypography.labelLarge,
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            for (final days in _stalledThresholdOptions)
              AppFilterChip(
                label: '$days dias',
                selected: filters.stalledCoverageDaysThreshold == days,
                onSelected: (selected) {
                  if (!selected) return;
                  onChanged(
                    filters.copyWith(stalledCoverageDaysThreshold: days),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Text(
          'Filtro por categoria se aplica apenas à lista de produtos '
          'parados: nem a cobertura/giro do depósito/coleção nem os alertas '
          'de ruptura carregam uma dimensão de categoria hoje.',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
      ],
    );
  }

  String _monthLabel(InventoryDashboardFilters filters) {
    final label = _monthLabelFormat.format(
      DateTime.utc(filters.year, filters.month),
    );
    return label[0].toUpperCase() + label.substring(1);
  }
}

class _InventoryDashboardContent extends StatelessWidget {
  const _InventoryDashboardContent({
    required this.state,
    required this.onRetry,
    required this.onStalledProductsRetry,
    required this.onLoadMoreStalledProducts,
    required this.onDrillDownToProduct,
  });

  final InventoryDashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onStalledProductsRetry;
  final VoidCallback onLoadMoreStalledProducts;
  final ValueChanged<String> onDrillDownToProduct;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case InventoryDashboardStatus.initial:
      case InventoryDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case InventoryDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso ao dashboard de estoque',
          description:
              'Você não tem permissão para ver esta análise de estoque. '
              'Fale com um administrador caso acredite que isso é um '
              'engano.',
        );
      case InventoryDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o dashboard de estoque',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
        );
      case InventoryDashboardStatus.ready:
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _InventoryDashboardBody(
          state: state,
          snapshot: snapshot,
          onStalledProductsRetry: onStalledProductsRetry,
          onLoadMoreStalledProducts: onLoadMoreStalledProducts,
          onDrillDownToProduct: onDrillDownToProduct,
        );
    }
  }
}

class _InventoryDashboardBody extends StatelessWidget {
  const _InventoryDashboardBody({
    required this.state,
    required this.snapshot,
    required this.onStalledProductsRetry,
    required this.onLoadMoreStalledProducts,
    required this.onDrillDownToProduct,
  });

  final InventoryDashboardState state;
  final InventoryDashboardSnapshot snapshot;
  final VoidCallback onStalledProductsRetry;
  final VoidCallback onLoadMoreStalledProducts;
  final ValueChanged<String> onDrillDownToProduct;

  @override
  Widget build(BuildContext context) {
    final filters = state.filters;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Todos os valores abaixo referem-se a ${filters.monthKey} '
            '(${filters.companyId})${_scopeSuffix(filters, snapshot)}.',
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
          Text(
            'Alertas de ruptura consolidados',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            snapshot.alertsHasMore
                ? 'Mostrando os ${snapshot.alerts.length} alertas mais '
                      'recentes — existem mais alertas ativos além destes.'
                : 'Todo alerta de ruptura ativo (TASK-093) está listado '
                      'abaixo.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          _AlertsTable(
            alerts: snapshot.alerts,
            onDrillDownToProduct: onDrillDownToProduct,
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text('Produtos parados', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Produtos cuja cobertura de estoque (TASK-094) alcança '
            '${filters.stalledCoverageDaysThreshold} dia(s) sem giro '
            'relevante no período. Granularidade por produto, sobre uma '
            'página do catálogo por vez — nunca o catálogo inteiro de uma '
            'só vez (ver documentação da task para o detalhe completo).',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          _StalledProductsTable(
            status: state.stalledProductsStatus,
            rows: state.stalledProductRows,
            hasMore: state.stalledProductsHasMore,
            failureMessage: state.stalledProductsFailure?.message,
            onRetry: onStalledProductsRetry,
            onLoadMore: onLoadMoreStalledProducts,
            onDrillDownToProduct: onDrillDownToProduct,
          ),
        ],
      ),
    );
  }

  String _scopeSuffix(
    InventoryDashboardFilters filters,
    InventoryDashboardSnapshot snapshot,
  ) {
    if (filters.warehouseId != null) return ', depósito selecionado';
    if (filters.collectionId != null) return ', coleção selecionada';
    if (snapshot.warehousesConsidered > 0) {
      return ', agregado sobre ${snapshot.warehousesConsidered} depósito(s) ativo(s)';
    }
    return '';
  }

  List<Widget> _kpiCards() {
    return <Widget>[
      _metricCard(
        label: 'Cobertura de estoque',
        metric: snapshot.coverageDays,
        format: (value) => '${value.toStringAsFixed(0)} dias',
        icon: Icons.calendar_month_outlined,
        notCalculatedLabel:
            'Selecione um depósito ou coleção para ver a cobertura '
            'agregada',
      ),
      _metricCard(
        label: 'Sell-through',
        metric: snapshot.sellThroughRate,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.trending_up,
        notCalculatedLabel:
            'Selecione um depósito ou coleção para ver o sell-through',
      ),
      _metricCard(
        label: 'Giro de estoque',
        metric: snapshot.turnoverRate,
        format: (value) => value.toStringAsFixed(2),
        icon: Icons.autorenew,
        notCalculatedLabel: 'Selecione um depósito ou coleção para ver o giro',
      ),
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: 'Alertas de ruptura ativos',
          value: '${snapshot.activeAlertCount}',
          icon: Icons.warning_amber_outlined,
          trend: snapshot.criticalAlertCount > 0
              ? AppKpiTrend.down
              : AppKpiTrend.neutral,
          trendLabel: '${snapshot.criticalAlertCount} crítico(s)',
        ),
      ),
    ];
  }

  Widget _metricCard({
    required String label,
    required ExecutiveDashboardMetric metric,
    required String Function(double) format,
    required IconData icon,
    required String notCalculatedLabel,
  }) {
    final value = switch (metric.status) {
      ExecutiveDashboardMetricStatus.available => format(metric.value!),
      ExecutiveDashboardMetricStatus.notCalculated => notCalculatedLabel,
      ExecutiveDashboardMetricStatus.failed => 'Indisponível no momento',
    };
    return SizedBox(
      width: 240,
      child: AppKpiCard(
        label: label,
        value: value,
        icon: icon,
        trend: AppKpiTrend.neutral,
        semanticLabel: metric.status == ExecutiveDashboardMetricStatus.failed
            ? '$label: não foi possível carregar (${metric.failureMessage})'
            : null,
      ),
    );
  }
}

class _AlertsTable extends StatelessWidget {
  const _AlertsTable({
    required this.alerts,
    required this.onDrillDownToProduct,
  });

  final List<StockAlert> alerts;
  final ValueChanged<String> onDrillDownToProduct;

  @override
  Widget build(BuildContext context) {
    return AppDataTable<StockAlert>(
      status: alerts.isEmpty
          ? AppDataTableStatus.empty
          : AppDataTableStatus.idle,
      rows: alerts,
      rowIdBuilder: (alert) => alert.id,
      emptyTitle: 'Nenhum alerta de ruptura ativo',
      emptyDescription: 'O estoque está saudável para os filtros atuais.',
      errorTitle: 'Não foi possível carregar os alertas de ruptura',
      errorMessage: 'Tente novamente em breve.',
      retryLabel: 'Tentar novamente',
      onRetry: () {},
      mobileCardTitleBuilder: (context, alert) =>
          Text(_levelLabel(alert.level)),
      columns: <AppDataColumn<StockAlert>>[
        AppDataColumn(
          label: 'Severidade',
          cellBuilder: (context, alert) => AppStatusBadge(
            label: _levelLabel(alert.level),
            variant: alert.level == StockAlertLevel.critical
                ? AppStatusBadgeVariant.error
                : AppStatusBadgeVariant.warning,
          ),
        ),
        AppDataColumn(
          label: 'Transição',
          cellBuilder: (context, alert) =>
              Text(_transitionLabel(alert.transitionType)),
        ),
        AppDataColumn(
          label: 'Produto',
          cellBuilder: (context, alert) => Text(alert.productId),
        ),
        AppDataColumn(
          label: 'Depósito',
          cellBuilder: (context, alert) => Text(alert.warehouseId),
        ),
        AppDataColumn(
          label: 'Saldo/limite',
          numeric: true,
          cellBuilder: (context, alert) =>
              Text('${alert.sellableQuantity} / ${alert.thresholdQuantity}'),
        ),
      ],
      rowActions: <AppDataTableAction<StockAlert>>[
        AppDataTableAction<StockAlert>(
          icon: Icons.visibility_outlined,
          semanticLabel: 'Ver detalhe de estoque do produto',
          onPressed: (alert) => onDrillDownToProduct(alert.productId),
        ),
      ],
    );
  }

  String _levelLabel(StockAlertLevel level) {
    return switch (level) {
      StockAlertLevel.low => 'Baixo',
      StockAlertLevel.critical => 'Crítico',
    };
  }

  String _transitionLabel(StockAlertTransitionType type) {
    return switch (type) {
      StockAlertTransitionType.entered => 'Entrou no limite',
      StockAlertTransitionType.escalated => 'Agravou',
      StockAlertTransitionType.deescalated => 'Melhorou parcialmente',
      StockAlertTransitionType.recovered => 'Recuperado',
    };
  }
}

class _StalledProductsTable extends StatelessWidget {
  const _StalledProductsTable({
    required this.status,
    required this.rows,
    required this.hasMore,
    required this.failureMessage,
    required this.onRetry,
    required this.onLoadMore,
    required this.onDrillDownToProduct,
  });

  final InventoryDashboardStalledProductsStatus status;
  final List<InventoryDashboardStalledProductRow> rows;
  final bool hasMore;
  final String? failureMessage;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onDrillDownToProduct;

  @override
  Widget build(BuildContext context) {
    final stalledRows = rows.where((row) => row.isStalled).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDataTable<InventoryDashboardStalledProductRow>(
          status: switch (status) {
            InventoryDashboardStalledProductsStatus.loading =>
              AppDataTableStatus.loading,
            InventoryDashboardStalledProductsStatus.error =>
              AppDataTableStatus.error,
            InventoryDashboardStalledProductsStatus.ready =>
              stalledRows.isEmpty
                  ? AppDataTableStatus.empty
                  : AppDataTableStatus.idle,
          },
          rows: stalledRows,
          rowIdBuilder: (row) => row.productId,
          emptyTitle: 'Nenhum produto parado nesta página do catálogo',
          emptyDescription:
              'Ajuste os filtros, reduza o limiar de dias ou carregue mais '
              'produtos do catálogo.',
          errorTitle: 'Não foi possível carregar os produtos parados',
          errorMessage: failureMessage ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
          mobileCardTitleBuilder: (context, row) => Text(row.productName),
          columns: <AppDataColumn<InventoryDashboardStalledProductRow>>[
            AppDataColumn(
              label: 'Produto',
              cellBuilder: (context, row) => _buildProductCell(context, row),
            ),
            AppDataColumn(
              label: 'Cobertura',
              numeric: true,
              cellBuilder: (context, row) => Text(
                row.turnoverSnapshot == null
                    ? 'Sem dado'
                    : '${row.turnoverSnapshot!.stockCoverageDays.toStringAsFixed(0)} dias',
              ),
            ),
            AppDataColumn(
              label: 'Giro',
              numeric: true,
              cellBuilder: (context, row) => Text(
                row.turnoverSnapshot == null
                    ? 'Sem dado'
                    : row.turnoverSnapshot!.turnoverRate.toStringAsFixed(2),
              ),
            ),
            AppDataColumn(
              label: 'Categoria',
              cellBuilder: (context, row) => Text(row.categoryName ?? '—'),
            ),
          ],
          rowActions: <AppDataTableAction<InventoryDashboardStalledProductRow>>[
            AppDataTableAction<InventoryDashboardStalledProductRow>(
              icon: Icons.visibility_outlined,
              semanticLabel: 'Ver detalhe de estoque por variante',
              onPressed: (row) => onDrillDownToProduct(row.productId),
            ),
          ],
        ),
        if (status == InventoryDashboardStalledProductsStatus.ready &&
            hasMore) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing16),
          Center(
            child: AppButton(
              label: 'Carregar mais produtos do catálogo',
              semanticLabel:
                  'Carregar mais produtos do catálogo para avaliar cobertura',
              variant: AppButtonVariant.secondary,
              onPressed: onLoadMore,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductCell(
    BuildContext context,
    InventoryDashboardStalledProductRow row,
  ) {
    final colors = context.colors;
    final imageUrl = row.imageUrl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: AppSpacing.spacing40,
          height: AppSpacing.spacing40,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            child: (imageUrl == null || imageUrl.isEmpty)
                ? Container(
                    color: colors.surfaceContainer,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: AppIconSizes.md,
                      color: colors.outline,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const AppSkeleton(shape: AppSkeletonShape.block),
                    errorWidget: (context, url, error) => Container(
                      color: colors.surfaceContainer,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: AppIconSizes.md,
                        color: colors.outline,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing8),
        Flexible(
          child: Text(
            row.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
