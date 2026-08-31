import '../../utils/utils.dart';
import 'entities/offline_package_entity_kind.dart';
import 'offline_package_cancellation_token.dart';

enum OfflinePackageEntityLoadOutcome {
  /// The entity finished downloading and its local store was replaced.
  completed,

  /// [OfflinePackageCancellationToken.isCancelled] became `true` before the
  /// entity's local write started — nothing was written for it this run.
  cancelled,
}

/// Result of one [OfflinePackageEntityLoader.load] call.
final class OfflinePackageEntityLoadResult {
  const OfflinePackageEntityLoadResult({
    required this.outcome,
    required this.recordCount,
  });

  final OfflinePackageEntityLoadOutcome outcome;

  /// Records written locally — always `0` when [outcome] is
  /// [OfflinePackageEntityLoadOutcome.cancelled].
  final int recordCount;
}

/// One entity's slice of the offline package download (TASK-107): a feature
/// implements this per `OfflinePackageEntityKind` it owns, adapting its own
/// domain repositories to this uniform contract so
/// `DownloadOfflinePackageUseCase` can orchestrate every entity the same
/// way without knowing anything feature-specific.
///
/// Implementations must:
/// - never read/write data outside the `organizationId`/`companyId` scope
///   they are given;
/// - apply whatever RBAC/carteira filtering the entity requires themselves
///   ([isApplicable] for "does this role get this entity at all", [load]
///   internally for "which subset of the entity does this role get" — e.g.
///   a `SALES_REP`'s own portfolio vs. a `SALES_MANAGER`'s team(s));
/// - check [OfflinePackageCancellationToken.isCancelled] between lots (page
///   fetches, remote calls) and never start their local replace write once
///   it is `true`;
/// - perform their local write as a single atomic replace (already the
///   established `XLocalStoreRepository.replaceInitialLoad` shape most
///   entities already have from earlier tasks) so a crash mid-fetch can
///   never leave the local table half-written.
abstract interface class OfflinePackageEntityLoader {
  OfflinePackageEntityKind get kind;

  /// Whether this entity applies to [userId] at all inside
  /// [organizationId]/[companyId] right now — `false` skips this loader
  /// entirely (it is excluded from the estimate total, progress and
  /// [DownloadOfflinePackageUseCase]'s entity loop).
  Future<AppResult<bool>> isApplicable({
    required String organizationId,
    required String companyId,
    required String userId,
  });

  /// Best-effort record count for the size/progress estimate shown before
  /// the download starts. Never a hard guarantee — implementations are
  /// expected to use whatever cheap signal they have (a remote count, or a
  /// previous local load's count) rather than a full remote fetch.
  Future<AppResult<int>> estimate({
    required String organizationId,
    required String companyId,
    required String userId,
  });

  /// Downloads and atomically replaces this entity's local cache for
  /// [organizationId]/[companyId], scoped to whatever [userId] may see.
  ///
  /// [onProgress] is invoked with the running count of records fetched from
  /// the remote source so far (not necessarily committed yet — see this
  /// interface's class doc). [cancellationToken] must be checked between
  /// lots; once it is cancelled this must return
  /// [OfflinePackageEntityLoadOutcome.cancelled] without writing anything.
  Future<AppResult<OfflinePackageEntityLoadResult>> load({
    required String organizationId,
    required String companyId,
    required String userId,
    required OfflinePackageCancellationToken cancellationToken,
    required void Function(int recordsFetchedSoFar) onProgress,
    DateTime? now,
  });
}
