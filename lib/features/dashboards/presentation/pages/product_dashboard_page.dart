import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import '../../domain/entities/executive_dashboard_metric.dart';
import '../../domain/entities/product_dashboard_filters.dart';
import '../../domain/entities/product_dashboard_ranking_row.dart';
import '../../domain/entities/product_dashboard_snapshot.dart';
import '../../domain/value_objects/product_dashboard_sort_field.dart';
import '../bloc/product_dashboard_bloc.dart';
import '../bloc/product_dashboard_event.dart';
import '../bloc/product_dashboard_state.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);
final DateFormat _monthLabelFormat = DateFormat('MMMM/yyyy', 'pt_BR');

const String _noOptionValue = '';

/// Product Dashboard (TASK-137, EPIC-17): "análise de mix, giro e
/// desempenho por produto, coleção, cor, tamanho e categoria" — quantidade
/// vendida, amplitude de mix comercializado, desconto médio e margem, mais
/// um ranking de produtos por quantidade/faturamento/mix/desconto, cruzado
/// com giro de estoque (TASK-094) e com drill-down até o detalhe visual do
/// produto (TASK-078).
///
/// Reads exclusively from [ProductDashboardBloc] (`AggregationRepository`,
/// TASK-133 — never uma consulta bruta a `orders`/`products`). Gated behind
/// [Capability.reportViewSensitive] — mesma capability que
/// [SalesDashboardPage]/[CustomerDashboardPage] já exigem.
///
/// **Lacunas documentadas** (ver `ProductDashboardBloc`'s own docs e
/// `docs/tasks/TASK-137-implementar-dashboard-de-produtos-CONCLUIDA.md`):
/// filtro por cor/tamanho e ranking por "maior conversão" não estão
/// disponíveis hoje — nenhuma dimensão de agregação/rastreamento existente
/// no código-fonte sustenta esses dois recursos sem fabricar dado no
/// cliente.
class ProductDashboardPage extends StatelessWidget {
  const ProductDashboardPage({
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
  final ProductDashboardBloc Function() createBloc;
  final ProductDashboardFilters initialFilters;

  /// Called when the caller drills down from a ranking row into the
  /// product's own detail (TASK-078) — the composition root
  /// (`bootstrap.dart`) decides the actual navigation, same "this page never
  /// hard-codes another feature's route" contract
  /// `CustomerDashboardPage.onDrillDownToCustomer` already sets.
  final ValueChanged<String> onDrillDownToProduct;

  /// Called whenever [ProductDashboardFilters] change, so the host can
  /// mirror them into the URL (Flutter Web deep link) — same contract
  /// `CustomerDashboardPage.onUrlStateChanged` already sets.
  final void Function(ProductDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ProductDashboardBloc>(
          create: (_) => createBloc()
            ..add(
              ProductDashboardStarted(
                organizationId: organizationId,
                userId: userId,
                initialFilters: initialFilters,
              ),
            ),
          child: _ProductDashboardView(
            onDrillDownToProduct: onDrillDownToProduct,
            onUrlStateChanged: onUrlStateChanged,
          ),
        );
      },
    );
  }
}

class _ProductDashboardView extends StatelessWidget {
  const _ProductDashboardView({
    required this.onDrillDownToProduct,
    this.onUrlStateChanged,
  });

  final ValueChanged<String> onDrillDownToProduct;
  final void Function(ProductDashboardFilters filters)? onUrlStateChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDashboardBloc, ProductDashboardState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) => onUrlStateChanged?.call(state.filters),
      builder: (context, state) {
        final bloc = context.read<ProductDashboardBloc>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Dashboard de produtos',
            filtersTitle: 'Filtros do dashboard de produtos',
            filtersBuilder: (_) => _ProductDashboardFiltersForm(
              state: state,
              onChanged: (filters) =>
                  bloc.add(ProductDashboardFiltersChanged(filters)),
            ),
            content: _ProductDashboardContent(
              state: state,
              onRetry: () => bloc.add(const ProductDashboardRetried()),
              onRankingRetry: () =>
                  bloc.add(const ProductDashboardRankingRetried()),
              onSortChanged: (field, descending) => bloc.add(
                ProductDashboardFiltersChanged(
                  state.filters.copyWith(
                    sortField: field,
                    sortDescending: descending,
                  ),
                ),
              ),
              onLoadMoreRanking: () =>
                  bloc.add(const ProductDashboardRankingPageRequested()),
              onDrillDownToProduct: onDrillDownToProduct,
            ),
          ),
        );
      },
    );
  }
}

class _ProductDashboardFiltersForm extends StatelessWidget {
  const _ProductDashboardFiltersForm({
    required this.state,
    required this.onChanged,
  });

