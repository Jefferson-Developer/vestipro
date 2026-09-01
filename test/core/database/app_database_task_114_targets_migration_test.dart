import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

/// No-op [QueryExecutorUser] used only to seed a raw "schema version 17"
/// sqlite file with the pre-TASK-114 `targets` table shape (TASK-106's
/// narrow placeholder: `owner_id`, no `dimension_type`/`period_granularity`/
/// `currency`/`status`), bypassing `AppDatabase`'s own `onCreate`/`onUpgrade`
/// machinery — mirroring `_RawSchemaVersionSeed` in
/// `app_database_task_106_schema_test.dart`.
class _RawSchemaVersionSeed implements QueryExecutorUser {
  const _RawSchemaVersionSeed(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      Future<void>.value();
}

void main() {
  group('AppDatabase Targets schema (TASK-114)', () {
    test('a fresh database creates the extended targets columns', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(() => database.close());

      expect(database.schemaVersion, 19);
      await database.customStatement('SELECT 1');

      final columnNames = await database
          .customSelect("PRAGMA table_info('targets')")
          .map((row) => row.read<String>('name'))
          .get();

      expect(
        columnNames,
        containsAll(<String>[
          'id',
          'organization_id',
          'company_id',
          'dimension_id',
          'dimension_type',
          'period_start',
          'period_end',
          'period_granularity',
          'metric',
          'target_value',
          'currency',
          'status',
          'achieved_value_cache',
          'version',
          'sync_status',
        ]),
      );
      expect(columnNames, isNot(contains('owner_id')));
    });

    test('upgrades an existing schema version 17 database to 18, renaming '
        'owner_id to dimension_id without losing pre-existing target rows, '
        'and adding the new columns as null (not yet backfilled)', () async {
      final seedFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task114_migration_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (seedFile.existsSync()) seedFile.deleteSync();
      });

      // 1. Seed a raw "schema version 17" database with the pre-TASK-114
      // `targets` table shape and one pre-existing row.
      final seedExecutor = NativeDatabase(seedFile);
      await seedExecutor.ensureOpen(const _RawSchemaVersionSeed(17));
      await seedExecutor.runCustom('''
          CREATE TABLE targets (
            id TEXT NOT NULL PRIMARY KEY,
            organization_id TEXT NOT NULL,
            company_id TEXT NOT NULL,
            owner_id TEXT NOT NULL,
            period_start INTEGER NOT NULL,
            period_end INTEGER NOT NULL,
            metric TEXT NOT NULL,
            target_value REAL NOT NULL,
            achieved_value_cache REAL,
            created_at INTEGER NOT NULL,
            created_by TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            updated_by TEXT NOT NULL,
            deleted_at INTEGER,
            version INTEGER NOT NULL,
            sync_status TEXT NOT NULL
          )
        ''');
      await seedExecutor.runInsert(
        'INSERT INTO targets (id, organization_id, company_id, owner_id, '
        'period_start, period_end, metric, target_value, created_at, '
        'created_by, updated_at, updated_by, version, sync_status) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'target-legacy-1',
          'org-1',
          'company-1',
          'user-1',
          DateTime.utc(2026, 1, 1).millisecondsSinceEpoch,
          DateTime.utc(2026, 2, 1).millisecondsSinceEpoch,
          'revenue',
          100000.0,
          DateTime.utc(2025, 12, 20).millisecondsSinceEpoch,
          'user-1',
          DateTime.utc(2025, 12, 21).millisecondsSinceEpoch,
          'user-1',
          1,
          'synced',
        ],
      );
      await seedExecutor.close();

      // 2. Open the real `AppDatabase` (schemaVersion 18) against that
      // same file — this must run the real `onUpgrade(from: 17, to: 18)`
      // migration.
      final upgradedDatabase = AppDatabase(NativeDatabase(seedFile));
      addTearDown(() => upgradedDatabase.close());

      final rows = await upgradedDatabase
          .select(upgradedDatabase.targetsTable)
          .get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, 'target-legacy-1');
      expect(row.dimensionId, 'user-1');
      expect(row.dimensionType, isNull);
      expect(row.periodGranularity, isNull);
      expect(row.currency, isNull);
      expect(row.status, isNull);
      expect(row.metric, 'revenue');
      expect(row.targetValue, 100000.0);

      final columnNames = await upgradedDatabase
          .customSelect("PRAGMA table_info('targets')")
          .map((r) => r.read<String>('name'))
          .get();
      expect(columnNames, isNot(contains('owner_id')));
      expect(columnNames, contains('dimension_id'));
    });
  });
}
