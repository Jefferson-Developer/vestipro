import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('DriftConflictRecordRepository', () {
    late AppDatabase database;
    late DriftConflictRecordRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftConflictRecordRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    ConflictRecord buildRecord({
      String id = 'conflict-1',
      String organizationId = 'org-1',
      String outboxOperationId = 'op-1',
      DateTime? detectedAt,
    }) {
      return ConflictRecord(
        id: id,
        organizationId: organizationId,
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        outboxOperationId: outboxOperationId,
        policy: ConflictPolicy.manualResolution,
        localSnapshot: const <String, Object?>{'discount': 0.1},
        remoteSnapshot: const <String, Object?>{'discount': 0.15},
        conflictingFields: const ['discount'],
        status: ConflictRecordStatus.conflict,
        detectedAt: detectedAt ?? DateTime.utc(2026, 1, 1),
      );
    }

    test('create persists and decodes both snapshots back exactly', () async {
      final result = await repository.create(buildRecord());

      expect(result, isA<AppSuccess<ConflictRecord>>());
      final record = (result as AppSuccess<ConflictRecord>).value;
      expect(record.localSnapshot, <String, Object?>{'discount': 0.1});
      expect(record.remoteSnapshot, <String, Object?>{'discount': 0.15});
      expect(record.conflictingFields, ['discount']);
      expect(record.status, ConflictRecordStatus.conflict);
    });

    test(
      'create is idempotent per outboxOperationId: a second call for the '
      'same still-open operation returns the existing record unchanged',
      () async {
        final first = await repository.create(buildRecord());
        final second = await repository.create(
          buildRecord(id: 'conflict-2', detectedAt: DateTime.utc(2026, 2, 1)),
        );

        final firstRecord = (first as AppSuccess<ConflictRecord>).value;
        final secondRecord = (second as AppSuccess<ConflictRecord>).value;
        expect(secondRecord.id, firstRecord.id);
        expect(secondRecord.detectedAt, firstRecord.detectedAt);

        final open = await repository.listOpen(organizationId: 'org-1');
        expect((open as AppSuccess<List<ConflictRecord>>).value, hasLength(1));
      },
    );

    test(
      'listOpen returns only conflict-status records, oldest first',
      () async {
        await repository.create(
          buildRecord(
            id: 'conflict-1',
            outboxOperationId: 'op-1',
            detectedAt: DateTime.utc(2026, 1, 2),
          ),
        );
        await repository.create(
          buildRecord(
            id: 'conflict-2',
            outboxOperationId: 'op-2',
            detectedAt: DateTime.utc(2026, 1, 1),
          ),
        );

        final result = await repository.listOpen(organizationId: 'org-1');
        final records = (result as AppSuccess<List<ConflictRecord>>).value;
        expect(records.map((r) => r.id), ['conflict-2', 'conflict-1']);
      },
    );

    test('listOpen never returns records from another organization', () async {
      await repository.create(buildRecord());
      await repository.create(
        buildRecord(
          id: 'conflict-2',
          organizationId: 'org-2',
          outboxOperationId: 'op-2',
        ),
      );

      final result = await repository.listOpen(organizationId: 'org-1');
      final records = (result as AppSuccess<List<ConflictRecord>>).value;
      expect(records, hasLength(1));
      expect(records.single.organizationId, 'org-1');
    });

    test('getById returns null for an unknown id', () async {
      final result = await repository.getById('missing');
      expect((result as AppSuccess<ConflictRecord?>).value, isNull);
    });
  });
}
