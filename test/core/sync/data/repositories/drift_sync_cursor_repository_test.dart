import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/sync/sync.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('DriftSyncCursorRepository', () {
    late AppDatabase database;
    late DriftSyncCursorRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftSyncCursorRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'getCursor returns null when the entity was never pulled yet',
      () async {
        final result = await repository.getCursor(
          organizationId: 'org-1',
          companyId: 'company-1',
          kind: OfflinePackageEntityKind.customers,
        );

        expect(result, isA<AppSuccess<SyncCursor?>>());
        expect((result as AppSuccess<SyncCursor?>).value, isNull);
      },
    );

    test('saveCursor persists the value and getCursor reads it back', () async {
      final now = DateTime.utc(2026, 1, 1);

      final saveResult = await repository.saveCursor(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
        cursorValue: '2026-01-01T00:00:00.000Z',
        updatedAt: now,
      );
      expect(saveResult, isA<AppSuccess<void>>());

      final getResult = await repository.getCursor(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
      );
      final cursor = (getResult as AppSuccess<SyncCursor?>).value;
      expect(cursor, isNotNull);
      expect(cursor!.cursorValue, '2026-01-01T00:00:00.000Z');
      expect(cursor.organizationId, 'org-1');
      expect(cursor.companyId, 'company-1');
      expect(cursor.kind, OfflinePackageEntityKind.customers);
    });

    test(
      'saveCursor overwrites a previous cursor for the same scope',
      () async {
        final now = DateTime.utc(2026, 1, 1);
        await repository.saveCursor(
          organizationId: 'org-1',
          companyId: 'company-1',
          kind: OfflinePackageEntityKind.customers,
          cursorValue: 'cursor-1',
          updatedAt: now,
        );
        await repository.saveCursor(
          organizationId: 'org-1',
          companyId: 'company-1',
          kind: OfflinePackageEntityKind.customers,
          cursorValue: 'cursor-2',
          updatedAt: now.add(const Duration(minutes: 1)),
        );

        final result = await repository.getCursor(
          organizationId: 'org-1',
          companyId: 'company-1',
          kind: OfflinePackageEntityKind.customers,
        );
        final cursor = (result as AppSuccess<SyncCursor?>).value;
        expect(cursor!.cursorValue, 'cursor-2');
      },
    );

    test('cursors are isolated per organizationId/companyId/kind', () async {
      final now = DateTime.utc(2026, 1, 1);
      await repository.saveCursor(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
        cursorValue: 'org-1-cursor',
        updatedAt: now,
      );
      await repository.saveCursor(
        organizationId: 'org-2',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
        cursorValue: 'org-2-cursor',
        updatedAt: now,
      );
      await repository.saveCursor(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.priceLists,
        cursorValue: 'price-lists-cursor',
        updatedAt: now,
      );

      final org1Customers = await repository.getCursor(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
      );
      final org2Customers = await repository.getCursor(
        organizationId: 'org-2',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
      );
      final org1PriceLists = await repository.getCursor(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.priceLists,
      );

      expect(
        (org1Customers as AppSuccess<SyncCursor?>).value!.cursorValue,
        'org-1-cursor',
      );
      expect(
        (org2Customers as AppSuccess<SyncCursor?>).value!.cursorValue,
        'org-2-cursor',
      );
      expect(
        (org1PriceLists as AppSuccess<SyncCursor?>).value!.cursorValue,
        'price-lists-cursor',
      );
    });
  });
}
