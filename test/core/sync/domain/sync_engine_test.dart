import 'dart:collection';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/services/services.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

class _RecordingCrashReporter implements CrashReporter {
  final List<Object> recordedErrors = [];

  @override
  Future<void> recordError(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    recordedErrors.add(exception);
  }

  @override
  Future<void> setUserIdentifier(String? userId) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}
}

/// Simulates a backend that recognizes a replayed `clientOperationId` as
/// already processed — [behavior] lets individual tests script a specific
/// outcome sequence (e.g. a client-perceived timeout on the first call for a
/// write the "server" already committed).
class _FakePushHandler implements SyncPushHandler {
  _FakePushHandler(this.entityType);

  @override
  final OutboxEntityType entityType;

  final List<OutboxOperation> pushCalls = [];
  final Set<String> remoteProcessedIds = {};
  SyncPushOutcome Function(OutboxOperation operation)? behavior;

  @override
  Future<SyncPushOutcome> push(OutboxOperation operation) async {
    pushCalls.add(operation);
    if (behavior != null) return behavior!(operation);

    if (remoteProcessedIds.contains(operation.clientOperationId)) {
      return const SyncPushAlreadyProcessed();
    }
    remoteProcessedIds.add(operation.clientOperationId);
    return const SyncPushSynced();
  }
}

class _FakeSyncPullSource implements SyncPullSource {
  _FakeSyncPullSource(this.kind);

  @override
  final OfflinePackageEntityKind kind;

  final List<SyncPullRecord> applied = [];
  final List<String?> fetchCursors = [];
  final Queue<AppResult<SyncPullPage>> _scriptedPages =
      Queue<AppResult<SyncPullPage>>();

  void enqueuePage(AppResult<SyncPullPage> result) =>
      _scriptedPages.add(result);

  @override
  Future<AppResult<SyncPullPage>> fetchChanges({
    required String organizationId,
    required String companyId,
    String? cursor,
  }) async {
    fetchCursors.add(cursor);
    if (_scriptedPages.isEmpty) {
      return const AppSuccess<SyncPullPage>(SyncPullPage(records: []));
    }
    return _scriptedPages.removeFirst();
  }

  @override
  Future<AppResult<void>> apply(SyncPullRecord record) async {
    applied.add(record);
    return const AppSuccess<void>(null);
  }
}

