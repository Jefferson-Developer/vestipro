import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/utils/utils.dart';

void main() {
  group('DriftOfflinePackageStatusRepository', () {
    late AppDatabase database;
    late DriftOfflinePackageStatusRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftOfflinePackageStatusRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('a never-downloaded scope has no status rows', () async {
      final result = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(result, isA<AppSuccess<List<OfflinePackageEntityStatus>>>());
      expect(
        (result as AppSuccess<List<OfflinePackageEntityStatus>>).value,
        isEmpty,
      );
    });

    test('markIncomplete then markComplete leaves a complete row', () async {
      final now = DateTime.utc(2026, 1, 1, 10);

      await repository.markIncomplete(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
        now: now,
      );
      await repository.markComplete(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
        recordCount: 42,
        now: now.add(const Duration(seconds: 5)),
      );

      final result = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final statuses =
          (result as AppSuccess<List<OfflinePackageEntityStatus>>).value;
      expect(statuses, hasLength(1));
      expect(statuses.single.kind, OfflinePackageEntityKind.customers);
      expect(statuses.single.isComplete, isTrue);
      expect(statuses.single.recordCount, 42);
    });

    test('markIncomplete after a previous markComplete flips the marker back '
        '(carga incompleta)', () async {
      final now = DateTime.utc(2026, 1, 1);

      await repository.markIncomplete(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.priceLists,
        now: now,
      );
      await repository.markComplete(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.priceLists,
        recordCount: 10,
        now: now,
      );

      // A new run starts and never finishes (crash/cancel).
      await repository.markIncomplete(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.priceLists,
        now: now.add(const Duration(minutes: 1)),
      );

      final result = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final statuses =
          (result as AppSuccess<List<OfflinePackageEntityStatus>>).value;
      expect(statuses.single.isComplete, isFalse);
    });

    test('never mixes statuses from another organization/company', () async {
      final now = DateTime.utc(2026, 1, 1);

      await repository.markComplete(
        organizationId: 'org-1',
        companyId: 'company-1',
        kind: OfflinePackageEntityKind.customers,
        recordCount: 5,
        now: now,
      );
      await repository.markComplete(
        organizationId: 'org-2',
        companyId: 'company-2',
        kind: OfflinePackageEntityKind.customers,
        recordCount: 99,
        now: now,
      );

      final result = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final statuses =
          (result as AppSuccess<List<OfflinePackageEntityStatus>>).value;
      expect(statuses, hasLength(1));
      expect(statuses.single.recordCount, 5);
    });
  });
}
