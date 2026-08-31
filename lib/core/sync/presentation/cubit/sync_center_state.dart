import '../../../errors/errors.dart';
import '../../../offline/domain/entities/offline_package_entity_status.dart';
import '../../domain/entities/outbox_operation.dart';
import '../../domain/entities/outbox_summary.dart';
import '../../domain/entities/sync_cycle_report.dart';

enum SyncCenterLoadStatus { initial, loading, ready, failure }

/// Drives `SyncCenterPage` (TASK-112, EPIC-14): the transparency dashboard
/// over Outbox pendencies (TASK-108), sync failures (TASK-109) and the
/// shortcut into open conflicts (TASK-110/TASK-111) for one
/// `organizationId`/`companyId` scope.
final class SyncCenterState {
  const SyncCenterState({
    this.loadStatus = SyncCenterLoadStatus.initial,
    this.organizationId = '',
    this.companyId = '',
    this.outboxSummary = const OutboxSummary(),
    this.failedOperations = const <OutboxOperation>[],
    this.openConflictCount = 0,
    this.entityStatuses = const <OfflinePackageEntityStatus>[],
    this.isOnline = true,
    this.isSyncing = false,
    this.retryingOperationIds = const <String>{},
    this.failure,
    this.lastManualCycleReport,
    this.lastManualCycleAt,
  });

  final SyncCenterLoadStatus loadStatus;
  final String organizationId;
  final String companyId;

  /// Reactive pending/syncing/failed/conflict counts (TASK-108) — kept in
  /// sync with `OutboxRepository.watchSummary` for the whole time this state
  /// is alive, never re-fetched manually.
  final OutboxSummary outboxSummary;

  /// Every `failed` Outbox operation for [organizationId], oldest first —
  /// re-fetched after every action that could change it (manual sync,
  /// individual/batch retry) since `OutboxRepository` has no reactive stream
  /// for the full rows, only for [outboxSummary]'s counts.
  final List<OutboxOperation> failedOperations;

  /// How many `ConflictRecord`s are currently open (TASK-110/TASK-111) —
  /// `SyncCenterView` links into `ConflictListRoute` whenever this is `> 0`.
  final int openConflictCount;

  /// The "última carga completa" marker (TASK-107) per entity the offline
  /// package can carry — what the "última sincronização" section of the
  /// screen renders per entity.
  final List<OfflinePackageEntityStatus> entityStatuses;

  /// Whether the device currently has network connectivity
  /// (`ConnectivityService`) — while `false`, `SyncCenterView` explains that
  /// no sync attempt will happen until reconnection instead of showing a
  /// generic failure.
  final bool isOnline;

  /// Whether a manual "Sincronizar agora"/"Tentar novamente todos" cycle is
  /// currently running — disables every retry action while `true` so a
  /// second manual trigger can never overlap the first (TASK-112's own
  /// restriction).
  final bool isSyncing;

  /// `OutboxOperation.id`s currently being retried individually — drives the
  /// per-row loading state of `OutboxFailedItemCard` without blocking every
  /// other row's own "Tentar novamente" button.
  final Set<String> retryingOperationIds;

  final Failure? failure;

  /// The outcome of the last manual "Sincronizar agora" cycle, kept only to
  /// drive a one-shot snackbar in `SyncCenterView` — never rendered
  /// directly, since a `SyncPushReport`/`SyncPullReport` failure count alone
  /// is not yet the business-friendly message TASK-112 requires (that comes
  /// from [failedOperations] instead).
  final SyncCycleReport? lastManualCycleReport;

  /// When [lastManualCycleReport] was produced — `BlocListener` compares
  /// this against its previous value to fire the snackbar exactly once per
  /// cycle, never on every rebuild.
  final DateTime? lastManualCycleAt;

  bool get isInitialLoading =>
      loadStatus == SyncCenterLoadStatus.initial ||
      loadStatus == SyncCenterLoadStatus.loading;

  bool get hasFailures => failedOperations.isNotEmpty;

  bool get hasConflicts => openConflictCount > 0;

  bool get isFullySynced =>
      loadStatus == SyncCenterLoadStatus.ready &&
      outboxSummary.totalUnsyncedCount == 0 &&
      openConflictCount == 0;

  /// The most recent successful full load among [entityStatuses], or `null`
  /// if none has ever completed for this scope — the overall "última
  /// sincronização" timestamp shown at the top of the screen.
  DateTime? get lastFullSyncAt {
    DateTime? latest;
    for (final status in entityStatuses) {
      final completedAt = status.lastCompletedAt;
      if (completedAt == null) continue;
      if (latest == null || completedAt.isAfter(latest)) {
        latest = completedAt;
      }
    }
    return latest;
  }

  SyncCenterState copyWith({
    SyncCenterLoadStatus? loadStatus,
    String? organizationId,
    String? companyId,
    OutboxSummary? outboxSummary,
    List<OutboxOperation>? failedOperations,
    int? openConflictCount,
    List<OfflinePackageEntityStatus>? entityStatuses,
    bool? isOnline,
    bool? isSyncing,
    Set<String>? retryingOperationIds,
    Failure? failure,
    bool clearFailure = false,
    SyncCycleReport? lastManualCycleReport,
    DateTime? lastManualCycleAt,
  }) {
    return SyncCenterState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      outboxSummary: outboxSummary ?? this.outboxSummary,
      failedOperations: failedOperations ?? this.failedOperations,
      openConflictCount: openConflictCount ?? this.openConflictCount,
      entityStatuses: entityStatuses ?? this.entityStatuses,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      retryingOperationIds: retryingOperationIds ?? this.retryingOperationIds,
      failure: clearFailure ? null : failure ?? this.failure,
      lastManualCycleReport:
          lastManualCycleReport ?? this.lastManualCycleReport,
      lastManualCycleAt: lastManualCycleAt ?? this.lastManualCycleAt,
    );
  }
}
