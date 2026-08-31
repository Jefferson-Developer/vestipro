import 'dart:async' show unawaited;

import 'package:injectable/injectable.dart';

import '../../analytics/analytics.dart';
import '../../offline/domain/entities/offline_package_entity_kind.dart';
import '../../services/services.dart';
import '../../utils/utils.dart';
import 'entities/outbox_entity_type.dart';
import 'entities/outbox_operation.dart';
import 'entities/outbox_status.dart';
import 'entities/sync_cycle_report.dart';
import 'entities/sync_pull_record.dart';
import 'entities/sync_pull_report.dart';
import 'entities/sync_push_outcome.dart';
import 'entities/sync_push_report.dart';
import 'repositories/outbox_repository.dart';
import 'repositories/sync_cursor_repository.dart';
import 'sync_pull_source.dart';
import 'sync_push_handler.dart';
import 'sync_retry_policy.dart';

/// Incremental synchronization engine between the local (Drift) database and
/// Firestore/Cloud Functions (TASK-109, EPIC-14 — seção 5.4/14 de
/// `tasks.md`).
///
/// Two independent passes, both scoped to one `organizationId`/`companyId`
/// at a time — this class never iterates over every tenant on the device by
/// itself, callers ([SyncScheduler] or a future manual "sincronizar agora"
/// action) always pass the currently active scope explicitly:
///
/// - [runPush] drains the local Outbox (TASK-108) — every `pending`/
///   `failed`-but-due operation, oldest first per
///   `OutboxOperation.sequenceNumber` — dispatching each to the
///   [SyncPushHandler] registered for its `OutboxEntityType`, with
///   exponential backoff/retry-limit ([SyncRetryPolicy]) and idempotency
///   (`OutboxOperation.clientOperationId` plus [SyncPushAlreadyProcessed]).
/// - [runPull] asks every registered [SyncPullSource] for what changed
///   remotely since its persisted [SyncCursorRepository] cursor, and applies
///   it locally as an upsert — never a full re-download.
///
/// [runFullCycle] runs push, then pull, in that order: pushing local writes
/// out first shrinks the set of entities a subsequent pull might otherwise
/// have to skip (see [runPull] docs) and keeps the device's own edits from
/// looking, even momentarily, like they lost to a remote value it just
/// hasn't sent yet.
///
/// Nothing is wired to actually run either pass yet ([SyncScheduler] exists
/// but nothing in `lib/app/` calls `SyncScheduler.start` on sign-in/sign-out
/// yet) and neither list of adapters
/// (`SyncModule.syncPushHandlers`/`syncPullSources`, in `lib/app/`) has a
/// concrete entry yet — every push/pull path here is exercised through
/// fakes in tests until a feature adopts the Outbox (push) or registers a
/// `SyncPullSource` (pull). This mirrors `DownloadOfflinePackageUseCase`
/// (TASK-107) at the same point in its own history.
@lazySingleton
final class SyncEngine {
  SyncEngine(
    this._outboxRepository,
    this._syncCursorRepository,
    this._pushHandlers,
    this._pullSources,
    this._analyticsService,
    this._crashReporter, {
    SyncRetryPolicy? retryPolicy,
  }) : _retryPolicy = retryPolicy ?? const SyncRetryPolicy();

  final OutboxRepository _outboxRepository;
  final SyncCursorRepository _syncCursorRepository;
  final List<SyncPushHandler> _pushHandlers;
  final List<SyncPullSource> _pullSources;
  final AnalyticsService _analyticsService;
  final CrashReporter _crashReporter;
  final SyncRetryPolicy _retryPolicy;

  /// Runs [runPush] then [runPull] for [organizationId]/[companyId].
  Future<SyncCycleReport> runFullCycle({
    required String organizationId,
    required String companyId,
    DateTime? now,
  }) async {
    final push = await runPush(organizationId: organizationId, now: now);
    final pull = await runPull(
      organizationId: organizationId,
      companyId: companyId,
      now: now,
    );
    return SyncCycleReport(
      push: push,
      pull: pull,
      completedAt: now ?? DateTime.now().toUtc(),
    );
  }

