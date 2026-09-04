import '../../../../core/errors/errors.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/entities/product_dashboard_filters.dart';
import '../../domain/entities/product_dashboard_ranking_row.dart';
import '../../domain/entities/product_dashboard_snapshot.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;

enum ProductDashboardStatus { initial, loading, forbidden, error, ready }

enum ProductDashboardRankingStatus { loading, ready, error }

final class ProductDashboardState {
  const ProductDashboardState({
    this.status = ProductDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.visibilityFilter,
    this.filters = const ProductDashboardFilters(
      companyId: '',
      year: 2024,
      month: 1,
    ),
    this.companyOptions = const <ExecutiveDashboardScopeOption>[],
    this.collectionOptions = const <ExecutiveDashboardScopeOption>[],
    this.categoryOptions = const <ExecutiveDashboardScopeOption>[],
    this.snapshot,
    this.rankingStatus = ProductDashboardRankingStatus.loading,
    this.rankingRows = const <ProductDashboardRankingRow>[],
    this.rankingFailure,
    this.visibleRankingCount = pageSize,
    this.turnoverByProductId = const <String, StockTurnoverMetricSnapshot?>{},
    this.imageUrlByProductId = const <String, String?>{},
    this.failure,
  });

  /// How many ranking rows one "page" reveals — also the initial visible
  /// count and the increment `ProductDashboardRankingPageRequested` grows it
  /// by, same bound `CustomerDashboardState.pageSize` already sets.
  static const int pageSize = 20;

  final ProductDashboardStatus status;
  final String organizationId;
  final String userId;

  /// Reuses `ExecutiveDashboardVisibilityFilter` verbatim — same RBAC
  /// scoping semantics every EPIC-17 dashboard already shares.
  final ExecutiveDashboardVisibilityFilter? visibilityFilter;
  final ProductDashboardFilters filters;
  final List<ExecutiveDashboardScopeOption> companyOptions;
  final List<ExecutiveDashboardScopeOption> collectionOptions;
  final List<ExecutiveDashboardScopeOption> categoryOptions;
  final ProductDashboardSnapshot? snapshot;

  /// Loaded independently from [snapshot] failures: a failed ranking read
  /// never blocks... in this dashboard [snapshot] is itself derived from
  /// [rankingRows], so the two statuses always move together — kept as two
  /// fields anyway (not folded into one) only to mirror the same
  /// "carregando"/"erro" shape every other EPIC-17 dashboard's ranking table
  /// already exposes to its own presentation layer.
  final ProductDashboardRankingStatus rankingStatus;

  /// Every row fetched for the current filters, already sorted/filtered —
  /// the bounded, in-memory list [visibleRankingRows] windows over for
  /// pagination.
  final List<ProductDashboardRankingRow> rankingRows;
  final Failure? rankingFailure;

  /// How many of [rankingRows], from the start, are currently "visible" —
  /// grown by `ProductDashboardRankingPageRequested`, reset to [pageSize] on
  /// any new fetch.
  final int visibleRankingCount;

  /// TASK-094 giro de estoque por produto (mesma fonte, `product`-scoped,
  /// de `GetStockTurnoverMetricsUseCase` — ver `ProductDashboardBloc`'s own
  /// docs para a nota de consistência com a regra de insight TASK-128),
  /// carregado apenas para as linhas atualmente visíveis
  /// ([visibleRankingRows]) — nunca para as 500 linhas do read bruto.
  /// Ausência de entrada = ainda não carregado; entrada com valor `null` =
  /// carregado, sem dado disponível para aquele produto/período.
  final Map<String, StockTurnoverMetricSnapshot?> turnoverByProductId;

  /// `Product.principalPhoto` (thumbnail/url), carregado em lote via
  /// `ProductRepository.getByIds` apenas para as linhas atualmente visíveis
  /// — mesma justificativa de escopo de [turnoverByProductId].
  final Map<String, String?> imageUrlByProductId;

  final Failure? failure;

  /// The current page of the ranking table — a prefix of [rankingRows], so
  /// growing [visibleRankingCount] always preserves every row already
  /// rendered.
  List<ProductDashboardRankingRow> get visibleRankingRows {
    if (visibleRankingCount >= rankingRows.length) return rankingRows;
    return rankingRows.sublist(0, visibleRankingCount);
  }

  bool get hasMoreRankingRows => visibleRankingCount < rankingRows.length;

  /// Whether the caller may pick a company other than their own — mirrors
  /// `CustomerDashboardState.canPickScope`/`SalesDashboardState
  /// .canPickScope`.
  bool get canPickScope =>
      visibilityFilter?.mode ==
          ExecutiveDashboardVisibilityMode.allOrganization ||
      companyOptions.length > 1;

  ProductDashboardState copyWith({
    ProductDashboardStatus? status,
    String? organizationId,
    String? userId,
    ExecutiveDashboardVisibilityFilter? visibilityFilter,
    ProductDashboardFilters? filters,
    List<ExecutiveDashboardScopeOption>? companyOptions,
    List<ExecutiveDashboardScopeOption>? collectionOptions,
    List<ExecutiveDashboardScopeOption>? categoryOptions,
    ProductDashboardSnapshot? snapshot,
    ProductDashboardRankingStatus? rankingStatus,
    List<ProductDashboardRankingRow>? rankingRows,
    Failure? rankingFailure,
    bool clearRankingFailure = false,
    int? visibleRankingCount,
    Map<String, StockTurnoverMetricSnapshot?>? turnoverByProductId,
    Map<String, String?>? imageUrlByProductId,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProductDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      visibilityFilter: visibilityFilter ?? this.visibilityFilter,
      filters: filters ?? this.filters,
      companyOptions: companyOptions ?? this.companyOptions,
      collectionOptions: collectionOptions ?? this.collectionOptions,
      categoryOptions: categoryOptions ?? this.categoryOptions,
      snapshot: snapshot ?? this.snapshot,
      rankingStatus: rankingStatus ?? this.rankingStatus,
      rankingRows: rankingRows ?? this.rankingRows,
      rankingFailure: clearRankingFailure
          ? null
          : (rankingFailure ?? this.rankingFailure),
      visibleRankingCount: visibleRankingCount ?? this.visibleRankingCount,
      turnoverByProductId: turnoverByProductId ?? this.turnoverByProductId,
      imageUrlByProductId: imageUrlByProductId ?? this.imageUrlByProductId,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
