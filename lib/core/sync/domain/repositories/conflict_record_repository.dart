import '../../../utils/utils.dart';
import '../entities/conflict_record.dart';

/// Domain contract for the local, persisted queue of manually-resolvable
/// conflicts (TASK-110, EPIC-14 — seção 5.5 de `tasks.md`).
///
/// [ConflictResolutionService] is the only writer of [create] — a
/// [ConflictRecord] always originates from a resolution attempt that was
/// blocked for manual decision, never created directly by a
/// repository/feature. TASK-111's conflict screen is the primary reader of
/// [listOpen]/[getById] and, once wired, the eventual caller of a future
/// `resolve` method this contract will grow when that task needs it.
abstract interface class ConflictRecordRepository {
  /// Persists a new [ConflictRecord] with
  /// `status == ConflictRecordStatus.conflict`.
  Future<AppResult<ConflictRecord>> create(ConflictRecord record);

  /// Every [ConflictRecord] with `status == ConflictRecordStatus.conflict`
  /// for [organizationId], oldest-detected first — the order TASK-111's list
  /// screen prioritizes them in.
  Future<AppResult<List<ConflictRecord>>> listOpen({
    required String organizationId,
  });

  /// A single [ConflictRecord] by [id], or `null` if it does not exist.
  Future<AppResult<ConflictRecord?>> getById(String id);
}
