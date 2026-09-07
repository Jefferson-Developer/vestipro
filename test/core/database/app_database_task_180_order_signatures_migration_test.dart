import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';

/// No-op [QueryExecutorUser] used only to seed a raw "schema version 22"
/// sqlite file with none of TASK-180's tables, bypassing `AppDatabase`'s own
/// `onCreate`/`onUpgrade` machinery — same precedent as `_RawSchemaVersionSeed`
/// in `app_database_task_177_visit_routes_migration_test.dart`.
class _RawSchemaVersionSeed implements QueryExecutorUser {
  const _RawSchemaVersionSeed(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      Future<void>.value();
}

void main() {
  group('AppDatabase order signatures schema (TASK-180)', () {
    test('a fresh database creates the order_signatures table', () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(() => database.close());

      expect(database.schemaVersion, 23);
      await database.customStatement('SELECT 1');

      final columnNames = await database
          .customSelect("PRAGMA table_info('order_signatures')")
          .map((row) => row.read<String>('name'))
          .get();

      expect(
        columnNames,
        containsAll(<String>[
          'id',
          'organization_id',
          'company_id',
          'order_id',
          'signer_role',
          'signed_by_user_id',
          'signed_by_name',
          'method',
          'image_bytes',
          'content_hash',
          'order_version_at_signature',
          'signed_at',
          'status',
          'sync_status',
        ]),
      );
    });

    test('upgrades an existing schema version 22 database to 23, creating the '
        'order_signatures table', () async {
      final seedFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task180_migration_'
        '${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (seedFile.existsSync()) seedFile.deleteSync();
      });

      final seedExecutor = NativeDatabase(seedFile);
      await seedExecutor.ensureOpen(const _RawSchemaVersionSeed(22));
      await seedExecutor.close();

      final upgradedDatabase = AppDatabase(NativeDatabase(seedFile));
      addTearDown(() => upgradedDatabase.close());

      // Forces the lazy migration to actually run.
      await upgradedDatabase.customStatement('SELECT 1');

      final tableNames = await upgradedDatabase
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'order_signatures'",
          )
          .map((row) => row.read<String>('name'))
          .get();
      expect(tableNames, hasLength(1));
    });

    test('a signature captured fully offline survives a full database restart '
        '(process-close/reopen), still pendingSync — "captura offline sem '
        'perda"', () async {
      final seedFile = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'vestipro_task180_offline_roundtrip_'
        '${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      addTearDown(() async {
        if (seedFile.existsSync()) seedFile.deleteSync();
      });

      final firstOpen = AppDatabase(NativeDatabase(seedFile));
      final imageBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final now = DateTime.utc(2026, 6, 1, 12);
      await firstOpen.upsertOrderSignature(
        OrderSignaturesTableCompanion.insert(
          id: 'signature-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          orderNumber: const Value('000001'),
          signerRole: 'customer',
          signedByUserId: 'seller-1',
          signedByName: 'Maria Cliente',
          method: 'canvas_drawn',
          imageBytes: imageBytes,
          contentHash: 'hash-1',
          orderVersionAtSignature: 1,
          signedAt: now,
          status: 'valid',
          createdAt: now,
          createdBy: 'seller-1',
          updatedAt: now,
          updatedBy: 'seller-1',
          version: 1,
          syncStatus: 'pending_sync',
        ),
      );
      // Simulates the app being closed while still offline — the row must
      // already be durably committed to disk, not just held in memory.
      await firstOpen.close();

      final reopened = AppDatabase(NativeDatabase(seedFile));
      addTearDown(() => reopened.close());
      final row = await reopened.getOrderSignatureByOrderId(
        organizationId: 'org-1',
        companyId: 'company-1',
        orderId: 'order-1',
      );

      expect(row, isNotNull);
      expect(row!.imageBytes, imageBytes);
      expect(row.contentHash, 'hash-1');
      expect(row.syncStatus, 'pending_sync');

      final pending = await reopened.getPendingSyncOrderSignatures(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect(pending, hasLength(1));

      // Reconciling the sync outcome (mirrors `SubmitOrderSignatureUseCase`
      // on success) upserts the same row instead of creating a second one.
      await reopened.upsertOrderSignature(
        OrderSignaturesTableCompanion.insert(
          id: 'signature-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          orderId: 'order-1',
          signerRole: 'customer',
          signedByUserId: 'seller-1',
          signedByName: 'Maria Cliente',
          method: 'canvas_drawn',
          imageBytes: imageBytes,
          contentHash: 'hash-1',
          orderVersionAtSignature: 1,
          signedAt: now,
          status: 'valid',
          createdAt: now,
          createdBy: 'seller-1',
          updatedAt: now,
          updatedBy: 'seller-1',
          version: 2,
          syncStatus: 'synced',
        ),
      );
      final syncedRow = await reopened.getOrderSignatureByOrderId(
        organizationId: 'org-1',
        companyId: 'company-1',
        orderId: 'order-1',
      );
      expect(syncedRow?.syncStatus, 'synced');
      final pendingAfterSync = await reopened.getPendingSyncOrderSignatures(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect(pendingAfterSync, isEmpty);
    });
  });
}
