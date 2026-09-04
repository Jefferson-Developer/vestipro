import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_scope.dart';
import '../../../inventory/domain/entities/stock_turnover_metric_snapshot.dart';
import '../../../inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart';
import '../../../inventory/domain/value_objects/stock_turnover_scope_type.dart';
import '../../../products/domain/entities/collection.dart';
import '../entities/aggregation_snapshot.dart';
import '../entities/collection_dashboard_category_mix.dart';
import '../entities/collection_dashboard_entry.dart';
import '../entities/executive_dashboard_metric.dart';
import '../repositories/aggregation_repository.dart';
import '../value_objects/aggregation_dimension.dart';

/// Builds the Collection Dashboard's comparison entries (TASK-138, seção
/// 12.1 de `tasks.md`: "performance por coleção/estação, com comparação
/// entre coleções"), one [CollectionDashboardEntry] per requested
/// [Collection], reading exclusively from TASK-133's [AggregationRepository]
/// (`productMonthly`, filtered by the row's denormalized `collectionId`
/// label) and TASK-094's [GetStockTurnoverMetricsUseCase]
/// (`StockTurnoverScopeType.collection`) — never a raw `orders`/`products`
/// scan.
///
/// **Cada coleção é lida sobre o seu próprio período, nunca um mês
/// compartilhado.** Unlike every other EPIC-17 dashboard (all filtered by a
/// single calendar month), this use case enumerates the calendar months
/// between `Collection.startDate` and `Collection.endDate` (TASK-066) —
/// clamped to "hoje" when `endDate` is `null`/in the future, since no
/// aggregation exists yet for a month that has not happened — and sums every
/// `productMonthly` row across those months whose `collectionId` label
/// matches. This is exactly this task's own "Comparação entre coleções de
/// estações diferentes deve deixar explícito o período de cada uma" rule:
/// [CollectionDashboardEntry.periodStart]/`.periodEnd` always carry the real
/// declared period, never a shared filter month.
///
/// **Sem `startDate`, sem leitura.** A [Collection] whose `startDate` is
/// `null` never triggers an aggregation/turnover read at all —
/// [CollectionDashboardEntry.undefinedPeriod] is returned instead, so the
/// comparison never silently treats an undefined period as "sem vendas"
/// (which would be indistinguishable from a real, published coleção that
/// genuinely sold nothing yet).
///
/// **Fan-out limitado.** At most [_maxMonthsPerCollection] months are read
/// per coleção (a season rarely spans more than a couple of years) — the
/// same "nunca centenas de queries do cliente" bound every other EPIC-17
/// read already enforces (`tasks.md`, seção 22).
@injectable
final class LoadCollectionDashboardEntriesUseCase {
  const LoadCollectionDashboardEntriesUseCase(
    this._aggregationRepository,
    this._getStockTurnoverMetrics,
  );

  final AggregationRepository _aggregationRepository;
  final GetStockTurnoverMetricsUseCase _getStockTurnoverMetrics;

  /// ~2 years of calendar months — comfortably covers a single fashion
  /// season/coleção while still bounding the fan-out of `listByPeriod`
  /// reads this use case issues per coleção.
  static const int _maxMonthsPerCollection = 24;

  static const int _rowLimit = 500;

  Future<AppResult<List<CollectionDashboardEntry>>> call({
    required String organizationId,
    required String companyId,
    required List<Collection> collections,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (collections.isEmpty) {
      fieldErrors['collections'] = 'At least one Collection is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<CollectionDashboardEntry>>(
        ValidationFailure(
          'Invalid collection dashboard payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_collection_dashboard_payload',
        ),
      );
    }

    final entries = <CollectionDashboardEntry>[];
    for (final collection in collections) {
      final entryResult = await _loadEntry(
        organizationId: trimmedOrganizationId,
        companyId: trimmedCompanyId,
        collection: collection,
      );
      if (entryResult case AppFailure<CollectionDashboardEntry>(
        failure: final failure,
      )) {
        return AppFailure<List<CollectionDashboardEntry>>(failure);
      }
      entries.add((entryResult as AppSuccess<CollectionDashboardEntry>).value);
    }

    return AppSuccess<List<CollectionDashboardEntry>>(entries);
  }

