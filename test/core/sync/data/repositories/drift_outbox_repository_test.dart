import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('DriftOutboxRepository', () {
    late AppDatabase database;
    late DriftOutboxRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftOutboxRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'enqueue persists the operation and decodes its payload back',
      () async {
        final now = DateTime.utc(2026, 1, 1);

        final result = await repository.enqueue(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
          operationType: OutboxOperationType.create,
          payload: <String, dynamic>{'total': 10, 'items': 2},
          createdAt: now,
          createdBy: 'seller-1',
        );

        expect(result, isA<AppSuccess<OutboxOperation>>());
        final operation = (result as AppSuccess<OutboxOperation>).value;
        expect(operation.status, OutboxStatus.pending);
        expect(operation.entityType, OutboxEntityType.order);
        expect(operation.operationType, OutboxOperationType.create);
        expect(operation.payload, <String, dynamic>{'total': 10, 'items': 2});
        expect(operation.clientOperationId, 'op-1');
      },
    );

    test('enqueue is idempotent: retrying the same clientOperationId returns '
        'the same operation instead of a logical duplicate', () async {
      final now = DateTime.utc(2026, 1, 1);

      final first = await repository.enqueue(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: <String, dynamic>{'total': 10},
        createdAt: now,
        createdBy: 'seller-1',
      );
      final retry = await repository.enqueue(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: <String, dynamic>{'total': 10},
        createdAt: now.add(const Duration(minutes: 10)),
        createdBy: 'seller-1',
      );

      final firstOperation = (first as AppSuccess<OutboxOperation>).value;
      final retryOperation = (retry as AppSuccess<OutboxOperation>).value;
      expect(retryOperation.sequenceNumber, firstOperation.sequenceNumber);
      expect(retryOperation.createdAt, firstOperation.createdAt);

      final listResult = await repository.listByStatus(
        organizationId: 'org-1',
        statuses: const <OutboxStatus>[OutboxStatus.pending],
      );
      final operations =
          (listResult as AppSuccess<List<OutboxOperation>>).value;
      expect(operations, hasLength(1));
    });

    test('listByEntity preserves creation order across create/update for the '
        'same entity', () async {
      final now = DateTime.utc(2026, 1, 1);
      await repository.enqueue(
        id: 'op-create',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: <String, dynamic>{},
        createdAt: now,
        createdBy: 'seller-1',
      );
      await repository.enqueue(
        id: 'op-update',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.update,
        payload: <String, dynamic>{},
        createdAt: now.add(const Duration(seconds: 1)),
        createdBy: 'seller-1',
      );

      final result = await repository.listByEntity(
        organizationId: 'org-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
      );
      final operations = (result as AppSuccess<List<OutboxOperation>>).value;

      expect(operations.map((operation) => operation.id), <String>[
        'op-create',
        'op-update',
      ]);
    });

    test(
      'markSyncing -> markSynced and markSyncing -> markFailed -> markSyncing '
      '(retry) transition through the expected states',
      () async {
        final now = DateTime.utc(2026, 1, 1);
        await repository.enqueue(
          id: 'op-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.crmActivity,
          entityId: 'activity-1',
          operationType: OutboxOperationType.create,
          payload: <String, dynamic>{},
          createdAt: now,
          createdBy: 'seller-1',
        );

        await repository.markSyncing(id: 'op-1', attemptedAt: now);
        await repository.markSynced(id: 'op-1');

        final syncedResult = await repository.listByStatus(
          organizationId: 'org-1',
          statuses: const <OutboxStatus>[OutboxStatus.synced],
        );
        expect(
          (syncedResult as AppSuccess<List<OutboxOperation>>).value,
          hasLength(1),
        );

        await repository.enqueue(
          id: 'op-2',
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.crmActivity,
          entityId: 'activity-2',
          operationType: OutboxOperationType.create,
          payload: <String, dynamic>{},
          createdAt: now,
          createdBy: 'seller-1',
        );
        await repository.markSyncing(id: 'op-2', attemptedAt: now);
        await repository.markFailed(
          id: 'op-2',
          error: 'network timeout',
          attemptedAt: now,
        );
        await repository.markSyncing(
          id: 'op-2',
          attemptedAt: now.add(const Duration(seconds: 5)),
        );

        final syncingResult = await repository.listByStatus(
          organizationId: 'org-1',
          statuses: const <OutboxStatus>[OutboxStatus.syncing],
        );
        final syncingOperations =
            (syncingResult as AppSuccess<List<OutboxOperation>>).value;
        expect(syncingOperations.single.id, 'op-2');
        expect(syncingOperations.single.attemptCount, 2);
      },
    );

    test('markConflict records the error and moves the operation out of '
        'the retry path', () async {
      final now = DateTime.utc(2026, 1, 1);
      await repository.enqueue(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.customer,
        entityId: 'customer-1',
        operationType: OutboxOperationType.update,
        payload: <String, dynamic>{},
        createdAt: now,
        createdBy: 'seller-1',
      );

      await repository.markConflict(
        id: 'op-1',
        error: 'stale version',
        attemptedAt: now,
      );

      final result = await repository.listByStatus(
        organizationId: 'org-1',
        statuses: const <OutboxStatus>[OutboxStatus.conflict],
      );
      final operations = (result as AppSuccess<List<OutboxOperation>>).value;
      expect(operations.single.lastError, 'stale version');
    });

    test('watchSummary reactively reflects pending/failed counts', () async {
      final now = DateTime.utc(2026, 1, 1);
      final emissions = <OutboxSummary>[];
      final subscription = repository
          .watchSummary(organizationId: 'org-1')
          .listen(emissions.add);
      addTearDown(subscription.cancel);

      await repository.enqueue(
        id: 'op-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        operationType: OutboxOperationType.create,
        payload: <String, dynamic>{},
        createdAt: now,
        createdBy: 'seller-1',
      );
      await repository.markSyncing(id: 'op-1', attemptedAt: now);
      await repository.markFailed(id: 'op-1', error: 'boom', attemptedAt: now);

      await pumpEventQueue();

      expect(emissions, isNotEmpty);
      expect(emissions.last.failedCount, 1);
      expect(emissions.last.pendingCount, 0);
      expect(emissions.last.hasFailuresOrConflicts, isTrue);
    });
  });
}