  final ProductDashboardState state;
  final ValueChanged<ProductDashboardFilters> onChanged;

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
          const SizedBox(height: AppSpacing.spacing8),
        ],
        Text(
          'Filtro por cor e tamanho ainda não está disponível: a camada de '
          'agregação de vendas (TASK-133) registra dados por produto, sem '
          'dimensão de variante.',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
      ],
    );
  }

  String _monthLabel(ProductDashboardFilters filters) {
    final label = _monthLabelFormat.format(
      DateTime.utc(filters.year, filters.month),
    );
    return label[0].toUpperCase() + label.substring(1);
  }
}

class _ProductDashboardContent extends StatelessWidget {
  const _ProductDashboardContent({
    required this.state,
    required this.onRetry,
    required this.onRankingRetry,
    required this.onSortChanged,
    required this.onLoadMoreRanking,
    required this.onDrillDownToProduct,
  });

  final ProductDashboardState state;
  final VoidCallback onRetry;
  final VoidCallback onRankingRetry;
  final void Function(ProductDashboardSortField field, bool descending)
  onSortChanged;
  final VoidCallback onLoadMoreRanking;
  final ValueChanged<String> onDrillDownToProduct;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ProductDashboardStatus.initial:
      case ProductDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ProductDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso ao dashboard de produtos',
          description:
              'Você não tem permissão para ver esta análise de produtos. '
              'Fale com um administrador caso acredite que isso é um '
              'engano.',
        );
      case ProductDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar o dashboard de produtos',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
        );
      case ProductDashboardStatus.ready:
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _ProductDashboardBody(
          state: state,
          snapshot: snapshot,
          onRankingRetry: onRankingRetry,
          onSortChanged: onSortChanged,
          onLoadMoreRanking: onLoadMoreRanking,
          onDrillDownToProduct: onDrillDownToProduct,
        );
    }
  }
}

class _ProductDashboardBody extends StatelessWidget {
  const _ProductDashboardBody({
    required this.state,
    required this.snapshot,
    required this.onRankingRetry,
    required this.onSortChanged,
    required this.onLoadMoreRanking,
    required this.onDrillDownToProduct,
  });