void main() {
  group('SyncEngine.runPush', () {
    late AppDatabase database;
    late DriftOutboxRepository outboxRepository;
    late DriftSyncCursorRepository syncCursorRepository;
    late FakeAnalyticsService analyticsService;
    late _RecordingCrashReporter crashReporter;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      outboxRepository = DriftOutboxRepository(database);
      syncCursorRepository = DriftSyncCursorRepository(database);
      analyticsService = FakeAnalyticsService();
      crashReporter = _RecordingCrashReporter();
    });

    tearDown(() async {
      await database.close();
    });

    SyncEngine buildEngine({
      List<SyncPushHandler> pushHandlers = const [],
      List<SyncPullSource> pullSources = const [],
      SyncRetryPolicy? retryPolicy,
    }) {
      return SyncEngine(
        outboxRepository,
        syncCursorRepository,
        pushHandlers,
        pullSources,
        analyticsService,
        crashReporter,
        retryPolicy: retryPolicy,
      );
    }

    test(
      'a successfully pushed operation moves from pending to synced',
      () async {
        final now = DateTime.utc(2026, 1, 1);
        await outboxRepository.enqueue(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
          operationType: OutboxOperationType.create,
          payload: const <String, dynamic>{'total': 10},
          createdAt: now,
          createdBy: 'seller-1',
        );

        final handler = _FakePushHandler(OutboxEntityType.order);
        final engine = buildEngine(pushHandlers: [handler]);

        final report = await engine.runPush(organizationId: 'org-1', now: now);

        expect(report.attempted, 1);
        expect(report.synced, 1);
        expect(report.failed, 0);
        expect(handler.pushCalls, hasLength(1));

        final listResult = await outboxRepository.listByStatus(
          organizationId: 'org-1',
          statuses: const <OutboxStatus>[OutboxStatus.synced],
        );
        expect(
          (listResult as AppSuccess<List<OutboxOperation>>).value,
          hasLength(1),
        );

        expect(
          analyticsService.loggedEvents.map((event) => event.name),
          contains(AnalyticsEvents.syncPushCompleted),
        );
      },
    );

    test(
      'a retryable failure backs off exponentially and stops after '
      'maxAttempts, leaving the operation failed for manual action',
      () async {
        const retryPolicy = SyncRetryPolicy(
          maxAttempts: 3,
          baseDelay: Duration(seconds: 2),
        );
        final handler = _FakePushHandler(OutboxEntityType.order)
          ..behavior = (_) => const SyncPushRetryableFailure('network timeout');
        final engine = buildEngine(
          pushHandlers: [handler],
          retryPolicy: retryPolicy,
        );

        var now = DateTime.utc(2026, 1, 1, 12);
        await outboxRepository.enqueue(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
          operationType: OutboxOperationType.create,
          payload: const <String, dynamic>{},
          createdAt: now,
          createdBy: 'seller-1',
        );

        // Attempt 1.
        final firstReport = await engine.runPush(
          organizationId: 'org-1',
          now: now,
        );
        expect(firstReport.attempted, 1);
        expect(firstReport.failed, 1);

        // Too soon for attempt 2 (backoff after attempt 1 is 2s).
        now = now.add(const Duration(seconds: 1));
        final tooSoonReport = await engine.runPush(
          organizationId: 'org-1',
          now: now,
        );
        expect(tooSoonReport.attempted, 0);
        expect(handler.pushCalls, hasLength(1));

        // Attempt 2, right at the 2s boundary.
        now = now.add(const Duration(seconds: 1));
        final secondReport = await engine.runPush(
          organizationId: 'org-1',
          now: now,
        );
        expect(secondReport.attempted, 1);
        expect(handler.pushCalls, hasLength(2));

        // Attempt 3, after the (now doubled) 4s backoff.
        now = now.add(const Duration(seconds: 4));
        final thirdReport = await engine.runPush(
          organizationId: 'org-1',
          now: now,
        );
        expect(thirdReport.attempted, 1);
        expect(handler.pushCalls, hasLength(3));

        // Retry budget exhausted (maxAttempts: 3) — never attempted again,
        // even long after any backoff window would have elapsed.
        now = now.add(const Duration(days: 1));
        final exhaustedReport = await engine.runPush(
          organizationId: 'org-1',
          now: now,
        );
        expect(exhaustedReport.attempted, 0);
        expect(handler.pushCalls, hasLength(3));

        final finalState = await outboxRepository.listByStatus(
          organizationId: 'org-1',
          statuses: const <OutboxStatus>[OutboxStatus.failed],
        );
        final operations =
            (finalState as AppSuccess<List<OutboxOperation>>).value;
        expect(operations.single.attemptCount, 3);
      },
    );

    test(
      'idempotency: replaying an operation the backend already committed '
      'is treated as synced without creating a second remote record',
      () async {
        final now = DateTime.utc(2026, 1, 1);
        final handler = _FakePushHandler(OutboxEntityType.order);
        handler.behavior = (operation) {
          final alreadyProcessed = handler.remoteProcessedIds.contains(
            operation.clientOperationId,
          );
          if (!alreadyProcessed) {
            // The "server" persists it on this very call...
            handler.remoteProcessedIds.add(operation.clientOperationId);
            if (handler.pushCalls.length == 1) {
              // ...but the client never sees the response (e.g. dropped
              // connection), so it will retry.
              return const SyncPushRetryableFailure('client-perceived timeout');
            }
            return const SyncPushSynced();
          }
          return const SyncPushAlreadyProcessed();
        };

        final engine = buildEngine(
          pushHandlers: [handler],
          retryPolicy: const SyncRetryPolicy(baseDelay: Duration(seconds: 1)),
        );

        await outboxRepository.enqueue(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
          operationType: OutboxOperationType.create,
          payload: const <String, dynamic>{},
          createdAt: now,
          createdBy: 'seller-1',
        );

        // First attempt: "server" commits it, client reports failure.
        final firstReport = await engine.runPush(
          organizationId: 'org-1',
          now: now,
        );
        expect(firstReport.failed, 1);
        expect(handler.remoteProcessedIds, hasLength(1));

        // Retry after backoff: backend recognizes the same
        // clientOperationId and answers "already processed".
        final secondReport = await engine.runPush(
          organizationId: 'org-1',
          now: now.add(const Duration(seconds: 1)),
        );
        expect(secondReport.synced, 1);
        expect(handler.pushCalls, hasLength(2));
        // Still exactly one entry — no duplicate remote record.
        expect(handler.remoteProcessedIds, hasLength(1));

        final syncedResult = await outboxRepository.listByStatus(
          organizationId: 'org-1',
          statuses: const <OutboxStatus>[OutboxStatus.synced],
        );
        expect(
          (syncedResult as AppSuccess<List<OutboxOperation>>).value,
          hasLength(1),
        );
      },
    );

    test('an operation orphaned in syncing by a previous interrupted run is '
        'recovered and retried, never left corrupted', () async {
      final now = DateTime.utc(2026, 1, 1);
      await outboxRepository.enqueue(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: const <String, dynamic>{},
        createdAt: now,
        createdBy: 'seller-1',
      );
      // Simulate a previous run that crashed right after markSyncing, before
      // any push handler response ever arrived.
      await outboxRepository.markSyncing(id: 'op-1', attemptedAt: now);

      final handler = _FakePushHandler(OutboxEntityType.order);
      // A zero backoff makes the recovered operation immediately eligible
      // again within this same call — the backoff window itself is already
      // covered by the dedicated retry/backoff test above.
      final engine = buildEngine(
        pushHandlers: [handler],
        retryPolicy: const SyncRetryPolicy(baseDelay: Duration.zero),
      );

      final report = await engine.runPush(
        organizationId: 'org-1',
        now: now.add(const Duration(seconds: 1)),
      );

      expect(report.synced, 1);
      expect(handler.pushCalls, hasLength(1));

      final result = await outboxRepository.listByStatus(
        organizationId: 'org-1',
        statuses: const <OutboxStatus>[OutboxStatus.synced],
      );
      final operations = (result as AppSuccess<List<OutboxOperation>>).value;
      // Exactly one row, never duplicated by the recovery path.
      expect(operations, hasLength(1));
      expect(operations.single.id, 'op-1');
    });
  });

  group('SyncEngine.runPull', () {
    late AppDatabase database;
    late DriftOutboxRepository outboxRepository;
    late DriftSyncCursorRepository syncCursorRepository;
    late FakeAnalyticsService analyticsService;
    late _RecordingCrashReporter crashReporter;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      outboxRepository = DriftOutboxRepository(database);
      syncCursorRepository = DriftSyncCursorRepository(database);
      analyticsService = FakeAnalyticsService();
      crashReporter = _RecordingCrashReporter();
    });

    tearDown(() async {
      await database.close();
    });

    SyncEngine buildEngine({
      List<SyncPushHandler> pushHandlers = const [],
      required List<SyncPullSource> pullSources,
    }) {
      return SyncEngine(
        outboxRepository,
        syncCursorRepository,
        pushHandlers,
        pullSources,
        analyticsService,
        crashReporter,
      );
    }

    test(
      'applies only records after the cursor and advances it on success',
      () async {
        final source = _FakeSyncPullSource(OfflinePackageEntityKind.customers);
        final engine = buildEngine(pullSources: [source]);

        source.enqueuePage(
          AppSuccess<SyncPullPage>(
            SyncPullPage(
              records: [
                SyncPullRecord(
                  entityId: 'customer-1',
                  organizationId: 'org-1',
                  companyId: 'company-1',
                  updatedAt: DateTime.utc(2026, 1, 1),
                  data: const <String, dynamic>{'name': 'Loja A'},
                ),
              ],
              nextCursor: '2026-01-01T00:00:00.000Z',
            ),
          ),
        );

        final firstReport = await engine.runPull(
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        expect(firstReport.applied, 1);
        expect(source.applied.single.entityId, 'customer-1');
        expect(source.fetchCursors.single, isNull);

        final cursorResult = await syncCursorRepository.getCursor(
          organizationId: 'org-1',
          companyId: 'company-1',
          kind: OfflinePackageEntityKind.customers,
        );
        expect(
          (cursorResult as AppSuccess<SyncCursor?>).value!.cursorValue,
          '2026-01-01T00:00:00.000Z',
        );

        // Second cycle: the source only returns records after that cursor —
        // simulated here by an empty page, proving the engine asked for
        // exactly the persisted cursor rather than refetching everything.
        source.enqueuePage(
          const AppSuccess<SyncPullPage>(SyncPullPage(records: [])),
        );
        final secondReport = await engine.runPull(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        expect(secondReport.applied, 0);
        expect(source.fetchCursors.last, '2026-01-01T00:00:00.000Z');
      },
    );

    test('rejects a cross-tenant record without applying it or advancing '
        'the cursor', () async {
      final source = _FakeSyncPullSource(OfflinePackageEntityKind.customers);
      final engine = buildEngine(pullSources: [source]);

      source.enqueuePage(
        AppSuccess<SyncPullPage>(
          SyncPullPage(
            records: [
              SyncPullRecord(
                entityId: 'customer-from-other-org',
                organizationId: 'org-2',
                companyId: 'company-2',
                updatedAt: DateTime.utc(2026, 1, 1),
                data: const <String, dynamic>{},
              ),
            ],
            nextCursor: '2026-01-01T00:00:00.000Z',
          ),
        ),
      );

      final report = await engine.runPull(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(report.rejectedCrossTenant, 1);
      expect(report.applied, 0);
      expect(source.applied, isEmpty);

      final cursorResult = await syncCursorRepository.getCursor(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
      );
      expect((cursorResult as AppSuccess<SyncCursor?>).value, isNull);
      expect(crashReporter.recordedErrors, isNotEmpty);
    });

    test(
      'skips a record whose entity has a pending Outbox operation, '
      'never overwriting it, and does not advance the cursor past it',
      () async {
        final now = DateTime.utc(2026, 1, 1);
        await outboxRepository.enqueue(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.customer,
          entityId: 'customer-1',
          operationType: OutboxOperationType.update,
          payload: const <String, dynamic>{},
          createdAt: now,
          createdBy: 'seller-1',
        );

        final source = _FakeSyncPullSource(OfflinePackageEntityKind.customers);
        final engine = buildEngine(pullSources: [source]);

        source.enqueuePage(
          AppSuccess<SyncPullPage>(
            SyncPullPage(
              records: [
                SyncPullRecord(
                  entityId: 'customer-1',
                  organizationId: 'org-1',
                  companyId: 'company-1',
                  updatedAt: now,
                  data: const <String, dynamic>{'name': 'Remote value'},
                ),
              ],
              nextCursor: now.toIso8601String(),
            ),
          ),
        );

        final report = await engine.runPull(
          organizationId: 'org-1',
          companyId: 'company-1',
          now: now,
        );

        expect(report.skipped, 1);
        expect(report.applied, 0);
        expect(source.applied, isEmpty);

        final cursorResult = await syncCursorRepository.getCursor(
          organizationId: 'org-1',
          companyId: 'company-1',
          kind: OfflinePackageEntityKind.customers,
        );
        expect((cursorResult as AppSuccess<SyncCursor?>).value, isNull);
      },
    );

    test(
      'a failed fetch leaves the cursor untouched for a later retry',
      () async {
        final source = _FakeSyncPullSource(OfflinePackageEntityKind.customers);
        final engine = buildEngine(pullSources: [source]);

        source.enqueuePage(
          const AppFailure<SyncPullPage>(
            ServerFailure('Firestore unreachable', code: 'unavailable'),
          ),
        );

        final report = await engine.runPull(
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        expect(report.sourcesFailed, 1);
        expect(report.applied, 0);

        final cursorResult = await syncCursorRepository.getCursor(
          organizationId: 'org-1',
          companyId: 'company-1',
          kind: OfflinePackageEntityKind.customers,
        );
        expect((cursorResult as AppSuccess<SyncCursor?>).value, isNull);
      },
    );
  });

  group('SyncEngine.runFullCycle', () {
    test('runs push before pull and returns both reports', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final outboxRepository = DriftOutboxRepository(database);
      final syncCursorRepository = DriftSyncCursorRepository(database);
      final analyticsService = FakeAnalyticsService();
      final crashReporter = _RecordingCrashReporter();

      final now = DateTime.utc(2026, 1, 1);
      await outboxRepository.enqueue(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: const <String, dynamic>{},
        createdAt: now,
        createdBy: 'seller-1',
      );

      final pushHandler = _FakePushHandler(OutboxEntityType.order);
      final pullSource = _FakeSyncPullSource(
        OfflinePackageEntityKind.customers,
      );
      final engine = SyncEngine(
        outboxRepository,
        syncCursorRepository,
        [pushHandler],
        [pullSource],
        analyticsService,
        crashReporter,
      );

      final report = await engine.runFullCycle(
        organizationId: 'org-1',
        companyId: 'company-1',
        now: now,
      );

      expect(report.push.synced, 1);
      expect(report.pull.sourcesProcessed, 1);
      expect(pushHandler.pushCalls, hasLength(1));
      expect(pullSource.fetchCursors, hasLength(1));
    });
  });
}
