import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

/// No-op [QueryExecutorUser] used only to seed a raw "schema version 21"
/// sqlite file with none of TASK-177's tables, bypassing `AppDatabase`'s own
/// `onCreate`/`onUpgrade` machinery — same precedent as
/// `_RawSchemaVersionSeed` in
/// `app_database_task_176_customer_geocoding_migration_test.dart`.
class _RawSchemaVersionSeed implements QueryExecutorUser {
  const _RawSchemaVersionSeed(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      Future<void>.value();
}

void main() {
  group('AppDatabase visit routes schema (TASK-177)', () {
    test('a fresh database creates the visit_routes table', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(() => database.close());

      expect(database.schemaVersion, 23);
      await database.customStatement('SELECT 1');

      final columnNames = await database
          .customSelect("PRAGMA table_info('visit_routes')")
          .map((row) => row.read<String>('name'))
          .get();

      expect(
        columnNames,
        containsAll(<String>[
          'id',
          'organization_id',
          'company_id',
          'sales_rep_id',
          'date',
          'stops_json',
          'created_at',
          'updated_at',
        ]),
      );
    });

    test('upgrades an existing schema version 21 database to 22, creating the '
        'visit_routes table', () async {
      final seedFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task177_migration_'
        '${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (seedFile.existsSync()) seedFile.deleteSync();
      });

      final seedExecutor = NativeDatabase(seedFile);
      await seedExecutor.ensureOpen(const _RawSchemaVersionSeed(21));
      await seedExecutor.close();

      final upgradedDatabase = AppDatabase(NativeDatabase(seedFile));
      addTearDown(() => upgradedDatabase.close());

      // Forces the lazy migration to actually run.
      await upgradedDatabase.customStatement('SELECT 1');

      final tableNames = await upgradedDatabase
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'visit_routes'",
          )
          .map((row) => row.read<String>('name'))
          .get();
      expect(tableNames, hasLength(1));

      // The new table is immediately usable (insert/select round-trip).
      await upgradedDatabase
          .into(upgradedDatabase.visitRoutesTable)
          .insert(
            VisitRoutesTableCompanion.insert(
              id: 'route-1',
              organizationId: 'org-1',
              companyId: 'company-1',
              salesRepId: 'rep-1',
              date: DateTime.utc(2026, 9, 7),
              stopsJson: '[]',
              createdAt: DateTime.utc(2026, 9, 7),
              updatedAt: DateTime.utc(2026, 9, 7),
            ),
          );
      final rows = await upgradedDatabase
          .select(upgradedDatabase.visitRoutesTable)
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'route-1');
    });
  });
}
