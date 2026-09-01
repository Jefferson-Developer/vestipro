import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/target_achievement_snapshot.dart';
import '../../domain/repositories/target_achievement_repository.dart';

/// Drift-backed implementation of [TargetAchievementRepository] (TASK-116),
/// reading the server-computed snapshot [TargetsTable] already reserves for
/// this dashboard (`achievedValueCache`/`updatedAt`) — never summing raw
/// order documents client-side.
///
/// A `null` [TargetsTableData] row (Target id not found locally yet) and a
/// `null` `achievedValueCache` (row present, no aggregation has populated it
/// yet) both resolve to the same "not calculated" [TargetAchievementSnapshot]
/// — the dashboard cannot tell those two apart today, and does not need to:
/// either way there is nothing to show yet.
@LazySingleton(as: TargetAchievementRepository)
final class DriftTargetAchievementRepository
    implements TargetAchievementRepository {
  const DriftTargetAchievementRepository(this._database);

  final AppDatabase _database;

  @override
  Future<AppResult<TargetAchievementSnapshot>> getForTarget({
    required String organizationId,
    required String targetId,
  }) async {
    try {
      final row = await _database.getTargetById(
        organizationId: organizationId,
        id: targetId,
      );
      return AppSuccess<TargetAchievementSnapshot>(_toSnapshot(targetId, row));
    } catch (exception) {
      return AppFailure<TargetAchievementSnapshot>(
        UnexpectedFailure(
          'Unexpected error reading target achievement locally.',
          code: 'target_achievement_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Stream<TargetAchievementSnapshot> watchForTarget({
    required String organizationId,
    required String targetId,
  }) {
    return _database
        .watchTargetById(organizationId: organizationId, id: targetId)
        .map((row) => _toSnapshot(targetId, row));
  }

  TargetAchievementSnapshot _toSnapshot(
    String targetId,
    TargetsTableData? row,
  ) {
    final realizedValue = row?.achievedValueCache;
    if (realizedValue == null) {
      return TargetAchievementSnapshot(targetId: targetId);
    }
    return TargetAchievementSnapshot(
      targetId: targetId,
      realizedValue: realizedValue,
      calculatedAt: row!.updatedAt,
    );
  }
}
