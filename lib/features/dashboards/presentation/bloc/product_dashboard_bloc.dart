import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_scope.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import '../../../inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart';
import '../../../inventory/domain/value_objects/stock_turnover_scope_type.dart';
import '../../../organizations/domain/entities/company.dart';
import '../../../organizations/domain/repositories/company_repository.dart';
import '../../../products/domain/entities/category.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/category_repository.dart';
import '../../../products/domain/repositories/collection_repository.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/entities/executive_dashboard_visibility_filter.dart';
import '../../domain/entities/product_dashboard_filters.dart';
import '../../domain/services/executive_dashboard_visibility_service.dart';
import '../../domain/usecases/build_product_dashboard_snapshot_use_case.dart';
import '../../domain/usecases/load_product_dashboard_ranking_use_case.dart';
import 'executive_dashboard_state.dart' show ExecutiveDashboardScopeOption;
import 'product_dashboard_event.dart';
import 'product_dashboard_state.dart';

/// Drives the Product Dashboard (TASK-137, EPIC-17): resolves which
/// companies the caller may pick as scope, then loads the ranking table
/// exclusively from [LoadProductDashboardRankingUseCase] (TASK-133's
/// `productMonthly` aggregation, price-list-restricted) and derives the KPI
/// snapshot from those same rows via [BuildProductDashboardSnapshotUseCase]
/// — never a raw query against `orders`/`products`.
///
/// **Giro de estoque (TASK-094), mesma fonte da regra de insight
/// TASK-128 — com uma lacuna pré-existente documentada.** Este bloc
/// enriquece cada linha visível do ranking chamando
/// [GetStockTurnoverMetricsUseCase] com [StockTurnoverScopeType.product] —
/// o único ponto de leitura de giro por produto que hoje existe e está
/// realmente conectado a um repositório no código-fonte (`StockTurnoverRepository`).
/// A regra `HighStockLowTurnoverInsightRule` (TASK-128) lê, em vez disso,
/// `InsightStockPositionSnapshot.turnoverIndex` de um `InsightDataset` cujo
/// builder de produção — o código que popularia esse dataset a partir de
/// `StockTurnoverRepository` — ainda não existe em lugar nenhum do
/// código-fonte (lacuna pré-existente, fora do escopo desta task). Por isso
/// os dois leitores não podem ser comparados em runtime hoje; este bloc
/// documenta explicitamente que lê a mesma (e única) fonte canônica da
/// TASK-094 que a regra de insight está desenhada para eventualmente usar,
/// para que os dois nunca precisem divergir quando aquele builder for
/// implementado. Ver
/// `docs/tasks/TASK-137-implementar-dashboard-de-produtos-CONCLUIDA.md`.
///
/// **"Produtos com maior conversão", lacuna documentada.** Nenhum pipeline
/// de eventos/agregação neste código-fonte rastreia visualizações de
/// produto nem adições ao pedido por período —
/// `ProductDashboardRankingRow.conversionRate` fica sempre `null`, nunca
/// calculado ad-hoc a partir de um proxy (este task's own "Regras de
/// negócio e restrições"). O ranking "mais vendidos" (por quantidade,
/// faturamento, mix ou desconto) é o único ranking funcional hoje.
@injectable
final class ProductDashboardBloc
    extends Bloc<ProductDashboardEvent, ProductDashboardState> {
  ProductDashboardBloc(
    this._visibilityService,
    this._loadRanking,
    this._buildSnapshot,
    this._companyRepository,
    this._collectionRepository,
    this._categoryRepository,
    this._getStockTurnoverMetrics,
    this._productRepository,
    this._analyticsService,
  ) : super(const ProductDashboardState()) {
    on<ProductDashboardStarted>(_onStarted);
    on<ProductDashboardFiltersChanged>(_onFiltersChanged);
    on<ProductDashboardRetried>(_onRetried);
    on<ProductDashboardRankingRetried>(_onRankingRetried);
    on<ProductDashboardRankingPageRequested>(_onRankingPageRequested);
  }

  final ExecutiveDashboardVisibilityService _visibilityService;
  final LoadProductDashboardRankingUseCase _loadRanking;
  final BuildProductDashboardSnapshotUseCase _buildSnapshot;
  final CompanyRepository _companyRepository;
  final CollectionRepository _collectionRepository;
  final CategoryRepository _categoryRepository;
  final GetStockTurnoverMetricsUseCase _getStockTurnoverMetrics;
  final ProductRepository _productRepository;
  final AnalyticsService _analyticsService;

  Future<void> _onStarted(
    ProductDashboardStarted event,
    Emitter<ProductDashboardState> emit,
  ) async {
    emit(
      ProductDashboardState(
        status: ProductDashboardStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        filters: event.initialFilters,
      ),
    );

    final visibilityResult = await _visibilityService.resolve(
      organizationId: event.organizationId,
      userId: event.userId,
    );
    if (visibilityResult case AppFailure<ExecutiveDashboardVisibilityFilter>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(status: ProductDashboardStatus.error, failure: failure),
      );
      return;
    }
    final visibility =
        (visibilityResult as AppSuccess<ExecutiveDashboardVisibilityFilter>)
            .value;
    emit(state.copyWith(visibilityFilter: visibility));

    if (!visibility.canViewAny) {
      emit(state.copyWith(status: ProductDashboardStatus.forbidden));
      return;
    }

    final companiesResult = await _companyRepository.listByOrganization(
      event.organizationId,
    );
    if (companiesResult case AppFailure<List<Company>>(
      failure: final failure,
    )) {
      emit(
        state.copyWith(status: ProductDashboardStatus.error, failure: failure),
      );
      return;
    }
    final companies = (companiesResult as AppSuccess<List<Company>>).value
        .where(
          (company) =>
              company.deletedAt == null &&
              visibility.canViewCompany(company.id),
        )
        .toList(growable: false);

    final companyOptions = <ExecutiveDashboardScopeOption>[
      for (final company in companies)
        ExecutiveDashboardScopeOption(id: company.id, name: company.name),
    ];

    final collectionsResult = await _collectionRepository.listByOrganization(
      event.organizationId,
    );
    final collectionOptions = switch (collectionsResult) {
      AppSuccess<List<Collection>>(value: final collections) =>
        <ExecutiveDashboardScopeOption>[
          for (final collection in collections)
            if (collection.deletedAt == null)
              ExecutiveDashboardScopeOption(
                id: collection.id,
                name: collection.name,
              ),
        ],
      AppFailure<List<Collection>>() => const <ExecutiveDashboardScopeOption>[],
    };

    final categoriesResult = await _categoryRepository.listByOrganization(
      event.organizationId,
    );
    final categoryOptions = switch (categoriesResult) {
      AppSuccess<List<Category>>(value: final categories) =>
        <ExecutiveDashboardScopeOption>[
          for (final category in categories)
            if (category.deletedAt == null)
              ExecutiveDashboardScopeOption(
                id: category.id,
                name: category.name,
              ),
        ],
      AppFailure<List<Category>>() => const <ExecutiveDashboardScopeOption>[],
    };

    var effectiveFilters = event.initialFilters;
    if (companies.isNotEmpty &&
        !companies.any((company) => company.id == effectiveFilters.companyId)) {
      effectiveFilters = effectiveFilters.copyWith(
        companyId: companies.first.id,
      );
    }

    emit(
      state.copyWith(
        companyOptions: companyOptions,
        collectionOptions: collectionOptions,
        categoryOptions: categoryOptions,
        filters: effectiveFilters,
      ),
    );

    await _load(effectiveFilters, emit);
  }

  Future<void> _onFiltersChanged(
    ProductDashboardFiltersChanged event,
    Emitter<ProductDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null || !visibility.canViewAny) return;
    if (!visibility.canViewCompany(event.filters.companyId)) return;

    emit(
      state.copyWith(
        status: ProductDashboardStatus.loading,
        filters: event.filters,
      ),
    );
    await _load(event.filters, emit);
  }

  Future<void> _onRetried(
    ProductDashboardRetried event,
    Emitter<ProductDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(
        status: ProductDashboardStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(state.filters, emit);
  }

  Future<void> _onRankingRetried(
    ProductDashboardRankingRetried event,
    Emitter<ProductDashboardState> emit,
  ) async {
    final visibility = state.visibilityFilter;
    if (visibility == null) return;
    emit(
      state.copyWith(
        rankingStatus: ProductDashboardRankingStatus.loading,
        clearRankingFailure: true,
      ),
    );
    await _loadRankingInto(state.filters, emit);
  }

  Future<void> _onRankingPageRequested(
    ProductDashboardRankingPageRequested event,
    Emitter<ProductDashboardState> emit,
  ) async {
    if (!state.hasMoreRankingRows) return;
    final nextCount =
        state.visibleRankingCount + ProductDashboardState.pageSize;
    emit(
      state.copyWith(
        visibleRankingCount: nextCount > state.rankingRows.length
            ? state.rankingRows.length
            : nextCount,
      ),
    );
    await _enrichVisibleRows(emit);
  }

  Future<void> _load(
    ProductDashboardFilters filters,
    Emitter<ProductDashboardState> emit,
  ) async {
    await _loadRankingInto(filters, emit);

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.dashboardViewed,
        parameters: <String, Object?>{
          'organization_id': state.organizationId,
          'dashboard_type': 'product',
          'company_id': filters.companyId,
          'month': filters.monthKey,
          'collection_id': filters.collectionId,
          'category_id': filters.categoryId,
        },
      ),
    );
  }

  Future<void> _loadRankingInto(
    ProductDashboardFilters filters,
    Emitter<ProductDashboardState> emit,
  ) async {
    final result = await _loadRanking(
      organizationId: state.organizationId,
      filters: filters,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(
            status: ProductDashboardStatus.error,
            rankingStatus: ProductDashboardRankingStatus.error,
            rankingFailure: failure,
          ),
        );
        return;
      case AppSuccess(value: final rows):
        emit(
          state.copyWith(
            status: ProductDashboardStatus.ready,
            rankingStatus: ProductDashboardRankingStatus.ready,
            rankingRows: rows,
            snapshot: _buildSnapshot(rows),
            visibleRankingCount: ProductDashboardState.pageSize,
            turnoverByProductId: const <String, StockTurnoverMetricSnapshot?>{},
            imageUrlByProductId: const <String, String?>{},
            clearFailure: true,
            clearRankingFailure: true,
          ),
        );
    }

    await _enrichVisibleRows(emit);
  }

  /// Loads giro de estoque (TASK-094) and imagem de produto only for
  /// [ProductDashboardState.visibleRankingRows] not already present in
  /// [ProductDashboardState.turnoverByProductId]/`.imageUrlByProductId` — a
  /// bounded enrichment triggered by an explicit user action (initial page
  /// load or "carregar mais"), never a fan-out over the whole ranking (this
  /// task's own "nunca centenas de queries do cliente" rule).
  Future<void> _enrichVisibleRows(Emitter<ProductDashboardState> emit) async {
    final visibleRows = state.visibleRankingRows;
    final pendingRows = visibleRows
        .where((row) => !state.turnoverByProductId.containsKey(row.productId))
        .toList(growable: false);
    if (pendingRows.isEmpty) return;

    final periodStart = state.filters.periodStart;
    final periodEnd = state.filters.periodEnd;

    final turnoverResults = await Future.wait(
      pendingRows.map(
        (row) => _getStockTurnoverMetrics(
          organizationId: state.organizationId,
          scope: StockTurnoverMetricScope(
            type: StockTurnoverScopeType.product,
            id: row.productId,
          ),
          periodStart: periodStart,
          periodEnd: periodEnd,
        ),
      ),
    );
    if (emit.isDone) return;

    final nextTurnoverByProductId =
        Map<String, StockTurnoverMetricSnapshot?>.of(state.turnoverByProductId);
    for (var i = 0; i < pendingRows.length; i++) {
      final result = turnoverResults[i];
      nextTurnoverByProductId[pendingRows[i].productId] = switch (result) {
        AppSuccess<StockTurnoverMetricSnapshot?>(value: final value) => value,
        AppFailure<StockTurnoverMetricSnapshot?>() => null,
      };
    }

    final productsResult = await _productRepository.getByIds(
      organizationId: state.organizationId,
      ids: pendingRows.map((row) => row.productId).toList(growable: false),
    );
    if (emit.isDone) return;

    final nextImageUrlByProductId = Map<String, String?>.of(
      state.imageUrlByProductId,
    );
    if (productsResult case AppSuccess<List<Product>>(value: final products)) {
      for (final product in products) {
        final photo = product.principalPhoto;
        nextImageUrlByProductId[product.id] = photo?.thumbnailUrl ?? photo?.url;
      }
    }
    for (final row in pendingRows) {
      nextImageUrlByProductId.putIfAbsent(row.productId, () => null);
    }

    emit(
      state.copyWith(
        turnoverByProductId: nextTurnoverByProductId,
        imageUrlByProductId: nextImageUrlByProductId,
      ),
    );
  }
}
