import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('ConflictResolutionService', () {
    late AppDatabase database;
    late DriftOutboxRepository outboxRepository;
    late DriftConflictRecordRepository conflictRecordRepository;
    late DriftConflictAuditLogRepository conflictAuditLogRepository;
    late ConflictResolutionService service;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      outboxRepository = DriftOutboxRepository(database);
      conflictRecordRepository = DriftConflictRecordRepository(database);
      conflictAuditLogRepository = DriftConflictAuditLogRepository(database);
      service = ConflictResolutionService(
        conflictRecordRepository,
        conflictAuditLogRepository,
        outboxRepository,
      );
    });

    tearDown(() async {
      await database.close();
    });

    Future<String> enqueueOutboxOperation({
      required OutboxEntityType entityType,
      required String entityId,
      String id = 'op-1',
    }) async {
      await outboxRepository.enqueue(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        entityType: entityType,
        entityId: entityId,
        operationType: OutboxOperationType.update,
        payload: const <String, dynamic>{},
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'seller-1',
      );
      return id;
    }

    group('divergence detection', () {
      test(
        'a timestamp-only difference with identical fields is not a real '
        'conflict (noop), and is still recorded in the audit trail',
        () async {
          final opId = await enqueueOutboxOperation(
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
          );

          final outcome = await service.resolve(
            organizationId: 'org-1',
            companyId: 'company-1',
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
            outboxOperationId: opId,
            local: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Visita realizada'},
              updatedAt: DateTime.utc(2026, 1, 1, 10),
            ),
            remote: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Visita realizada'},
              updatedAt: DateTime.utc(2026, 1, 1, 11),
            ),
          );

          expect(outcome, isA<ConflictResolutionNoop>());

          final audit = await conflictAuditLogRepository.listByOrganization(
            organizationId: 'org-1',
          );
          final entries = (audit as AppSuccess<List<ConflictAuditEntry>>).value;
          expect(entries, hasLength(1));
          expect(entries.single.outcome, ConflictAuditOutcome.noop);

          final openConflicts = await conflictRecordRepository.listOpen(
            organizationId: 'org-1',
          );
          expect(
            (openConflicts as AppSuccess<List<ConflictRecord>>).value,
            isEmpty,
          );
        },
      );
    });

    group('lastWriteWins (crmActivity)', () {
      test(
        'the more recent remote value wins, discarding the local one',
        () async {
          final opId = await enqueueOutboxOperation(
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
          );

          final outcome = await service.resolve(
            organizationId: 'org-1',
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
            outboxOperationId: opId,
            local: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Nota local'},
              updatedAt: DateTime.utc(2026, 1, 1, 10),
            ),
            remote: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Nota remota'},
              updatedAt: DateTime.utc(2026, 1, 1, 12),
            ),
          );

          expect(outcome, isA<ConflictResolutionAppliedRemote>());
          expect(
            (outcome as ConflictResolutionAppliedRemote).remoteData['note'],
            'Nota remota',
          );

          final audit = await conflictAuditLogRepository.listByOrganization(
            organizationId: 'org-1',
          );
          final entry =
              (audit as AppSuccess<List<ConflictAuditEntry>>).value.single;
          expect(entry.outcome, ConflictAuditOutcome.appliedRemote);
          expect(entry.discardedFields, contains('note'));

          // Never touches the Outbox row for an automatic, safe policy.
          final outboxOps = await outboxRepository.listByStatus(
            organizationId: 'org-1',
            statuses: const [OutboxStatus.conflict],
          );
          expect(
            (outboxOps as AppSuccess<List<OutboxOperation>>).value,
            isEmpty,
          );
        },
      );

      test(
        'a more recent local value wins, keeping the local pending write',
        () async {
          final opId = await enqueueOutboxOperation(
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
          );

          final outcome = await service.resolve(
            organizationId: 'org-1',
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
            outboxOperationId: opId,
            local: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Nota local'},
              updatedAt: DateTime.utc(2026, 1, 1, 12),
            ),
            remote: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Nota remota'},
              updatedAt: DateTime.utc(2026, 1, 1, 10),
            ),
          );

          expect(outcome, isA<ConflictResolutionAppliedLocal>());

          final audit = await conflictAuditLogRepository.listByOrganization(
            organizationId: 'org-1',
          );
          final entry =
              (audit as AppSuccess<List<ConflictAuditEntry>>).value.single;
          expect(entry.outcome, ConflictAuditOutcome.appliedLocal);
        },
      );

      test('an exact tie (same updatedAt, no version) is resolved '
          'deterministically in favor of the remote value', () async {
        final opId = await enqueueOutboxOperation(
          entityType: OutboxEntityType.crmActivity,
          entityId: 'activity-1',
        );
        final tie = DateTime.utc(2026, 1, 1, 10);

        final outcome = await service.resolve(
          organizationId: 'org-1',
          entityType: OutboxEntityType.crmActivity,
          entityId: 'activity-1',
          outboxOperationId: opId,
          local: ConflictSnapshot(
            data: const <String, Object?>{'note': 'Nota local'},
            updatedAt: tie,
          ),
          remote: ConflictSnapshot(
            data: const <String, Object?>{'note': 'Nota remota'},
            updatedAt: tie,
          ),
        );

        expect(outcome, isA<ConflictResolutionAppliedRemote>());
      });

      test(
        'version, when present on both sides, is preferred over updatedAt',
        () async {
          final opId = await enqueueOutboxOperation(
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
          );

          // Local has a *newer* wall-clock timestamp but an *older* version —
          // version must win, proving updatedAt alone is not authoritative.
          final outcome = await service.resolve(
            organizationId: 'org-1',
            entityType: OutboxEntityType.crmActivity,
            entityId: 'activity-1',
            outboxOperationId: opId,
            local: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Nota local'},
              updatedAt: DateTime.utc(2026, 1, 1, 12),
              version: 1,
            ),
            remote: ConflictSnapshot(
              data: const <String, Object?>{'note': 'Nota remota'},
              updatedAt: DateTime.utc(2026, 1, 1, 10),
              version: 2,
            ),
          );

          expect(outcome, isA<ConflictResolutionAppliedRemote>());
        },
      );
    });

    group('fieldMerge (customer)', () {
      test(
        'changes in distinct fields are merged automatically, without '
        'creating a ConflictRecord or blocking the Outbox operation',
        () async {
          final opId = await enqueueOutboxOperation(
            entityType: OutboxEntityType.customer,
            entityId: 'customer-1',
          );

          final outcome = await service.resolve(
            organizationId: 'org-1',
            entityType: OutboxEntityType.customer,
            entityId: 'customer-1',
            outboxOperationId: opId,
            base: ConflictSnapshot(
              data: const <String, Object?>{
                'phone': '1111-1111',
                'address': 'Rua A, 100',
              },
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
            local: ConflictSnapshot(
              data: const <String, Object?>{
                'phone': '1111-1111',
                'address': 'Rua B, 200',
              },
              updatedAt: DateTime.utc(2026, 1, 2),
            ),
            remote: ConflictSnapshot(
              data: const <String, Object?>{
                'phone': '2222-2222',
                'address': 'Rua A, 100',
              },
              updatedAt: DateTime.utc(2026, 1, 2),
            ),
          );

          expect(outcome, isA<ConflictResolutionMerged>());
          final merged = outcome as ConflictResolutionMerged;
          expect(merged.mergedData['phone'], '2222-2222');
          expect(merged.mergedData['address'], 'Rua B, 200');
          expect(merged.mergedFields, {'address'});

          final openConflicts = await conflictRecordRepository.listOpen(
            organizationId: 'org-1',
          );
          expect(
            (openConflicts as AppSuccess<List<ConflictRecord>>).value,
            isEmpty,
          );

          final conflictOps = await outboxRepository.listByStatus(
            organizationId: 'org-1',
            statuses: const [OutboxStatus.conflict],
          );
          expect(
            (conflictOps as AppSuccess<List<OutboxOperation>>).value,
            isEmpty,
          );

          final audit = await conflictAuditLogRepository.listByOrganization(
            organizationId: 'org-1',
          );
          expect(
            (audit as AppSuccess<List<ConflictAuditEntry>>)
                .value
                .single
                .outcome,
            ConflictAuditOutcome.merged,
          );
        },
      );

      test('the same field changed on both sides blocks for manual resolution '
          'instead of merging silently', () async {
        final opId = await enqueueOutboxOperation(
          entityType: OutboxEntityType.customer,
          entityId: 'customer-1',
        );

        final outcome = await service.resolve(
          organizationId: 'org-1',
          entityType: OutboxEntityType.customer,
          entityId: 'customer-1',
          outboxOperationId: opId,
          base: ConflictSnapshot(
            data: const <String, Object?>{'phone': '1111-1111'},
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          local: ConflictSnapshot(
            data: const <String, Object?>{'phone': '2222-2222'},
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
          remote: ConflictSnapshot(
            data: const <String, Object?>{'phone': '3333-3333'},
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
        );

        expect(outcome, isA<ConflictResolutionBlockedManual>());
        final blocked = outcome as ConflictResolutionBlockedManual;
        expect(blocked.conflictingFields, {'phone'});

        final record = await conflictRecordRepository.getById(
          blocked.conflictRecordId,
        );
        final persisted = (record as AppSuccess<ConflictRecord?>).value;
        expect(persisted, isNotNull);
        expect(persisted!.policy, ConflictPolicy.fieldMerge);
        expect(persisted.localSnapshot['phone'], '2222-2222');
        expect(persisted.remoteSnapshot['phone'], '3333-3333');
        expect(persisted.status, ConflictRecordStatus.conflict);

        final conflictOps = await outboxRepository.listByStatus(
          organizationId: 'org-1',
          statuses: const [OutboxStatus.conflict],
        );
        expect(
          (conflictOps as AppSuccess<List<OutboxOperation>>).value.map(
            (op) => op.id,
          ),
          contains(opId),
        );
      });

      test('without a base snapshot, fieldMerge falls back to manual '
          'resolution rather than guessing a merge', () async {
        final opId = await enqueueOutboxOperation(
          entityType: OutboxEntityType.customer,
          entityId: 'customer-1',
        );

        final outcome = await service.resolve(
          organizationId: 'org-1',
          entityType: OutboxEntityType.customer,
          entityId: 'customer-1',
          outboxOperationId: opId,
          local: ConflictSnapshot(
            data: const <String, Object?>{'phone': '1111-1111'},
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          remote: ConflictSnapshot(
            data: const <String, Object?>{'phone': '2222-2222'},
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
        );

        expect(outcome, isA<ConflictResolutionBlockedManual>());
      });
    });

    group('manualResolution (order)', () {
      test('a diverging order always blocks for manual resolution, persisting '
          'both snapshots and never applying anything automatically', () async {
        final opId = await enqueueOutboxOperation(
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
        );

        final localData = <String, Object?>{
          'discount': 0.1,
          'paymentTermId': 'term-30d',
        };
        final remoteData = <String, Object?>{
          'discount': 0.15,
          'paymentTermId': 'term-30d',
        };

        final outcome = await service.resolve(
          organizationId: 'org-1',
          companyId: 'company-1',
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
          outboxOperationId: opId,
          local: ConflictSnapshot(
            data: localData,
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
          remote: ConflictSnapshot(
            data: remoteData,
            updatedAt: DateTime.utc(2026, 1, 2),
          ),
        );

        expect(outcome, isA<ConflictResolutionBlockedManual>());
        final blocked = outcome as ConflictResolutionBlockedManual;
        expect(blocked.conflictingFields, {'discount'});

        final openConflicts = await conflictRecordRepository.listOpen(
          organizationId: 'org-1',
        );
        final records =
            (openConflicts as AppSuccess<List<ConflictRecord>>).value;
        expect(records, hasLength(1));
        expect(records.single.entityType, OutboxEntityType.order);
        expect(records.single.policy, ConflictPolicy.manualResolution);
        expect(records.single.localSnapshot, localData);
        expect(records.single.remoteSnapshot, remoteData);
        expect(records.single.status, ConflictRecordStatus.conflict);
        expect(records.single.outboxOperationId, opId);

        final conflictOps = await outboxRepository.listByStatus(
          organizationId: 'org-1',
          statuses: const [OutboxStatus.conflict],
        );
        expect(
          (conflictOps as AppSuccess<List<OutboxOperation>>).value.map(
            (op) => op.id,
          ),
          contains(opId),
        );

        final audit = await conflictAuditLogRepository.listByOrganization(
          organizationId: 'org-1',
        );
        final entry =
            (audit as AppSuccess<List<ConflictAuditEntry>>).value.single;
        expect(entry.outcome, ConflictAuditOutcome.blockedManual);
        expect(entry.conflictRecordId, blocked.conflictRecordId);
      });

      test('resolving the same still-open conflict again never creates a '
          'duplicate ConflictRecord for the same Outbox operation', () async {
        final opId = await enqueueOutboxOperation(
          entityType: OutboxEntityType.order,
          entityId: 'order-1',
        );

        Future<ConflictResolutionOutcome> attempt() {
          return service.resolve(
            organizationId: 'org-1',
            entityType: OutboxEntityType.order,
            entityId: 'order-1',
            outboxOperationId: opId,
            local: ConflictSnapshot(
              data: const <String, Object?>{'discount': 0.1},
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
            remote: ConflictSnapshot(
              data: const <String, Object?>{'discount': 0.15},
              updatedAt: DateTime.utc(2026, 1, 2),
            ),
          );
        }

        final first = await attempt() as ConflictResolutionBlockedManual;
        final second = await attempt() as ConflictResolutionBlockedManual;

        expect(second.conflictRecordId, first.conflictRecordId);

        final openConflicts = await conflictRecordRepository.listOpen(
          organizationId: 'org-1',
        );
        expect(
          (openConflicts as AppSuccess<List<ConflictRecord>>).value,
          hasLength(1),
        );
      });
    });
  });
}
