import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('GetCommercialPackAvailabilityUseCase', () {
    late _FakePackComponentVariantResolver resolver;
    late _FakeVariantStockBalanceRepository stockRepository;
    late GetCommercialPackAvailabilityUseCase useCase;

    setUp(() {
      resolver = _FakePackComponentVariantResolver();
      stockRepository = _FakeVariantStockBalanceRepository();
      useCase = GetCommercialPackAvailabilityUseCase(resolver, stockRepository);
    });

    test(
      'reports the minimum fulfillable instances across every resolved '
      'component, explaining the bottleneck (consumeComponentBalances)',
      () async {
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
        // Component 1 needs 2 per instance, 10 available -> 5 instances.
        stockRepository.seed('variant-1', 10);
        // Component 2 needs 1 per instance, 3 available -> 3 instances
        // (the bottleneck).
        stockRepository.seed('variant-2', 3);

        final pack = _pack(
          stockPolicyType:
              CommercialPackStockPolicyType.consumeComponentBalances,
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

        final result = await useCase(pack: pack);

        final availability = _requireSuccess(result);
        expect(availability.availableInstances, 3);
        expect(availability.isFullyAvailable, isTrue);
        expect(availability.shortfalls, hasLength(1));
        expect(availability.shortfalls.single.variantId, 'variant-2');
      },
    );

    test(
      'reports zero instances when a component has no stock at all',
      () async {
        resolver.seed(
          scopeType: PackComponentScopeType.variant,
          scopeReferenceId: 'variant-1',
          variants: <ResolvedComponentVariant>[
            (variantId: 'variant-1', productId: 'product-1'),
          ],
        );
        // No stock seeded for variant-1 at all.

        final pack = _pack(
          stockPolicyType:
              CommercialPackStockPolicyType.consumeComponentBalances,
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

        final result = await useCase(pack: pack);

        final availability = _requireSuccess(result);
        expect(availability.availableInstances, 0);
        expect(availability.isFullyAvailable, isFalse);
      },
    );

    test('reads the dedicated pre-assembled balance directly under '
        'dedicatedStock', () async {
      stockRepository.seed('pack-1', 7);

      final pack = _pack(
        stockPolicyType: CommercialPackStockPolicyType.dedicatedStock,
        dedicatedWarehouseId: 'warehouse-1',
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

      final result = await useCase(pack: pack);

      final availability = _requireSuccess(result);
      expect(availability.availableInstances, 7);
      expect(availability.shortfalls, isEmpty);
    });
  });
}

CommercialPackAvailability _requireSuccess(
  AppResult<CommercialPackAvailability> result,
) {
  return switch (result) {
    AppSuccess<CommercialPackAvailability>(value: final availability) =>
      availability,
    AppFailure<CommercialPackAvailability>(failure: final failure) => fail(
      'Expected success, got failure: $failure',
    ),
  };
}

CommercialPack _pack({
  required CommercialPackStockPolicyType stockPolicyType,
  String? dedicatedWarehouseId,
  required List<PackComponent> components,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return CommercialPack(
    id: 'pack-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    packCode: 'PACK-1',
    version: 1,
    name: 'Kit Verão',
    packType: CommercialPackType.kit,
    status: CommercialPackStatus.active,
    pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
    stockPolicyType: stockPolicyType,
    dedicatedWarehouseId: dedicatedWarehouseId,
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

/// Fake keyed by [variantId] alone (organization/warehouse narrowing is not
/// needed for these tests) — returns `NotFoundFailure` for anything never
/// [seed]ed, matching [VariantStockBalanceRepository.getAvailability]'s own
/// documented "missing means unresolved" contract.
final class _FakeVariantStockBalanceRepository
    implements VariantStockBalanceRepository {
  final Map<String, int> _sellableByVariantId = <String, int>{};

  void seed(String variantId, int sellableQuantity) {
    _sellableByVariantId[variantId] = sellableQuantity;
  }

  @override
  Future<AppResult<VariantInventoryAvailability>> getAvailability({
    required String organizationId,
    required String variantId,
    String? warehouseId,
  }) async {
    final sellable = _sellableByVariantId[variantId];
    if (sellable == null) {
      return const AppFailure<VariantInventoryAvailability>(
        NotFoundFailure(
          'No stock balance found.',
          code: 'variant_stock_balance_not_found',
        ),
      );
    }
    return AppSuccess<VariantInventoryAvailability>(
      VariantInventoryAvailability(
        variantId: variantId,
        productId: 'product-for-$variantId',
        totalSellableQuantity: sellable,
        byWarehouse: const <VariantStockBalance>[],
      ),
    );
  }

  @override
  Future<AppResult<List<VariantStockBalance>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<VariantStockBalance>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<List<VariantStockBalance>>> listByWarehouse({
    required String organizationId,
    required String warehouseId,
    int limit = 20,
    String? startAfterId,
  }) => throw UnimplementedError();
}
