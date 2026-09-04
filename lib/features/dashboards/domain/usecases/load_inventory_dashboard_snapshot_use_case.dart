import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../inventory/domain/entities/stock_alert_page.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_scope.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import '../../../inventory/domain/entities/warehouse.dart';
import '../../../inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart';
import '../../../inventory/domain/usecases/list_stock_alerts_use_case.dart';
import '../../../inventory/domain/value_objects/stock_coverage_status.dart';
import '../../../inventory/domain/value_objects/stock_turnover_scope_type.dart';
import '../entities/executive_dashboard_metric.dart';
import '../entities/inventory_dashboard_filters.dart';
import '../entities/inventory_dashboard_snapshot.dart';

/// Builds the Inventory Dashboard's KPI cards + alertas de ruptura
/// consolidados (TASK-139, seção 12.1 de `tasks.md`) for one
/// [InventoryDashboardFilters] scope/period.
///
/// **Cobertura/sell-through/giro sempre vêm de [GetStockTurnoverMetricsUseCase]
/// (TASK-094) — a mesma (e única) fonte canônica que `ProductDashboardBloc`
/// (TASK-137) e `LoadCollectionDashboardEntriesUseCase` (TASK-138) já leem, e
/// a mesma que `HighStockLowTurnoverInsightRule`/
/// `ReplenishmentSuggestionInsightRule` (TASK-128) foram desenhadas para
/// eventualmente consumir.** A regra de insight lê, na prática, um
/// `InsightStockPositionSnapshot` vindo de um `InsightDataset` cujo builder
/// de produção ainda não existe em lugar nenhum do código-fonte (lacuna
/// pré-existente, já documentada em `ProductDashboardBloc`'s own docs e em
/// `docs/tasks/TASK-137-implementar-dashboard-de-produtos-CONCLUIDA.md`) —
/// os dois leitores não podem ser comparados em runtime hoje por essa razão,
/// não por uma divergência introduzida por esta task. Este use case garante
/// que, quando aquele builder existir, os dois nunca precisarão divergir,
/// por lerem exatamente a mesma tabela `stockTurnoverMetrics`.
///
/// **Fan-out limitado a depósitos ativos.** Quando nem `warehouseId` nem
/// `collectionId` estão selecionados, o card agrega (média ponderada) sobre
/// todo depósito ativo passado em [activeWarehouses] — o mesmo "nunca
/// centenas de queries do cliente" bound que
/// `LoadCollectionDashboardEntriesUseCase` já aplica ao fan-out por coleção
/// (`tasks.md`, seção 22).
@injectable
final class LoadInventoryDashboardSnapshotUseCase {
  const LoadInventoryDashboardSnapshotUseCase(
    this._getStockTurnoverMetrics,
    this._listStockAlerts,
  );

  final GetStockTurnoverMetricsUseCase _getStockTurnoverMetrics;
  final ListStockAlertsUseCase _listStockAlerts;

  static const int _alertsPageLimit = 100;
  static const int _maxWarehousesFolded = 25;