  final ProductDashboardState state;
  final ProductDashboardSnapshot snapshot;
  final VoidCallback onRankingRetry;
  final void Function(ProductDashboardSortField field, bool descending)
  onSortChanged;
  final VoidCallback onLoadMoreRanking;
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
            '(${filters.companyId}).',
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
            'Ranking de produtos mais vendidos',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            'Ranking por "maior conversão" ainda não está disponível: nenhum '
            'rastreamento de visualizações/adições ao pedido por período '
            'existe hoje para calculá-lo sem fabricar o dado no cliente.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          _ProductDashboardRankingTable(
            filters: filters,
            status: state.rankingStatus,
            rows: state.visibleRankingRows,
            hasMore: state.hasMoreRankingRows,
            failureMessage: state.rankingFailure?.message,
            turnoverByProductId: state.turnoverByProductId,
            imageUrlByProductId: state.imageUrlByProductId,
            onRetry: onRankingRetry,
            onSortChanged: onSortChanged,
            onLoadMore: onLoadMoreRanking,
            onDrillDownToProduct: onDrillDownToProduct,
          ),
        ],
      ),
    );
  }

  List<Widget> _kpiCards() {
    return <Widget>[
      _metricCard(
        label: 'Quantidade vendida',
        metric: snapshot.quantitySold,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.inventory_2_outlined,
      ),
      _metricCard(
        label: 'Produtos ativos no mix',
        metric: snapshot.activeProductCount,
        format: (value) => value.toStringAsFixed(0),
        icon: Icons.grid_view_outlined,
      ),
      _metricCard(
        label: 'Desconto médio',
        metric: snapshot.averageDiscountPercentage,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.percent_outlined,
      ),
      _metricCard(
        label: 'Margem',
        metric: snapshot.margin,
        format: (value) => '${value.toStringAsFixed(1)}%',
        icon: Icons.trending_up,
        notCalculatedLabel: 'Sem dado de custo/margem disponível',
      ),
    ];
  }

  Widget _metricCard({
    required String label,
    required ExecutiveDashboardMetric metric,
    required String Function(double) format,
    required IconData icon,
    String notCalculatedLabel = 'Cálculo ainda não disponível',
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

class _ProductDashboardRankingTable extends StatelessWidget {
  const _ProductDashboardRankingTable({
    required this.filters,
    required this.status,
    required this.rows,
    required this.hasMore,
    required this.failureMessage,
    required this.turnoverByProductId,
    required this.imageUrlByProductId,
    required this.onRetry,
    required this.onSortChanged,
    required this.onLoadMore,
    required this.onDrillDownToProduct,
  });

  final ProductDashboardFilters filters;
  final ProductDashboardRankingStatus status;
  final List<ProductDashboardRankingRow> rows;
  final bool hasMore;
  final String? failureMessage;
  final Map<String, StockTurnoverMetricSnapshot?> turnoverByProductId;
  final Map<String, String?> imageUrlByProductId;
  final VoidCallback onRetry;
  final void Function(ProductDashboardSortField field, bool descending)
  onSortChanged;
  final VoidCallback onLoadMore;
  final ValueChanged<String> onDrillDownToProduct;

  int get _sortColumnIndex => switch (filters.sortField) {
    ProductDashboardSortField.quantitySold => 1,
    ProductDashboardSortField.revenue => 2,
    ProductDashboardSortField.mix => 3,
    ProductDashboardSortField.discount => 4,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDataTable<ProductDashboardRankingRow>(
          status: switch (status) {
            ProductDashboardRankingStatus.loading => AppDataTableStatus.loading,
            ProductDashboardRankingStatus.error => AppDataTableStatus.error,
            ProductDashboardRankingStatus.ready =>
              rows.isEmpty ? AppDataTableStatus.empty : AppDataTableStatus.idle,
          },
          rows: rows,
          rowIdBuilder: (row) => row.productId,
          emptyTitle: 'Nenhum produto vendido neste período',
          emptyDescription:
              'Ajuste os filtros ou aguarde novos pedidos serem processados.',
          errorTitle: 'Não foi possível carregar o ranking de produtos',
          errorMessage: failureMessage ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: onRetry,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: !filters.sortDescending,
          onSort: (columnIndex, ascending) {
            final field = switch (columnIndex) {
              2 => ProductDashboardSortField.revenue,
              3 => ProductDashboardSortField.mix,
              4 => ProductDashboardSortField.discount,
              _ => ProductDashboardSortField.quantitySold,
            };
            onSortChanged(field, !ascending);
          },
          mobileCardTitleBuilder: (context, row) => Text(row.productName),
          columns: <AppDataColumn<ProductDashboardRankingRow>>[
            AppDataColumn(
              label: 'Produto',
              cellBuilder: (context, row) => _buildProductCell(
                context,
                row,
                imageUrlByProductId[row.productId],
              ),
            ),
            AppDataColumn(
              label: 'Qtd. vendida',
              numeric: true,
              sortable: true,
              cellBuilder: (context, row) => Text('${row.quantitySold}'),
            ),
            AppDataColumn(
              label: 'Faturamento',
              numeric: true,
              sortable: true,
              cellBuilder: (context, row) =>
                  Text(_currencyFormat.format(row.revenueNet)),
            ),
            AppDataColumn(
              label: 'Mix %',
              numeric: true,
              sortable: true,
              cellBuilder: (context, row) =>
                  Text('${row.mixPercentage.toStringAsFixed(1)}%'),
            ),
            AppDataColumn(
              label: 'Desconto %',
              numeric: true,
              sortable: true,
              cellBuilder: (context, row) =>
                  Text('${row.discountPercentage.toStringAsFixed(1)}%'),
            ),
            AppDataColumn(
              label: 'Giro',
              numeric: true,
              cellBuilder: (context, row) => _buildTurnoverCell(
                context,
                turnoverByProductId[row.productId],
              ),
            ),
            AppDataColumn(
              label: 'Categoria',
              cellBuilder: (context, row) => Text(row.categoryName ?? '—'),
            ),
          ],
          rowActions: <AppDataTableAction<ProductDashboardRankingRow>>[
            AppDataTableAction<ProductDashboardRankingRow>(
              icon: Icons.visibility_outlined,
              semanticLabel: 'Ver detalhe do produto',
              onPressed: (row) => onDrillDownToProduct(row.productId),
            ),
          ],
        ),
        if (status == ProductDashboardRankingStatus.ready &&
            hasMore) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing16),
          Center(
            child: AppButton(
              label: 'Carregar mais produtos',
              semanticLabel: 'Carregar mais produtos no ranking',
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
    ProductDashboardRankingRow row,
    String? imageUrl,
  ) {
    final colors = context.colors;
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

  Widget _buildTurnoverCell(
    BuildContext context,
    StockTurnoverMetricSnapshot? turnoverSnapshot,
  ) {
    if (turnoverSnapshot == null) {
      return Text(
        'Sem dado',
        style: AppTypography.bodySmall.copyWith(color: context.colors.outline),
      );
    }
    return Text(turnoverSnapshot.turnoverRate.toStringAsFixed(2));
  }
}
