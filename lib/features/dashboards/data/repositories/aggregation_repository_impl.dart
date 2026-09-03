import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/aggregation_snapshot.dart';
import '../../domain/repositories/aggregation_repository.dart';
import '../../domain/value_objects/aggregation_dimension.dart';
import '../datasources/aggregation_remote_data_source.dart';
import '../datasources/firestore_aggregation_data_source.dart';
import '../mappers/aggregation_snapshot_mapper.dart';

/// Reads from the five pre-computed aggregate collections
/// (`functions/src/aggregations`) with an in-memory, TTL-bounded cache in
/// front of the remote datasource — never recomputing anything client-side.
///
/// Deliberately an **in-memory** cache, not a Drift-backed one like
/// `VariantStockBalanceRepositoryImpl`
/// (`lib/features/inventory/data/repositories/variant_stock_balance_repository_impl.dart`):
/// dashboard aggregates are never on the offline-first commercial critical
/// path — no order/pricing/stock decision this app makes depends on a
/// dashboard rendering while offline, unlike stock balances which gate
/// whether a seller can add a line to an order at all. A dashboard reopened
/// after the app restarts simply refetches once back online. Adding a new
/// Drift table/migration for this is deferred to whichever dashboard task
/// (TASK-134+) turns out to actually need offline persistence for a
/// specific widget, once its concrete read pattern is known — this keeps
/// this task's schema footprint at zero.
@LazySingleton(as: AggregationRepository)
final class AggregationRepositoryImpl implements AggregationRepository {
  AggregationRepositoryImpl(
    this._remote,
    this._mapper, {
    this.cacheTtl = const Duration(minutes: 5),
    @ignoreParam DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Shorter than `VariantStockBalanceRepositoryImpl.cacheTtl` (10 minutes)
  /// on purpose: dashboard data is expected to be "fresh enough", not
  /// stock-decision-critical, but a `salesDaily` widget showing "hoje" still
  /// shouldn't feel stale for the length of an entire shopping session.
  final Duration cacheTtl;

  final AggregationRemoteDataSource _remote;
  final AggregationSnapshotMapper _mapper;
  final DateTime Function() _now;

  final Map<String, _CacheEntry<AggregationSnapshot?>> _snapshotCache =
      <String, _CacheEntry<AggregationSnapshot?>>{};
  final Map<String, _CacheEntry<List<AggregationSnapshot>>> _listCache =
      <String, _CacheEntry<List<AggregationSnapshot>>>{};

  @override
  Future<AppResult<AggregationSnapshot?>> getSnapshot({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String periodKey,
  }) async {
    final docId = buildAggregationDocId(
      companyId: companyId,
      scopeId: scopeId,
      periodKey: periodKey,
    );
    final cacheKey = 'snapshot::$organizationId::${dimension.name}::$docId';
    final cached = _snapshotCache[cacheKey];
    if (cached != null && !_isExpired(cached.fetchedAt)) {
      return AppSuccess<AggregationSnapshot?>(cached.value);
    }

    try {
      final dto = await _remote.getById(
        organizationId: organizationId,
        dimension: dimension,
        docId: docId,
      );
      final snapshot = dto == null ? null : _mapper.toEntity(dto);
      _snapshotCache[cacheKey] = _CacheEntry<AggregationSnapshot?>(
        snapshot,
        _now(),
      );
      return AppSuccess<AggregationSnapshot?>(snapshot);
    } on AppException catch (exception) {
      return AppFailure<AggregationSnapshot?>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<AggregationSnapshot?>(
        UnexpectedFailure(
          'Unexpected error loading an aggregation snapshot.',
          code: 'aggregation_snapshot_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<AggregationSnapshot>>> listByPeriod({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String periodKey,
    int limit = 50,
  }) async {
    final cacheKey =
        'byPeriod::$organizationId::${dimension.name}::$companyId::$periodKey::$limit';
    final cached = _listCache[cacheKey];
    if (cached != null && !_isExpired(cached.fetchedAt)) {
      return AppSuccess<List<AggregationSnapshot>>(cached.value);
    }

    try {
      final dtos = await _remote.listByPeriod(
        organizationId: organizationId,
        dimension: dimension,
        companyId: companyId,
        periodKey: periodKey,
        limit: limit,
      );
      final snapshots = dtos.map(_mapper.toEntity).toList(growable: false);
      _listCache[cacheKey] = _CacheEntry<List<AggregationSnapshot>>(
        snapshots,
        _now(),
      );
      return AppSuccess<List<AggregationSnapshot>>(snapshots);
    } on AppException catch (exception) {
      return AppFailure<List<AggregationSnapshot>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<AggregationSnapshot>>(
        UnexpectedFailure(
          'Unexpected error listing aggregation snapshots by period.',
          code: 'aggregation_snapshot_list_by_period_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<AggregationSnapshot>>> listByPeriodRange({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String fromPeriodKey,
    required String toPeriodKey,
  }) async {
    final cacheKey =
        'byRange::$organizationId::${dimension.name}::$companyId::$scopeId::$fromPeriodKey::$toPeriodKey';
    final cached = _listCache[cacheKey];
    if (cached != null && !_isExpired(cached.fetchedAt)) {
      return AppSuccess<List<AggregationSnapshot>>(cached.value);
    }

    try {
      final dtos = await _remote.listByPeriodRange(
        organizationId: organizationId,
        dimension: dimension,
        companyId: companyId,
        scopeId: scopeId,
        fromPeriodKey: fromPeriodKey,
        toPeriodKey: toPeriodKey,
      );
      final snapshots = dtos.map(_mapper.toEntity).toList(growable: false);
      _listCache[cacheKey] = _CacheEntry<List<AggregationSnapshot>>(
        snapshots,
        _now(),
      );
      return AppSuccess<List<AggregationSnapshot>>(snapshots);
    } on AppException catch (exception) {
      return AppFailure<List<AggregationSnapshot>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<AggregationSnapshot>>(
        UnexpectedFailure(
          'Unexpected error listing aggregation snapshots by period range.',
          code: 'aggregation_snapshot_list_by_range_unexpected',
          cause: exception,
        ),
      );
    }
  }

  bool _isExpired(DateTime fetchedAt) {
    return _now().difference(fetchedAt) >= cacheTtl;
  }
}

final class _CacheEntry<T> {
  const _CacheEntry(this.value, this.fetchedAt);

  final T value;
  final DateTime fetchedAt;
}
