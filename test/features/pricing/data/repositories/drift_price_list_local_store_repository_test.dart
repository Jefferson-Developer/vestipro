import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/data/mappers/price_list_local_mapper.dart';
import 'package:vestipro/features/pricing/data/mappers/price_list_mapper.dart';
import 'package:vestipro/features/pricing/data/repositories/drift_price_list_local_store_repository.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('DriftPriceListLocalStoreRepository', () {
    late AppDatabase database;
    late DriftPriceListLocalStoreRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftPriceListLocalStoreRepository(
        database,
        const PriceListLocalMapper(PriceListMapper()),
      );
    });

    tearDown(() async {
      await database.close();
    });

    PriceList priceList(
      String id, {
      String organizationId = 'org-1',
      String companyId = 'company-1',
      DateTime? deletedAt,
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return PriceList(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        name: 'Tabela $id',
        currency: 'BRL',
        validFrom: now,
        status: PriceListStatus.active,
        scope: PriceListScopeType.company,
        priority: 1,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        deletedAt: deletedAt,
        version: 1,
        syncStatus: PriceListSyncStatus.synced,
      );
    }

    test('replaceInitialLoad stores every given price list', () async {
      final result = await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceLists: <PriceList>[priceList('a'), priceList('b')],
      );

      expect(result, isA<AppSuccess<void>>());
      final countResult = await repository.count(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect((countResult as AppSuccess<int>).value, 2);
    });

    test(
      'replaceInitialLoad fully replaces the previous local set (no leftovers)',
      () async {
        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceLists: <PriceList>[priceList('a'), priceList('b')],
        );

        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceLists: <PriceList>[priceList('c')],
        );

        final allResult = await repository.getAll(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        final all = (allResult as AppSuccess<List<PriceList>>).value;
        expect(all.map((p) => p.id).toList(), <String>['c']);
      },
    );

    test(
      'replaceInitialLoad never touches another organization/company scope',
      () async {
        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceLists: <PriceList>[priceList('a')],
        );
        await repository.replaceInitialLoad(
          organizationId: 'org-2',
          companyId: 'company-2',
          priceLists: <PriceList>[
            priceList('b', organizationId: 'org-2', companyId: 'company-2'),
          ],
        );

        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceLists: const <PriceList>[],
        );

        final org2Result = await repository.getAll(
          organizationId: 'org-2',
          companyId: 'company-2',
        );
        expect((org2Result as AppSuccess<List<PriceList>>).value, hasLength(1));
      },
    );

    test(
      'upsert inserts a new price list and updates an existing one',
      () async {
        await repository.upsert(priceList: priceList('a'));
        await repository.upsert(
          priceList: priceList('a').copyWith(name: 'Renomeada'),
        );

        final allResult = await repository.getAll(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        final all = (allResult as AppSuccess<List<PriceList>>).value;
        expect(all, hasLength(1));
        expect(all.single.name, 'Renomeada');
      },
    );

    test('a soft-deleted price list does not appear in getAll/count', () async {
      await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceLists: <PriceList>[
          priceList('a'),
          priceList('b', deletedAt: DateTime.utc(2026, 2, 1)),
        ],
      );

      final allResult = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final countResult = await repository.count(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(
        (allResult as AppSuccess<List<PriceList>>).value.map((p) => p.id),
        <String>['a'],
      );
      expect((countResult as AppSuccess<int>).value, 1);
    });
  });
}
