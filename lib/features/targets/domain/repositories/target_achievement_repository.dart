import '../../../../core/utils/utils.dart';
import '../entities/target_achievement_snapshot.dart';

/// Domain contract for reading the server-computed "realizado" behind one
/// `Target` (TASK-116, EPIC-15), decoupled from Firestore/Drift — mirroring
/// the precedent set by `TargetRepository` itself (TASK-114).
///
/// Never a summation contract: every implementation must resolve
/// [TargetAchievementSnapshot.realizedValue] from a value some server-side
/// aggregation already computed (a Cloud Function/BI pipeline), cached
/// locally — this is the single seam `UpdateTargetUseCase`'s own
/// `currentAchievedValue` parameter doc already anticipated ("e.g. from the
/// TASK-116 dashboard's local cache").
abstract interface class TargetAchievementRepository {
  /// One-shot read of the current snapshot for [targetId].
  Future<AppResult<TargetAchievementSnapshot>> getForTarget({
    required String organizationId,
    required String targetId,
  });

  /// Near-real-time stream of [targetId]'s snapshot: emits again whenever
  /// the underlying local cache is refreshed by a future sync pass — the
  /// mechanism TASK-116's "atualização em tempo real (ou near real-time)"
  /// requirement is built on, without polling.
  Stream<TargetAchievementSnapshot> watchForTarget({
    required String organizationId,
    required String targetId,
  });
}
