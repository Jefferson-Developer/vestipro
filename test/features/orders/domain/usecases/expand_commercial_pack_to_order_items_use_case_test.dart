import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('ExpandCommercialPackToOrderItemsUseCase', () {
    late _FakePackComponentVariantResolver resolver;
    late _FakeCommercialPackRepository packRepository;
    late ResolvePriceForVariantUseCase resolvePriceForVariant;
    late ExpandCommercialPackToOrderItemsUseCase useCase;

    setUp(() {
      resolver = _FakePackComponentVariantResolver();
      packRepository = _FakeCommercialPackRepository();
      resolvePriceForVariant = ResolvePriceForVariantUseCase(
        ResolveApplicablePriceListsUseCase(const _FakePriceListRepository()),
        _FakePriceListItemRepository(<PriceListItem>[
          _priceListItem(
            productId: 'product-1',
            variantId: 'variant-1',
            price: 50,
          ),
          _priceListItem(
            productId: 'product-2',
            variantId: 'variant-2',
            price: 30,
          ),
        ]),
      );
      useCase = ExpandCommercialPackToOrderItemsUseCase(
        resolver,
        packRepository,
        resolvePriceForVariant,
        const Uuid(),
      );
    });

    test('expands a simple fixed-composition pack into OrderItems sharing one '
        'packGroupId, with the pack snapshot preserved on each item', () async {
      resolver.seed(
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-1',
        variants: <ResolvedComponentVariant>[
          (variantId: 'variant-1', productId: 'product-1'),
        ],
      );
      resolver.seed(
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-2',
        variants: <ResolvedComponentVariant>[
          (variantId: 'variant-2', productId: 'product-2'),
        ],
      );

      final pack = _pack(
        components: <PackComponent>[
          const PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-1',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 2,
          ),
          const PackComponent(
            id: 'component-2',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-2',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );

      final result = await useCase(
        pack: pack,
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      final items = _requireSuccess(result);
      expect(items, hasLength(2));
      expect(items.map((item) => item.packGroupId).toSet(), hasLength(1));
      expect(items.every((item) => item.packId == 'pack-1'), isTrue);
      expect(items.every((item) => item.packCode == 'PACK-1'), isTrue);
      expect(items.every((item) => item.packVersion == 1), isTrue);
      expect(items.every((item) => item.packName == 'Kit Verão'), isTrue);

      final variant1Item = items.firstWhere(
        (item) => item.variantId == 'variant-1',
      );
      expect(variant1Item.quantity, 2);
      expect(variant1Item.unitPrice, 50);
      expect(variant1Item.subtotal, 100);

      final variant2Item = items.firstWhere(
        (item) => item.variantId == 'variant-2',
      );
      expect(variant2Item.quantity, 1);
      expect(variant2Item.unitPrice, 30);
    });

    test(
      'rejects a pack that is not currently sellable (expired/inactive)',
      () async {
        final pack = _pack(
          status: CommercialPackStatus.draft,
          components: <PackComponent>[
            const PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: 'variant-1',
              compositionType: PackComponentCompositionType.fixed,
              quantity: 1,
            ),
          ],
        );

        final result = await useCase(
          pack: pack,
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        _requireFailureCode(result, 'commercial_pack_not_sellable');
      },
    );

    test('fails when a component has no currently sellable variant, explaining '
        'which component', () async {
      // Deliberately never seeded: resolves to an empty list.
      final pack = _pack(
        components: <PackComponent>[
          const PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-unknown',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );

      final result = await useCase(
        pack: pack,
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      switch (result) {
        case AppSuccess<List<OrderItem>>():
          fail('Expected failure.');
        case AppFailure<List<OrderItem>>(failure: final failure):
          expect(failure, isA<ValidationFailure>());
          expect(
            (failure as ValidationFailure).fieldErrors.containsKey(
              'components[0].scopeReferenceId',
            ),
            isTrue,
          );
      }
    });

    test('fails when a resolved variant has no price available', () async {
      resolver.seed(
        scopeType: PackComponentScopeType.variant,
        scopeReferenceId: 'variant-no-price',
        variants: <ResolvedComponentVariant>[
          (variantId: 'variant-no-price', productId: 'product-no-price'),
        ],
      );
      final pack = _pack(
        components: <PackComponent>[
          const PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-no-price',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );

      final result = await useCase(
        pack: pack,
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      _requireFailureCode(
        result,
        'commercial_pack_component_price_unavailable',
      );
    });

    test(
      'recursively expands a nested commercialPack component, multiplying '
      'quantities and keeping every item under the same packGroupId',
      () async {
        resolver.seed(
          scopeType: PackComponentScopeType.variant,
          scopeReferenceId: 'variant-1',
          variants: <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
        );

        final nestedPack = _pack(
          id: 'nested-pack',
          packCode: 'NESTED-1',
          components: <PackComponent>[
            const PackComponent(
              id: 'nested-component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: 'variant-1',
              compositionType: PackComponentCompositionType.fixed,
              quantity: 2,
            ),
          ],
        );
        packRepository.seed(nestedPack);

        final comboPack = _pack(
          id: 'combo-pack',
          packCode: 'COMBO-1',
          components: <PackComponent>[
            const PackComponent(
              id: 'combo-component-1',
              scopeType: PackComponentScopeType.commercialPack,
              scopeReferenceId: 'nested-pack',
              compositionType: PackComponentCompositionType.fixed,
              quantity: 3, // 3 nested pack instances.
            ),
          ],
        );

        final result = await useCase(
          pack: comboPack,
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        final items = _requireSuccess(result);
        expect(items, hasLength(1));
        // 2 units per nested pack instance x 3 instances = 6.
        expect(items.single.quantity, 6);
        expect(items.single.packId, 'nested-pack');
        expect(items.map((item) => item.packGroupId).toSet(), hasLength(1));
      },
    );

    test('rejects a pack whose nested composition is circular', () async {
      final selfReferencingPack = _pack(
        id: 'cyclic-pack',
        packCode: 'CYCLIC-1',
        components: <PackComponent>[
          const PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.commercialPack,
            scopeReferenceId: 'cyclic-pack',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );
      packRepository.seed(selfReferencingPack);

      final result = await useCase(
        pack: selfReferencingPack,
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      _requireFailureCode(
        result,
        'commercial_pack_expansion_circular_composition',
      );
    });
  });
}

List<OrderItem> _requireSuccess(AppResult<List<OrderItem>> result) {
  return switch (result) {
    AppSuccess<List<OrderItem>>(value: final items) => items,
    AppFailure<List<OrderItem>>(failure: final failure) => fail(
      'Expected success, got failure: $failure',
    ),
  };
}

void _requireFailureCode(AppResult<List<OrderItem>> result, String code) {
  switch (result) {
    case AppSuccess<List<OrderItem>>():
      fail('Expected failure with code "$code", got success.');
    case AppFailure<List<OrderItem>>(failure: final failure):
      expect(failure.code, code);
  }
}

CommercialPack _pack({
  String id = 'pack-1',
  String packCode = 'PACK-1',
  CommercialPackStatus status = CommercialPackStatus.active,
  required List<PackComponent> components,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return CommercialPack(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    packCode: packCode,
    version: 1,
    name: 'Kit Verão',
    packType: CommercialPackType.kit,
    status: status,
    pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
    stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
    validFrom: DateTime.utc(2026, 1, 1),
    components: components,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    syncStatus: CommercialPackSyncStatus.synced,
  );
}

final class _FakePackComponentVariantResolver
    implements PackComponentVariantResolver {
  final Map<String, List<ResolvedComponentVariant>> _byKey =
      <String, List<ResolvedComponentVariant>>{};

  void seed({
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
    required List<ResolvedComponentVariant> variants,
  }) {
    _byKey['${scopeType.name}|$scopeReferenceId'] = variants;
  }

  @override
  Future<AppResult<List<ResolvedComponentVariant>>> resolveSellableVariants({
    required String organizationId,
    String? companyId,
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
  }) async {
    final key = '${scopeType.name}|$scopeReferenceId';
    return AppSuccess<List<ResolvedComponentVariant>>(
      _byKey[key] ?? const <ResolvedComponentVariant>[],
    );
  }

  @override
  Future<AppResult<bool>> isReferenceValid({
    required String organizationId,
    String? companyId,
    required PackComponentScopeType scopeType,
    required String scopeReferenceId,
  }) async {
    final key = '${scopeType.name}|$scopeReferenceId';
    return AppSuccess<bool>(
      (_byKey[key] ?? const <ResolvedComponentVariant>[]).isNotEmpty,
    );
  }
}

final class _FakeCommercialPackRepository implements CommercialPackRepository {
  final Map<String, CommercialPack> _packsById = <String, CommercialPack>{};

  void seed(CommercialPack pack) => _packsById[pack.id] = pack;

  @override
  Future<AppResult<CommercialPack>> create({required CommercialPack pack}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<CommercialPack>> update({required CommercialPack pack}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<CommercialPack?>> getById({
    required String organizationId,
    required String id,
  }) async {
    return AppSuccess<CommercialPack?>(_packsById[id]);
  }

  @override
  Future<AppResult<List<CommercialPack>>> listByOrganization({
    required String organizationId,
    String? companyId,
  }) async => AppSuccess<List<CommercialPack>>(_packsById.values.toList());
}

PriceListItem _priceListItem({
  required String productId,
  required String variantId,
  required double price,
}) {
  return PriceListItem(
    id: PriceListItem.composeId(
      priceListId: 'price-list-1',
      productId: productId,
      variantId: variantId,
    ),
    organizationId: 'org-1',
    companyId: 'company-1',
    priceListId: 'price-list-1',
    productId: productId,
    variantId: variantId,
    price: price,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
  );
}

final class _FakePriceListRepository implements PriceListRepository {
  const _FakePriceListRepository();

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) =>
      throw UnimplementedError();

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async => AppSuccess<List<PriceList>>(<PriceList>[
    PriceList(
      id: 'price-list-1',
      organizationId: organizationId,
      companyId: companyId,
      name: 'Tabela padrão',
      currency: 'BRL',
      validFrom: DateTime.utc(2026, 1, 1),
      status: PriceListStatus.active,
      scope: PriceListScopeType.company,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
      version: 1,
      syncStatus: PriceListSyncStatus.synced,
    ),
  ]);

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) =>
      throw UnimplementedError();
}

final class _FakePriceListItemRepository implements PriceListItemRepository {
  const _FakePriceListItemRepository(this._items);

  final List<PriceListItem> _items;

  @override
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) async => AppSuccess<List<PriceListItem>>(
    _items
        .where(
          (item) =>
              item.organizationId == organizationId &&
              item.companyId == companyId &&
              item.priceListId == priceListId,
        )
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) async => AppSuccess<List<PriceListItem>>(
    _items
        .where(
          (item) =>
              item.organizationId == organizationId &&
              item.companyId == companyId &&
              item.productId == productId,
        )
        .toList(growable: false),
  );

  @override
  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  }) => throw UnimplementedError();
}