  Future<AppResult<InventoryDashboardSnapshot>> call({
    required String organizationId,
    required String requestedByUserId,
    required InventoryDashboardFilters filters,
    required List<Warehouse> activeWarehouses,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedRequestedByUserId = requestedByUserId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedRequestedByUserId.isEmpty) {
      fieldErrors['requestedByUserId'] = 'RequestedByUserId is required.';
    }
    if (filters.companyId.trim().isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<InventoryDashboardSnapshot>(
        ValidationFailure(
          'Invalid inventory dashboard payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_inventory_dashboard_payload',
        ),
      );
    }

    final coverageResult = await _resolveCoverage(
      organizationId: trimmedOrganizationId,
      filters: filters,
      activeWarehouses: activeWarehouses,
    );
    if (coverageResult case AppFailure<_CoverageMetrics>(
      failure: final failure,
    )) {
      return AppFailure<InventoryDashboardSnapshot>(failure);
    }
    final coverage = (coverageResult as AppSuccess<_CoverageMetrics>).value;

    final alertsResult = await _listStockAlerts(
      organizationId: trimmedOrganizationId,
      requestedByUserId: trimmedRequestedByUserId,
      limit: _alertsPageLimit,
      warehouseId: filters.warehouseId,
    );
    if (alertsResult case AppFailure<StockAlertPage>(failure: final failure)) {
      return AppFailure<InventoryDashboardSnapshot>(failure);
    }
    final alertPage = (alertsResult as AppSuccess<StockAlertPage>).value;

    return AppSuccess<InventoryDashboardSnapshot>(
      InventoryDashboardSnapshot(
        coverageDays: coverage.coverageDays,
        sellThroughRate: coverage.sellThroughRate,
        turnoverRate: coverage.turnoverRate,
        warehousesConsidered: coverage.warehousesConsidered,
        alerts: alertPage.alerts,
        alertsHasMore: alertPage.hasMore,
        generatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<AppResult<_CoverageMetrics>> _resolveCoverage({
    required String organizationId,
    required InventoryDashboardFilters filters,
    required List<Warehouse> activeWarehouses,
  }) async {
    final warehouseId = filters.warehouseId?.trim();
    if (warehouseId != null && warehouseId.isNotEmpty) {
      return _readSingleScope(
        organizationId: organizationId,
        filters: filters,
        scope: StockTurnoverMetricScope(
          type: StockTurnoverScopeType.warehouse,
          id: warehouseId,
        ),
        warehousesConsidered: 1,
      );
    }

    final collectionId = filters.collectionId?.trim();
    if (collectionId != null && collectionId.isNotEmpty) {
      return _readSingleScope(
        organizationId: organizationId,
        filters: filters,
        scope: StockTurnoverMetricScope(
          type: StockTurnoverScopeType.collection,
          id: collectionId,
        ),
        warehousesConsidered: 0,
      );
    }

    return _foldActiveWarehouses(
      organizationId: organizationId,
      filters: filters,
      activeWarehouses: activeWarehouses,
    );
  }

  Future<AppResult<_CoverageMetrics>> _readSingleScope({
    required String organizationId,
    required InventoryDashboardFilters filters,
    required StockTurnoverMetricScope scope,
    required int warehousesConsidered,
  }) async {
    final result = await _getStockTurnoverMetrics(
      organizationId: organizationId,
      scope: scope,
      periodStart: filters.periodStart,
      periodEnd: filters.periodEnd,
    );
    return switch (result) {
      AppSuccess<StockTurnoverMetricSnapshot?>(value: final snapshot) =>
        AppSuccess<_CoverageMetrics>(
          _CoverageMetrics.fromSnapshot(
            snapshot,
            warehousesConsidered: warehousesConsidered,
          ),
        ),
      AppFailure<StockTurnoverMetricSnapshot?>(failure: final failure) =>
        AppFailure<_CoverageMetrics>(failure),
    };
  }

  Future<AppResult<_CoverageMetrics>> _foldActiveWarehouses({
    required String organizationId,
    required InventoryDashboardFilters filters,
    required List<Warehouse> activeWarehouses,
  }) async {
    final boundedWarehouses = activeWarehouses
        .take(_maxWarehousesFolded)
        .toList(growable: false);
    if (boundedWarehouses.isEmpty) {
      return AppSuccess<_CoverageMetrics>(
        _CoverageMetrics.fromSnapshot(null, warehousesConsidered: 0),
      );
    }

    final results = await Future.wait(
      boundedWarehouses.map(
        (warehouse) => _getStockTurnoverMetrics(
          organizationId: organizationId,
          scope: StockTurnoverMetricScope(
            type: StockTurnoverScopeType.warehouse,
            id: warehouse.id,
          ),
          periodStart: filters.periodStart,
          periodEnd: filters.periodEnd,
        ),
      ),
    );

    final snapshots = <StockTurnoverMetricSnapshot>[];
    for (final result in results) {
      switch (result) {
        case AppFailure<StockTurnoverMetricSnapshot?>(failure: final failure):
          return AppFailure<_CoverageMetrics>(failure);
        case AppSuccess<StockTurnoverMetricSnapshot?>(value: final snapshot):
          if (snapshot != null &&
              snapshot.coverageStatus == StockCoverageStatus.ready) {
            snapshots.add(snapshot);
          }
      }
    }

    if (snapshots.isEmpty) {
      return AppSuccess<_CoverageMetrics>(
        _CoverageMetrics.fromSnapshot(
          null,
          warehousesConsidered: boundedWarehouses.length,
        ),
      );
    }

    final coverageWeight = snapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.averageStockQuantity,
    );
    final salesWeight = snapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.soldQuantity,
    );

    final coverageDays = _weightedAverage(
      snapshots,
      (snapshot) => snapshot.stockCoverageDays,
      (snapshot) => snapshot.averageStockQuantity,
      totalWeight: coverageWeight,
    );
    final sellThroughRate = _weightedAverage(
      snapshots,
      (snapshot) => snapshot.sellThroughRate,
      (snapshot) => snapshot.soldQuantity.toDouble(),
      totalWeight: salesWeight,
    );
    final turnoverRate = _weightedAverage(
      snapshots,
      (snapshot) => snapshot.turnoverRate,
      (snapshot) => snapshot.soldQuantity.toDouble(),
      totalWeight: salesWeight,
    );

    return AppSuccess<_CoverageMetrics>(
      _CoverageMetrics(
        coverageDays: ExecutiveDashboardMetric.available(value: coverageDays),
        sellThroughRate: ExecutiveDashboardMetric.available(
          value: sellThroughRate * 100,
        ),
        turnoverRate: ExecutiveDashboardMetric.available(value: turnoverRate),
        warehousesConsidered: boundedWarehouses.length,
      ),
    );
  }

  /// Weighted mean of [selector] over [snapshots], weighted by [weight] —
  /// falls back to a simple arithmetic mean when every weight is zero (e.g.
  /// a brand-new período sem vendas ainda registradas), never a division by
  /// zero.
  double _weightedAverage(
    List<StockTurnoverMetricSnapshot> snapshots,
    double Function(StockTurnoverMetricSnapshot) selector,
    double Function(StockTurnoverMetricSnapshot) weight, {
    required double totalWeight,
  }) {
    if (totalWeight <= 0) {
      final sum = snapshots.fold<double>(
        0,
        (acc, snapshot) => acc + selector(snapshot),
      );
      return sum / snapshots.length;
    }
    final weightedSum = snapshots.fold<double>(
      0,
      (acc, snapshot) => acc + selector(snapshot) * weight(snapshot),
    );
    return weightedSum / totalWeight;
  }
}

final class _CoverageMetrics {
  const _CoverageMetrics({
    required this.coverageDays,
    required this.sellThroughRate,
    required this.turnoverRate,
    required this.warehousesConsidered,
  });

  factory _CoverageMetrics.fromSnapshot(
    StockTurnoverMetricSnapshot? snapshot, {
    required int warehousesConsidered,
  }) {
    if (snapshot == null ||
        snapshot.coverageStatus != StockCoverageStatus.ready) {
      return _CoverageMetrics(
        coverageDays: const ExecutiveDashboardMetric.notCalculated(),
        sellThroughRate: const ExecutiveDashboardMetric.notCalculated(),
        turnoverRate: const ExecutiveDashboardMetric.notCalculated(),
        warehousesConsidered: warehousesConsidered,
      );
    }
    return _CoverageMetrics(
      coverageDays: ExecutiveDashboardMetric.available(
        value: snapshot.stockCoverageDays,
      ),
      sellThroughRate: ExecutiveDashboardMetric.available(
        value: snapshot.sellThroughRate * 100,
      ),
      turnoverRate: ExecutiveDashboardMetric.available(
        value: snapshot.turnoverRate,
      ),
      warehousesConsidered: warehousesConsidered,
    );
  }

  final ExecutiveDashboardMetric coverageDays;
  final ExecutiveDashboardMetric sellThroughRate;
  final ExecutiveDashboardMetric turnoverRate;
  final int warehousesConsidered;
}
