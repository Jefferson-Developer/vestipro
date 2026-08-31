import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

void main() {
  group('AppDatabase Outbox (TASK-108)', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('enqueueOutboxOperation persists a pending row with an increasing '
        'sequenceNumber', () async {
      final now = DateTime.utc(2026, 1, 1);

      final first = await database.enqueueOutboxOperation(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: 'order',
        entityId: 'order-1',
        operationType: 'create',
        payload: '{"total":10}',
        createdAt: now,
        createdBy: 'seller-1',
      );
      final second = await database.enqueueOutboxOperation(
        id: 'op-2',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: 'order',
        entityId: 'order-1',
        operationType: 'update',
        payload: '{"total":20}',
        createdAt: now.add(const Duration(seconds: 1)),
        createdBy: 'seller-1',
      );

      expect(first.status, 'pending');
      expect(first.attemptCount, 0);
      expect(second.sequenceNumber, greaterThan(first.sequenceNumber));
    });

    test(
      'enqueue is idempotent: reusing the same id (clientOperationId) does '
      'not create a duplicate row nor change the stored sequenceNumber',
      () async {
        final now = DateTime.utc(2026, 1, 1);

        final first = await database.enqueueOutboxOperation(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: 'order',
          entityId: 'order-1',
          operationType: 'create',
          payload: '{"total":10}',
          createdAt: now,
          createdBy: 'seller-1',
        );

        final retry = await database.enqueueOutboxOperation(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: 'order',
          entityId: 'order-1',
          operationType: 'create',
          payload: '{"total":10}',
          createdAt: now.add(const Duration(minutes: 5)),
          createdBy: 'seller-1',
        );

        expect(retry.sequenceNumber, first.sequenceNumber);
        expect(retry.createdAt, first.createdAt);

        final allRows = await database.select(database.outboxTable).get();
        expect(allRows, hasLength(1));
      },
    );

    test('getOutboxOperationsByEntity returns operations for the same entity '
        'in creation order (create before update)', () async {
      final now = DateTime.utc(2026, 1, 1);

      await database.enqueueOutboxOperation(
        id: 'op-update',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: 'order',
        entityId: 'order-1',
        operationType: 'update',
        payload: '{"total":20}',
        createdAt: now.add(const Duration(seconds: 5)),
        createdBy: 'seller-1',
      );
      // Enqueued second on purpose: exercises that ordering follows
      // sequenceNumber (insertion order), never createdAt/id ordering.
      await database.enqueueOutboxOperation(
        id: 'op-create',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: 'order',
        entityId: 'order-1',
        operationType: 'create',
        payload: '{"total":10}',
        createdAt: now,
        createdBy: 'seller-1',
      );

      final operations = await database.getOutboxOperationsByEntity(
        organizationId: 'org-1',
        entityType: 'order',
        entityId: 'order-1',
      );

      expect(operations.map((row) => row.id), <String>[
        'op-update',
        'op-create',
      ]);
    });

    test('status transitions: pending -> syncing -> synced, and '
        'pending -> syncing -> failed -> syncing (retry)', () async {
      final createdAt = DateTime.utc(2026, 1, 1);

      await database.enqueueOutboxOperation(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: 'order',
        entityId: 'order-1',
        operationType: 'create',
        payload: '{}',
        createdAt: createdAt,
        createdBy: 'seller-1',
      );

      await database.markOutboxSyncing(
        id: 'op-1',
        attemptedAt: createdAt.add(const Duration(seconds: 1)),
      );
      var row = await database.getOutboxOperationById('op-1');
      expect(row?.status, 'syncing');
      expect(row?.attemptCount, 1);

      await database.markOutboxSynced(id: 'op-1');
      row = await database.getOutboxOperationById('op-1');
      expect(row?.status, 'synced');

      // Second operation exercises the failure -> retry path.
      await database.enqueueOutboxOperation(
        id: 'op-2',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: 'order',
        entityId: 'order-2',
        operationType: 'create',
        payload: '{}',
        createdAt: createdAt,
        createdBy: 'seller-1',
      );
      await database.markOutboxSyncing(
        id: 'op-2',
        attemptedAt: createdAt.add(const Duration(seconds: 1)),
      );
      await database.markOutboxFailed(
        id: 'op-2',
        error: 'network timeout',
        attemptedAt: createdAt.add(const Duration(seconds: 2)),
      );
      row = await database.getOutboxOperationById('op-2');
      expect(row?.status, 'failed');
      expect(row?.lastError, 'network timeout');
      expect(row?.attemptCount, 1);

      await database.markOutboxSyncing(
        id: 'op-2',
        attemptedAt: createdAt.add(const Duration(seconds: 3)),
      );
      row = await database.getOutboxOperationById('op-2');
      expect(row?.status, 'syncing');
      expect(row?.attemptCount, 2);
    });

    test(
      'markOutboxConflict records the error and moves to conflict',
      () async {
        final createdAt = DateTime.utc(2026, 1, 1);
        await database.enqueueOutboxOperation(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: 'order',
          entityId: 'order-1',
          operationType: 'update',
          payload: '{}',
          createdAt: createdAt,
          createdBy: 'seller-1',
        );

        await database.markOutboxConflict(
          id: 'op-1',
          error: 'stale version',
          attemptedAt: createdAt.add(const Duration(seconds: 1)),
        );

        final row = await database.getOutboxOperationById('op-1');
        expect(row?.status, 'conflict');
        expect(row?.lastError, 'stale version');
      },
    );

    test(
      'getOutboxOperationsByStatus filters by scope and requested statuses',
      () async {
        final now = DateTime.utc(2026, 1, 1);

        await database.enqueueOutboxOperation(
          id: 'op-pending',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: 'order',
          entityId: 'order-1',
          operationType: 'create',
          payload: '{}',
          createdAt: now,
          createdBy: 'seller-1',
        );
        await database.enqueueOutboxOperation(
          id: 'op-other-org',
          organizationId: 'org-2',
          companyId: 'company-2',
          entityType: 'order',
          entityId: 'order-9',
          operationType: 'create',
          payload: '{}',
          createdAt: now,
          createdBy: 'seller-1',
        );
        await database.enqueueOutboxOperation(
          id: 'op-failed',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: 'crm_activity',
          entityId: 'activity-1',
          operationType: 'create',
          payload: '{}',
          createdAt: now,
          createdBy: 'seller-1',
        );
        await database.markOutboxSyncing(id: 'op-failed', attemptedAt: now);
        await database.markOutboxFailed(
          id: 'op-failed',
          error: 'boom',
          attemptedAt: now,
        );

        final pendingOrFailed = await database.getOutboxOperationsByStatus(
          organizationId: 'org-1',
          statuses: const <String>['pending', 'failed'],
        );

        expect(pendingOrFailed.map((row) => row.id).toSet(), <String>{
          'op-pending',
          'op-failed',
        });
      },
    );

    test(
      'watchOutboxStatusCounts reactively reflects status transitions',
      () async {
        final now = DateTime.utc(2026, 1, 1);
        final emissions = <OutboxStatusCounts>[];
        final subscription = database
            .watchOutboxStatusCounts(organizationId: 'org-1')
            .listen(emissions.add);
        addTearDown(subscription.cancel);

        await database.enqueueOutboxOperation(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: 'order',
          entityId: 'order-1',
          operationType: 'create',
          payload: '{}',
          createdAt: now,
          createdBy: 'seller-1',
        );
        await database.markOutboxSyncing(id: 'op-1', attemptedAt: now);
        await database.markOutboxFailed(
          id: 'op-1',
          error: 'boom',
          attemptedAt: now,
        );

        await pumpEventQueue();

        expect(emissions, isNotEmpty);
        expect(emissions.last.failed, 1);
        expect(emissions.last.pending, 0);
        expect(emissions.last.syncing, 0);
      },
    );

    test(
      'Outbox rows survive closing and reopening the same on-disk database',
      () async {
        final seedFile = File(
          '${Directory.systemTemp.path}${Platform.pathSeparator}'
          'vestipro_task108_outbox_${DateTime.now().microsecondsSinceEpoch}.sqlite',
        );
        addTearDown(() async {
          if (seedFile.existsSync()) seedFile.deleteSync();
        });

        final firstOpen = AppDatabase(NativeDatabase(seedFile));
        await firstOpen.enqueueOutboxOperation(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: 'order',
          entityId: 'order-1',
          operationType: 'create',
          payload: '{"total":10}',
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'seller-1',
        );
        await firstOpen.close();

        final reopened = AppDatabase(NativeDatabase(seedFile));
        addTearDown(reopened.close);

        final row = await reopened.getOutboxOperationById('op-1');
        expect(row, isNotNull);
        expect(row?.status, 'pending');
        expect(row?.payload, '{"total":10}');
      },
    );
  });
}
