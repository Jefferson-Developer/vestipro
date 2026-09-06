import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

void main() {
  test('clearAllLocalData remove caches e cursores de sincronização', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 9, 5);
    await database
        .into(database.customersTable)
        .insert(
          CustomersTableCompanion.insert(
            id: 'customer-a',
            organizationId: 'org-a',
            companyId: 'company-a',
            type: 'legalEntity',
            document: '04252011000110',
            status: 'active',
            registeredAt: now,
            createdAt: now,
            createdBy: 'user-a',
            updatedAt: now,
            updatedBy: 'user-a',
            version: 1,
            syncStatus: 'synced',
          ),
        );
    await database
        .into(database.syncCursorsTable)
        .insert(
          SyncCursorsTableCompanion.insert(
            organizationId: 'org-a',
            companyId: 'company-a',
            entityKind: 'customers',
            cursorValue: const Value('cursor-personal'),
            updatedAt: now,
          ),
        );

    await database.clearAllLocalData();

    expect(await database.select(database.customersTable).get(), isEmpty);
    expect(await database.select(database.syncCursorsTable).get(), isEmpty);
  });
}
