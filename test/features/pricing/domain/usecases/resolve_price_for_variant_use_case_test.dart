import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('ResolvePriceForVariantUseCase', () {
    final now = DateTime.utc(2026, 6, 1);

    PriceList priceList({
      required String id,
      int priority = 0,
      String organizationId = 'org-1',
      String companyId = 'company-1',
    }) {
      return PriceList(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        name: id,
        currency: 'BRL',
        validFrom: DateTime.utc(2026, 1, 1),
        status: PriceListStatus.active,
        scope: PriceListScopeType.company,
        priority: priority,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: PriceListSyncStatus.synced,
      );
    }

    PriceListItem item({
      required String priceListId,
      required String productId,
      required double price,
      String? variantId,
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
        updatedAt: now,
        updatedBy: 'user-1',
        syncStatus: 'synced',
      );
    }

    test('returns the variant-specific price when present', () async {
      final useCase = ResolvePriceForVariantUseCase(
        ResolveApplicablePriceListsUseCase(
          _FakePriceListRepository(<PriceList>[priceList(id: 'vip')]),
        ),
        _FakePriceListItemRepository(<PriceListItem>[
          item(
            priceListId: 'vip',
            productId: 'product-1',
            variantId: 'variant-1',
            price: 199.9,
          ),
          item(priceListId: 'vip', productId: 'product-1', price: 189.9),
        ]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        productId: 'product-1',
        variantId: 'variant-1',
        now: now,
      );

      final resolved = (result as AppSuccess<ResolvedVariantPrice>).value;
      expect(resolved.origin, PriceResolutionOrigin.variant);
      expect(resolved.price, 199.9);
    });

    test('falls back to the product-level price in the same table', () async {
      final useCase = ResolvePriceForVariantUseCase(
        ResolveApplicablePriceListsUseCase(
          _FakePriceListRepository(<PriceList>[priceList(id: 'base')]),
        ),
        _FakePriceListItemRepository(<PriceListItem>[
          item(priceListId: 'base', productId: 'product-1', price: 149.9),
        ]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        productId: 'product-1',
        variantId: 'variant-missing',
        now: now,
      );

      final resolved = (result as AppSuccess<ResolvedVariantPrice>).value;
      expect(resolved.origin, PriceResolutionOrigin.product);
      expect(resolved.price, 149.9);
    });

    test(
      'returns explicit missing when no applicable table has a price',
      () async {
        final useCase = ResolvePriceForVariantUseCase(
          ResolveApplicablePriceListsUseCase(
            _FakePriceListRepository(<PriceList>[priceList(id: 'base')]),
          ),
          _FakePriceListItemRepository(const <PriceListItem>[]),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          productId: 'product-1',
          variantId: 'variant-1',
          now: now,
        );

        final resolved = (result as AppSuccess<ResolvedVariantPrice>).value;
        expect(resolved.origin, PriceResolutionOrigin.missing);
        expect(resolved.hasPrice, isFalse);
      },
    );

    test('respects higher-priority applicable price lists first', () async {
      final useCase = ResolvePriceForVariantUseCase(
        ResolveApplicablePriceListsUseCase(
          _FakePriceListRepository(<PriceList>[
            priceList(id: 'low', priority: 1),
            priceList(id: 'high', priority: 10),
          ]),
        ),
        _FakePriceListItemRepository(<PriceListItem>[
          item(priceListId: 'low', productId: 'product-1', price: 120),
          item(priceListId: 'high', productId: 'product-1', price: 150),
        ]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        productId: 'product-1',
        variantId: 'variant-1',
        now: now,
      );

      final resolved = (result as AppSuccess<ResolvedVariantPrice>).value;
      expect(resolved.priceList?.id, 'high');
      expect(resolved.price, 150);
    });
  });
}

final class _FakePriceListRepository implements PriceListRepository {
  _FakePriceListRepository(this._items);

  final List<PriceList> _items;

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PriceList>>(
      _items
          .where(
            (item) =>
                item.organizationId == organizationId &&
                item.companyId == companyId,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) {
    throw UnimplementedError();
  }
}

final class _FakePriceListItemRepository implements PriceListItemRepository {
  _FakePriceListItemRepository(this._items);

  final List<PriceListItem> _items;

  @override
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) async {
    return AppSuccess<List<PriceListItem>>(
      _items
          .where(
            (item) =>
                item.organizationId == organizationId &&
                item.companyId == companyId &&
                item.productId == productId,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  }) {
    throw UnimplementedError();
  }
}
