import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('DriftConflictAuditLogRepository', () {
    late AppDatabase database;
    late DriftConflictAuditLogRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftConflictAuditLogRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    ConflictAuditEntry buildEntry({
      String id = 'audit-1',
      String organizationId = 'org-1',
      ConflictAuditOutcome outcome = ConflictAuditOutcome.blockedManual,
      DateTime? performedAt,
    }) {
      return ConflictAuditEntry(
        id: id,
        organizationId: organizationId,
        companyId: 'company-1',
        entityType: OutboxEntityType.order,
        entityId: 'order-1',
        policy: ConflictPolicy.manualResolution,
        outcome: outcome,
        actor: ConflictResolutionService.systemActor,
        performedAt: performedAt ?? DateTime.utc(2026, 1, 1),
        conflictingFields: const ['discount'],
        conflictRecordId: 'conflict-1',
      );
    }

    test('record persists and decodes an entry back exactly', () async {
      final result = await repository.record(buildEntry());

      expect(result, isA<AppSuccess<ConflictAuditEntry>>());
      final entry = (result as AppSuccess<ConflictAuditEntry>).value;
      expect(entry.outcome, ConflictAuditOutcome.blockedManual);
      expect(entry.conflictingFields, ['discount']);
      expect(entry.conflictRecordId, 'conflict-1');
      expect(entry.actor, 'system:sync-engine');
    });

    test('listByOrganization returns entries most-recent-first', () async {
      await repository.record(
        buildEntry(id: 'audit-1', performedAt: DateTime.utc(2026, 1, 1)),
      );
      await repository.record(
        buildEntry(id: 'audit-2', performedAt: DateTime.utc(2026, 1, 2)),
      );

      final result = await repository.listByOrganization(
        organizationId: 'org-1',
      );
      final entries = (result as AppSuccess<List<ConflictAuditEntry>>).value;
      expect(entries.map((e) => e.id), ['audit-2', 'audit-1']);
    });

    test(
      'listByOrganization never returns entries from another organization',
      () async {
        await repository.record(buildEntry());
        await repository.record(
          buildEntry(id: 'audit-2', organizationId: 'org-2'),
        );

        final result = await repository.listByOrganization(
          organizationId: 'org-1',
        );
        final entries = (result as AppSuccess<List<ConflictAuditEntry>>).value;
        expect(entries, hasLength(1));
        expect(entries.single.organizationId, 'org-1');
      },
    );
  });
}