  Future<AppResult<CollectionDashboardEntry>> _loadEntry({
    required String organizationId,
    required String companyId,
    required Collection collection,
  }) async {
    final start = collection.startDate;
    if (start == null) {
      return AppSuccess<CollectionDashboardEntry>(
        CollectionDashboardEntry.undefinedPeriod(
          collectionId: collection.id,
          collectionName: collection.name,
          seasonId: collection.seasonId,
          year: collection.year,
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final declaredEnd = collection.endDate;
    final queryEnd = (declaredEnd == null || declaredEnd.isAfter(now))
        ? now
        : declaredEnd;

    if (queryEnd.isBefore(start)) {
      // A coleção whose período ainda não começou (`startDate` no futuro):
      // never a negative-length month range.
      return AppSuccess<CollectionDashboardEntry>(
        CollectionDashboardEntry(
          collectionId: collection.id,
          collectionName: collection.name,
          seasonId: collection.seasonId,
          year: collection.year,
          periodStart: start,
          periodEnd: declaredEnd,
          hasDefinedPeriod: true,
          revenueGross: 0,
          revenueNet: 0,
          quantitySold: 0,
          orderCount: 0,
          discountAmount: 0,
          categoryMix: const <CollectionDashboardCategoryMix>[],
          sellThrough: const ExecutiveDashboardMetric.notCalculated(),
          margin: const ExecutiveDashboardMetric.notCalculated(),
        ),
      );
    }

    final monthKeys = _monthKeys(start.toUtc(), queryEnd);
    final matchingSnapshots = <AggregationSnapshot>[];
    for (final monthKey in monthKeys) {
      final result = await _aggregationRepository.listByPeriod(
        organizationId: organizationId,
        dimension: AggregationDimension.productMonthly,
        companyId: companyId,
        periodKey: monthKey,
        limit: _rowLimit,
      );
      if (result case AppFailure<List<AggregationSnapshot>>(
        failure: final failure,
      )) {
        return AppFailure<CollectionDashboardEntry>(failure);
      }
      final monthSnapshots =
          (result as AppSuccess<List<AggregationSnapshot>>).value;
      matchingSnapshots.addAll(
        monthSnapshots.where(
          (snapshot) =>
              snapshot.labels['collectionId']?.trim() == collection.id,
        ),
      );
    }

    final revenueGross = matchingSnapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.revenueGross,
    );
    final revenueNet = matchingSnapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.revenueNet,
    );
    final quantitySold = matchingSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.itemQuantity,
    );
    final orderCount = matchingSnapshots.fold<int>(
      0,
      (sum, snapshot) => sum + snapshot.orderCount,
    );
    final discountAmount = matchingSnapshots.fold<double>(
      0,
      (sum, snapshot) => sum + snapshot.discountAmount,
    );

    final categoryMix = _buildCategoryMix(matchingSnapshots, revenueNet);

    final turnoverResult = await _getStockTurnoverMetrics(
      organizationId: organizationId,
      scope: StockTurnoverMetricScope(
        type: StockTurnoverScopeType.collection,
        id: collection.id,
      ),
      periodStart: start,
      periodEnd: declaredEnd ?? now,
    );
    final sellThrough = switch (turnoverResult) {
      AppSuccess<StockTurnoverMetricSnapshot?>(value: final snapshot)
          when snapshot != null =>
        ExecutiveDashboardMetric.available(
          value: snapshot.sellThroughRate * 100,
        ),
      AppSuccess<StockTurnoverMetricSnapshot?>() =>
        const ExecutiveDashboardMetric.notCalculated(),
      AppFailure<StockTurnoverMetricSnapshot?>(failure: final failure) =>
        ExecutiveDashboardMetric.failed(failure.message),
    };

    return AppSuccess<CollectionDashboardEntry>(
      CollectionDashboardEntry(
        collectionId: collection.id,
        collectionName: collection.name,
        seasonId: collection.seasonId,
        year: collection.year,
        periodStart: start,
        periodEnd: declaredEnd,
        hasDefinedPeriod: true,
        revenueGross: revenueGross,
        revenueNet: revenueNet,
        quantitySold: quantitySold,
        orderCount: orderCount,
        discountAmount: discountAmount,
        categoryMix: categoryMix,
        sellThrough: sellThrough,
        margin: const ExecutiveDashboardMetric.notCalculated(),
      ),
    );
  }

  List<CollectionDashboardCategoryMix> _buildCategoryMix(
    List<AggregationSnapshot> snapshots,
    double totalRevenueNet,
  ) {
    final revenueByCategory = <String?, double>{};
    final nameByCategory = <String?, String>{};
    for (final snapshot in snapshots) {
      final categoryId = _nonEmpty(snapshot.labels['categoryId']);
      final categoryName =
          _nonEmpty(snapshot.labels['categoryName']) ?? 'Sem categoria';
      revenueByCategory.update(
        categoryId,
        (value) => value + snapshot.revenueNet,
        ifAbsent: () => snapshot.revenueNet,
      );
      nameByCategory[categoryId] = categoryName;
    }

    final mix = <CollectionDashboardCategoryMix>[
      for (final entry in revenueByCategory.entries)
        CollectionDashboardCategoryMix(
          categoryId: entry.key,
          categoryName: nameByCategory[entry.key] ?? 'Sem categoria',
          revenueNet: entry.value,
          percentage: totalRevenueNet == 0
              ? 0
              : (entry.value / totalRevenueNet) * 100,
        ),
    ]..sort((a, b) => b.revenueNet.compareTo(a.revenueNet));

    return mix;
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  List<String> _monthKeys(DateTime start, DateTime end) {
    final keys = <String>[];
    var cursor = DateTime.utc(start.year, start.month);
    final last = DateTime.utc(end.year, end.month);
    while (!cursor.isAfter(last) && keys.length < _maxMonthsPerCollection) {
      keys.add('${cursor.year}-${cursor.month.toString().padLeft(2, '0')}');
      cursor = DateTime.utc(cursor.year, cursor.month + 1);
    }
    return keys;
  }
}
