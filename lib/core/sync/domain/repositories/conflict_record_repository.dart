import '../../../utils/utils.dart';
import '../entities/conflict_record.dart';

/// Domain contract for the local, persisted queue of manually-resolvable
/// conflicts (TASK-110, EPIC-14 — seção 5.5 de `tasks.md`).
///
/// [ConflictResolutionService] is the only writer of [create]/[resolve] — a
/// [ConflictRecord] always originates from a resolution attempt that was
/// blocked for manual decision, never created directly by a
/// repository/feature, and is only ever marked resolved through
/// [ConflictResolutionService.resolveManually] (TASK-111), never by a
/// Cubit/page calling [resolve] directly. TASK-111's conflict screen is the
/// primary reader of [listOpen]/[getById].
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

  /// Marks [id] `status == ConflictRecordStatus.resolved`, recording
  /// [resolvedAt]/[resolvedBy] — the human decision trail TASK-111's screen
  /// requires (`ConflictRecord.resolvedBy` docs). Never applied to a record
  /// that is not currently `conflict`; callers (only
  /// [ConflictResolutionService.resolveManually]) are expected to check that
  /// themselves before calling this.
  Future<AppResult<ConflictRecord>> resolve({
    required String id,
    required String resolvedBy,
    required DateTime resolvedAt,
  });
}
