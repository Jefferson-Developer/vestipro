import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

/// No-op [QueryExecutorUser] used only to seed a raw "schema version 20"
/// sqlite file with the pre-TASK-176 `customer_addresses` table shape (no
/// `latitude`/`longitude`/`geocoding_status_code`/`geocoded_at` columns),
/// bypassing `AppDatabase`'s own `onCreate`/`onUpgrade` machinery — mirroring
/// `_RawSchemaVersionSeed` in `app_database_task_114_targets_migration_test.dart`.
class _RawSchemaVersionSeed implements QueryExecutorUser {
  const _RawSchemaVersionSeed(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      Future<void>.value();
}

void main() {
  group('AppDatabase customer geocoding schema (TASK-176)', () {
    test('a fresh database creates the geocoding columns', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(() => database.close());

      expect(database.schemaVersion, 21);
      await database.customStatement('SELECT 1');

      final columnNames = await database
          .customSelect("PRAGMA table_info('customer_addresses')")
          .map((row) => row.read<String>('name'))
          .get();

      expect(
        columnNames,
        containsAll(<String>[
          'latitude',
          'longitude',
          'geocoding_status_code',
          'geocoded_at',
        ]),
      );
    });

    test('upgrades an existing schema version 20 database to 21, adding the '
        'geocoding columns as pending/null without losing pre-existing '
        'address rows', () async {
      final seedFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task176_migration_${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (seedFile.existsSync()) seedFile.deleteSync();
      });

      // 1. Seed a raw "schema version 20" database with the pre-TASK-176
      // `customer_addresses` table shape and one pre-existing row.
      final seedExecutor = NativeDatabase(seedFile);
      await seedExecutor.ensureOpen(const _RawSchemaVersionSeed(20));
      await seedExecutor.runCustom('''
          CREATE TABLE customers (
            id TEXT NOT NULL PRIMARY KEY
          )
        ''');
      await seedExecutor.runCustom('''
          CREATE TABLE customer_addresses (
            id TEXT NOT NULL PRIMARY KEY,
            customer_id TEXT NOT NULL,
            organization_id TEXT NOT NULL,
            company_id TEXT NOT NULL,
            type_code TEXT NOT NULL,
            type_label TEXT NOT NULL,
            street TEXT NOT NULL,
            number TEXT,
            complement TEXT,
            district TEXT,
            city TEXT NOT NULL,
            state TEXT NOT NULL,
            zip_code TEXT NOT NULL,
            country TEXT NOT NULL,
            is_primary INTEGER NOT NULL DEFAULT 0,
            position INTEGER NOT NULL DEFAULT 0
          )
        ''');
      await seedExecutor.runInsert(
        'INSERT INTO customers (id) VALUES (?)',
        <Object?>['customer-legacy-1'],
      );
      await seedExecutor.runInsert(
        'INSERT INTO customer_addresses (id, customer_id, organization_id, '
        'company_id, type_code, type_label, street, city, state, zip_code, '
        'country, is_primary, position) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        <Object?>[
          'address-legacy-1',
          'customer-legacy-1',
          'org-1',
          'company-1',
          'headquarters',
          'Sede',
          'Rua das Flores',
          'Blumenau',
          'SC',
          '89010000',
          'BR',
          1,
          0,
        ],
      );
      await seedExecutor.close();

      // 2. Open the real `AppDatabase` (schemaVersion 21) against that
      // same file — this must run the real `onUpgrade(from: 20, to: 21)`
      // migration.
      final upgradedDatabase = AppDatabase(NativeDatabase(seedFile));
      addTearDown(() => upgradedDatabase.close());

      final rows = await upgradedDatabase
          .select(upgradedDatabase.customerAddressesTable)
          .get();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.id, 'address-legacy-1');
      expect(row.street, 'Rua das Flores');
      expect(row.latitude, isNull);
      expect(row.longitude, isNull);
      expect(row.geocodedAt, isNull);
      // `ALTER TABLE ADD COLUMN ... DEFAULT 'pending'` backfills every
      // pre-existing row with that default (SQLite applies it at the SQL
      // level), so this legacy address is already correctly marked
      // eligible for the geocoding backfill job — never a silent NULL.
      expect(row.geocodingStatusCode, 'pending');

      final columnNames = await upgradedDatabase
          .customSelect("PRAGMA table_info('customer_addresses')")
          .map((r) => r.read<String>('name'))
          .get();
      expect(
        columnNames,
        containsAll(<String>[
          'latitude',
          'longitude',
          'geocoding_status_code',
          'geocoded_at',
        ]),
      );
    });
  });
}
