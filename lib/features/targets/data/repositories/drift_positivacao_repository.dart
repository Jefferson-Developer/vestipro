import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/positivacao_snapshot.dart';
import '../../domain/repositories/positivacao_repository.dart';
import '../../domain/value_objects/positivacao_dimension_type.dart';

/// Drift-backed implementation of [PositivacaoRepository] (TASK-117), reading
/// the server-computed snapshot [PositivacaoSnapshotsTable] reserves for the
/// positivação dashboard — never summing raw Customer/Order documents
/// client-side. Same shape as `DriftTargetAchievementRepository` (TASK-116).
///
/// A missing row (dimension/period never synced locally) and a row with a
/// `null` `calculatedAt` (synced, but no aggregation pipeline populated it
/// yet) both resolve to the same [PositivacaoSnapshot.notCalculated] —
/// the dashboard cannot tell those two apart today, and does not need to.
@LazySingleton(as: PositivacaoRepository)
final class DriftPositivacaoRepository implements PositivacaoRepository {
  const DriftPositivacaoRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppResult<PositivacaoSnapshot>> getForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      final row = await _database.getPositivacaoSnapshotById(
        organizationId: organizationId,
        id: _snapshotId(
          organizationId: organizationId,
          dimensionType: dimensionType,
          dimensionId: dimensionId,
          periodStart: periodStart,
        ),
      );
      return AppSuccess<PositivacaoSnapshot>(
        _toSnapshot(
          organizationId: organizationId,
          companyId: companyId,
          dimensionType: dimensionType,
          dimensionId: dimensionId,
          periodStart: periodStart,
          periodEnd: periodEnd,
          row: row,
        ),
      );
    } catch (exception) {
      return AppFailure<PositivacaoSnapshot>(
        UnexpectedFailure(
          'Unexpected error reading positivação locally.',
          code: 'positivacao_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Stream<PositivacaoSnapshot> watchForDimension({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    return _database
        .watchPositivacaoSnapshotById(
          organizationId: organizationId,
          id: _snapshotId(
            organizationId: organizationId,
            dimensionType: dimensionType,
            dimensionId: dimensionId,
            periodStart: periodStart,
          ),
        )
        .map(
          (row) => _toSnapshot(
            organizationId: organizationId,
            companyId: companyId,
            dimensionType: dimensionType,
            dimensionId: dimensionId,
            periodStart: periodStart,
            periodEnd: periodEnd,
            row: row,
          ),
        );
  }

  /// Deterministic composite key matching
  /// [PositivacaoSnapshotsTable.id]'s own docs.
  String _snapshotId({
    required String organizationId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
  }) {
    return '$organizationId:${dimensionType.name}:$dimensionId:'
        '${periodStart.toUtc().toIso8601String()}';
  }

  PositivacaoSnapshot _toSnapshot({
    required String organizationId,
    required String companyId,
    required PositivacaoDimensionType dimensionType,
    required String dimensionId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required PositivacaoSnapshotsTableData? row,
  }) {
    final calculatedAt = row?.calculatedAt;
    final totalPortfolio = row?.totalPortfolio;
    final positivatedCount = row?.positivatedCount;
    if (calculatedAt == null ||
        totalPortfolio == null ||
        positivatedCount == null) {
      return PositivacaoSnapshot.notCalculated(
        organizationId: organizationId,
        companyId: companyId,
        dimensionType: dimensionType,
        dimensionId: dimensionId,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
    }

    return PositivacaoSnapshot(
      organizationId: organizationId,
      companyId: companyId,
      dimensionType: dimensionType,
      dimensionId: dimensionId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalPortfolio: totalPortfolio,
      positivatedCount: positivatedCount,
      nonPositivatedCustomerIds: _decodeCustomerIds(
        row!.nonPositivatedCustomerIdsJson,
      ),
      calculatedAt: calculatedAt,
    );
  }

  List<String> _decodeCustomerIds(String? json) {
    if (json == null || json.isEmpty) return const <String>[];
    final decoded = jsonDecode(json);
    if (decoded is! List) return const <String>[];
    return decoded.whereType<String>().toList(growable: false);
  }
}