  /// Drains the Outbox for [organizationId] — see this class' docs for the
  /// overall push contract.
  ///
  /// ## Crash/interruption recovery
  ///
  /// Every operation still in `OutboxStatus.syncing` when this method
  /// *starts* is, by construction, left over from a previous [runPush] call
  /// that was interrupted between `OutboxRepository.markSyncing` and the
  /// matching `markSynced`/`markFailed`/`markConflict` (this method never
  /// runs two pushes concurrently for the same scope by itself — see
  /// [SyncScheduler] — so a `syncing` row here cannot belong to a push
  /// currently in flight). Each is moved to `failed` before this cycle's
  /// normal draining starts, so it re-enters the retry path instead of
  /// being stuck `syncing` forever — never corrupted, never silently lost.
  Future<SyncPushReport> runPush({
    required String organizationId,
    DateTime? now,
  }) async {
    final resolvedNow = now ?? DateTime.now().toUtc();
    final stopwatch = Stopwatch()..start();

    var attempted = 0;
    var synced = 0;
    var failed = 0;
    var conflicts = 0;

    final orphanedResult = await _outboxRepository.listByStatus(
      organizationId: organizationId,
      statuses: const <OutboxStatus>[OutboxStatus.syncing],
    );
    if (orphanedResult case AppSuccess<List<OutboxOperation>>(
      value: final orphaned,
    )) {
      for (final operation in orphaned) {
        await _outboxRepository.markFailed(
          id: operation.id,
          error:
              'Sincronização anterior interrompida antes de uma resposta '
              'do servidor; reagendada para nova tentativa.',
          attemptedAt: resolvedNow,
        );
      }
    }

    final candidatesResult = await _outboxRepository.listByStatus(
      organizationId: organizationId,
      statuses: const <OutboxStatus>[OutboxStatus.pending, OutboxStatus.failed],
    );
    final candidates = candidatesResult.fold(
      onSuccess: (value) => value,
      onFailure: (failure) {
        unawaited(
          _crashReporter.recordError(
            StateError(failure.toString()),
            StackTrace.current,
            reason: 'SyncEngine.runPush: failed to list Outbox candidates',
          ),
        );
        return const <OutboxOperation>[];
      },
    );

    for (final operation in candidates) {
      if (operation.status == OutboxStatus.failed) {
        if (!_retryPolicy.hasAttemptsLeft(operation.attemptCount)) {
          // Retry budget exhausted — stays `failed` for manual action
          // (TASK-112), never retried automatically again.
          continue;
        }
        if (!_retryPolicy.isDueForRetry(
          attemptCount: operation.attemptCount,
          lastAttemptAt: operation.lastAttemptAt,
          now: resolvedNow,
        )) {
          continue;
        }
      }

      attempted++;
      await _outboxRepository.markSyncing(
        id: operation.id,
        attemptedAt: resolvedNow,
      );

      final handler = _pushHandlerFor(operation.entityType);
      if (handler == null) {
        failed++;
        await _outboxRepository.markFailed(
          id: operation.id,
          error:
              'Nenhum SyncPushHandler registrado para '
              '"${operation.entityType.code}" (ver SyncModule em lib/app/).',
          attemptedAt: resolvedNow,
        );
        continue;
      }

      SyncPushOutcome outcome;
      try {
        outcome = await handler.push(operation);
      } catch (exception, stackTrace) {
        outcome = SyncPushRetryableFailure(exception.toString());
        unawaited(
          _crashReporter.recordError(
            exception,
            stackTrace,
            reason: 'SyncEngine.runPush: ${operation.entityType.code} handler',
          ),
        );
      }

      switch (outcome) {
        case SyncPushSynced() || SyncPushAlreadyProcessed():
          synced++;
          await _outboxRepository.markSynced(id: operation.id);
        case SyncPushRetryableFailure(message: final message):
          failed++;
          await _outboxRepository.markFailed(
            id: operation.id,
            error: message,
            attemptedAt: resolvedNow,
          );
        case SyncPushConflict(message: final message):
          conflicts++;
          await _outboxRepository.markConflict(
            id: operation.id,
            error: message,
            attemptedAt: resolvedNow,
          );
      }
    }

    stopwatch.stop();
    final report = SyncPushReport(
      attempted: attempted,
      synced: synced,
      failed: failed,
      conflicts: conflicts,
      duration: stopwatch.elapsed,
    );

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.syncPushCompleted,
        parameters: <String, Object?>{
          'attempted': report.attempted,
          'synced': report.synced,
          'failed': report.failed,
          'conflicts': report.conflicts,
          'duration_ms': report.duration.inMilliseconds,
        },
      ),
    );

    return report;
  }

  /// Applies incremental remote changes for [organizationId]/[companyId]
  /// across every registered [SyncPullSource] — see this class' docs for
  /// the overall pull contract.
  ///
  /// ## Why a page with a skipped/rejected record never advances its cursor
  ///
  /// A record is skipped when its entity has a pending/unsynced Outbox
  /// operation locally (never overwritten without TASK-110's conflict
  /// resolution) or rejected when its `organizationId` does not match the
  /// scope requested (the tenant-isolation guard). If the persisted cursor
  /// advanced past such a record anyway, the next incremental pull would
  /// start *after* it and that remote change would never be looked at
  /// again. So whenever a page contains at least one skipped/rejected/
  /// failed-to-apply record, this method leaves the cursor exactly where it
  /// was before that page — the next cycle re-fetches the same page (upserts
  /// are idempotent, so re-applying already-applied records in it is
  /// harmless) until nothing in it needs skipping anymore.
  Future<SyncPullReport> runPull({
    required String organizationId,
    required String companyId,
    DateTime? now,
    int maxPagesPerSource = 20,
  }) async {
    final resolvedNow = now ?? DateTime.now().toUtc();
    final stopwatch = Stopwatch()..start();

    var sourcesProcessed = 0;
    var sourcesFailed = 0;
    var applied = 0;
    var skipped = 0;
    var rejectedCrossTenant = 0;

    for (final source in _pullSources) {
      sourcesProcessed++;
      final excludedEntityIds = await _pendingEntityIdsFor(
        organizationId: organizationId,
        kind: source.kind,
      );

      final cursorResult = await _syncCursorRepository.getCursor(
        organizationId: organizationId,
        companyId: companyId,
        kind: source.kind,
      );
      var cursor = cursorResult.fold(
        onSuccess: (value) => value?.cursorValue,
        onFailure: (_) => null,
      );

      var iterations = 0;
      var sourceFailedThisCycle = false;
      while (iterations < maxPagesPerSource) {
        iterations++;
        final pageResult = await source.fetchChanges(
          organizationId: organizationId,
          companyId: companyId,
          cursor: cursor,
        );
        if (pageResult case AppFailure<SyncPullPage>(failure: final failure)) {
          sourceFailedThisCycle = true;
          unawaited(
            _crashReporter.recordError(
              StateError(failure.toString()),
              StackTrace.current,
              reason: 'SyncEngine.runPull: ${source.kind.code} fetchChanges',
            ),
          );
          break;
        }
        final page = (pageResult as AppSuccess<SyncPullPage>).value;

        var pageHadIssue = false;
        for (final record in page.records) {
          if (record.organizationId != organizationId) {
            rejectedCrossTenant++;
            pageHadIssue = true;
            unawaited(
              _crashReporter.recordError(
                StateError(
                  'SyncPullSource "${source.kind.code}" returned a record '
                  'for a different organizationId than requested; rejected.',
                ),
                StackTrace.current,
                reason: 'SyncEngine.runPull tenant isolation guard',
              ),
            );
            continue;
          }

          if (excludedEntityIds.contains(record.entityId)) {
            skipped++;
            pageHadIssue = true;
            continue;
          }

          final applyResult = await source.apply(record);
          if (applyResult case AppFailure<void>()) {
            pageHadIssue = true;
            continue;
          }
          applied++;
        }

        if (!pageHadIssue &&
            page.nextCursor != null &&
            page.nextCursor != cursor) {
          cursor = page.nextCursor;
          await _syncCursorRepository.saveCursor(
            organizationId: organizationId,
            companyId: companyId,
            kind: source.kind,
            cursorValue: cursor,
            updatedAt: resolvedNow,
          );
        }

        if (pageHadIssue || !page.hasMore) break;
      }

      if (sourceFailedThisCycle) sourcesFailed++;
    }

    stopwatch.stop();
    final report = SyncPullReport(
      sourcesProcessed: sourcesProcessed,
      sourcesFailed: sourcesFailed,
      applied: applied,
      skipped: skipped,
      rejectedCrossTenant: rejectedCrossTenant,
      duration: stopwatch.elapsed,
    );

    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.syncPullCompleted,
        parameters: <String, Object?>{
          'sources_processed': report.sourcesProcessed,
          'sources_failed': report.sourcesFailed,
          'applied': report.applied,
          'skipped': report.skipped,
          'rejected_cross_tenant': report.rejectedCrossTenant,
          'duration_ms': report.duration.inMilliseconds,
        },
      ),
    );

    return report;
  }

  SyncPushHandler? _pushHandlerFor(OutboxEntityType entityType) {
    for (final handler in _pushHandlers) {
      if (handler.entityType == entityType) return handler;
    }
    return null;
  }

  /// Every locally not-yet-synced entity id of the `OutboxEntityType` that
  /// overlaps [kind] (today only `customers`/`customer`) — the set
  /// [runPull] must never silently overwrite with a remote value. A [kind]
  /// with no Outbox overlap (most of them, currently) always returns an
  /// empty set without querying the Outbox at all.
  Future<Set<String>> _pendingEntityIdsFor({
    required String organizationId,
    required OfflinePackageEntityKind kind,
  }) async {
    final outboxEntityType = _outboxEntityTypeFor(kind);
    if (outboxEntityType == null) return const <String>{};

    final result = await _outboxRepository.listByStatus(
      organizationId: organizationId,
      statuses: const <OutboxStatus>[
        OutboxStatus.pending,
        OutboxStatus.syncing,
        OutboxStatus.failed,
        OutboxStatus.conflict,
      ],
    );
    return result.fold(
      onSuccess: (operations) => operations
          .where((operation) => operation.entityType == outboxEntityType)
          .map((operation) => operation.entityId)
          .toSet(),
      onFailure: (_) => const <String>{},
    );
  }

  /// The `OutboxEntityType` a given pull [kind] shares Outbox rows with, or
  /// `null` when that entity never writes through the Outbox (most of
  /// `OfflinePackageEntityKind` today) — see `OutboxEntityType` docs for the
  /// up-to-date list of entities actually wired to enqueue an operation.
  OutboxEntityType? _outboxEntityTypeFor(OfflinePackageEntityKind kind) {
    return switch (kind) {
      OfflinePackageEntityKind.customers => OutboxEntityType.customer,
      _ => null,
    };
  }
}
