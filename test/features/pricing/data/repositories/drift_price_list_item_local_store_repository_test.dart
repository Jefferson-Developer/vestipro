import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/data/mappers/price_list_item_local_mapper.dart';
import 'package:vestipro/features/pricing/data/repositories/drift_price_list_item_local_store_repository.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('DriftPriceListItemLocalStoreRepository', () {
    late AppDatabase database;
    late DriftPriceListItemLocalStoreRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftPriceListItemLocalStoreRepository(
        database,
        const PriceListItemLocalMapper(),
      );
    });

    tearDown(() async {
      await database.close();
    });

    PriceListItem item(
      String productId, {
      String priceListId = 'price-list-1',
      String? variantId,
      double price = 189.9,
      DateTime? deletedAt,
    }) {
      return PriceListItem(
        id: PriceListItem.composeId(
          priceListId: priceListId,
          productId: productId,
          variantId: variantId,
        ),
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: priceListId,
        productId: productId,
        variantId: variantId,
        price: price,
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
        deletedAt: deletedAt,
        syncStatus: 'synced',
      );
    }

    test('replaceInitialLoad stores every given price item', () async {
      final result = await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'price-list-1',
        items: <PriceListItem>[
          item('product-1'),
          item('product-1', variantId: 'variant-1', price: 199.9),
        ],
      );

      expect(result, isA<AppSuccess<void>>());
      final all = await repository.getByPriceList(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'price-list-1',
      );
      expect((all as AppSuccess<List<PriceListItem>>).value, hasLength(2));
    });

    test(
      'replaceInitialLoad fully replaces previous item set for the table',
      () async {
        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceListId: 'price-list-1',
          items: <PriceListItem>[item('product-1')],
        );
        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceListId: 'price-list-1',
          items: <PriceListItem>[item('product-2')],
        );

        final all = await repository.getByPriceList(
          organizationId: 'org-1',
          companyId: 'company-1',
          priceListId: 'price-list-1',
        );
        expect(
          (all as AppSuccess<List<PriceListItem>>).value.map(
            (item) => item.productId,
          ),
          <String>['product-2'],
        );
      },
    );

    test('upsert updates an existing cached price row', () async {
      await repository.upsert(item: item('product-1'));
      await repository.upsert(item: item('product-1', price: 219.9));

      final all = await repository.getByPriceList(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'price-list-1',
      );
      expect(
        (all as AppSuccess<List<PriceListItem>>).value.single.price,
        219.9,
      );
    });

    test('soft-deleted cached rows do not appear in reads', () async {
      await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'price-list-1',
        items: <PriceListItem>[
          item('product-1'),
          item('product-2', deletedAt: DateTime.utc(2026, 2, 1)),
        ],
      );

      final all = await repository.getByPriceList(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'price-list-1',
      );
      expect((all as AppSuccess<List<PriceListItem>>).value, hasLength(1));
    });
  });
}
