import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';
import 'package:vestipro/features/commercial_packs/data/mappers/commercial_pack_mapper.dart';

void main() {
  group('CommercialPackMapper', () {
    const mapper = CommercialPackMapper();
    final now = DateTime.utc(2026, 1, 1);

    CommercialPack pack({required List<PackComponent> components}) {
      return CommercialPack(
        id: 'pack-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        packCode: 'PACK-1',
        version: 2,
        name: 'Kit Verão',
        description: 'Kit promocional de verão',
        packType: CommercialPackType.assortment,
        status: CommercialPackStatus.active,
        pricingPolicyType: CommercialPackPricingPolicyType.packDiscount,
        discountPercentage: 0.1,
        stockPolicyType: CommercialPackStockPolicyType.dedicatedStock,
        dedicatedWarehouseId: 'warehouse-1',
        collectionId: 'collection-1',
        campaignId: 'campaign-1',
        customerSegment: 'vip',
        channel: 'wholesale',
        validFrom: now,
        validTo: DateTime.utc(2026, 12, 31),
        components: components,
        assortmentRules: const <AssortmentRule>[
          AssortmentRule(
            id: 'rule-1',
            type: AssortmentRuleType.minQuantityPerSize,
            sizeId: 'size-m',
            minQuantity: 3,
          ),
        ],
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        supersededByPackId: 'pack-0',
        syncStatus: CommercialPackSyncStatus.synced,
      );
    }

    test('round-trips a pack with a fixed composition component', () {
      final entity = pack(
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-1',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 2,
          ),
        ],
      );

      final roundTripped = mapper.toEntity(mapper.toDto(entity));

      expect(roundTripped, entity);
    });

    test('round-trips a pack with a flexible composition component', () {
      final entity = pack(
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.product,
            scopeReferenceId: 'product-1',
            compositionType: PackComponentCompositionType.flexible,
            minQuantity: 1,
            maxQuantity: 5,
          ),
        ],
      );

      final roundTripped = mapper.toEntity(mapper.toDto(entity));

      expect(roundTripped, entity);
    });

    test(
      'round-trips a pack with a grid-proportion (by color/size) composition '
      'component',
      () {
        final entity = pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.color,
              scopeReferenceId: 'color-blue',
              compositionType: PackComponentCompositionType.gridProportion,
              proportion: 0.4,
            ),
            PackComponent(
              id: 'component-2',
              scopeType: PackComponentScopeType.size,
              scopeReferenceId: 'size-m',
              compositionType: PackComponentCompositionType.gridProportion,
              proportion: 0.6,
              isBonusItem: true,
            ),
          ],
        );

        final roundTripped = mapper.toEntity(mapper.toDto(entity));

        expect(roundTripped, entity);
      },
    );

    test('round-trips a nested commercialPack-scoped component', () {
      final entity = pack(
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.commercialPack,
            scopeReferenceId: 'pack-nested',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );

      final roundTripped = mapper.toEntity(mapper.toDto(entity));

      expect(roundTripped, entity);
    });

    test('round-trips every CommercialPackType/Status/PricingPolicyType/'
        'StockPolicyType/SyncStatus code', () {
      for (final packType in CommercialPackType.values) {
        expect(
          mapper.packTypeToEntity(mapper.packTypeToDto(packType)),
          packType,
        );
      }
      for (final status in CommercialPackStatus.values) {
        expect(mapper.statusToEntity(mapper.statusToDto(status)), status);
      }
      for (final policy in CommercialPackPricingPolicyType.values) {
        expect(
          mapper.pricingPolicyTypeToEntity(
            mapper.pricingPolicyTypeToDto(policy),
          ),
          policy,
        );
      }
      for (final policy in CommercialPackStockPolicyType.values) {
        expect(
          mapper.stockPolicyTypeToEntity(mapper.stockPolicyTypeToDto(policy)),
          policy,
        );
      }
      for (final syncStatus in CommercialPackSyncStatus.values) {
        expect(
          mapper.syncStatusToEntity(mapper.syncStatusToDto(syncStatus)),
          syncStatus,
        );
      }
      for (final scopeType in PackComponentScopeType.values) {
        expect(
          mapper.scopeTypeToEntity(mapper.scopeTypeToDto(scopeType)),
          scopeType,
        );
      }
      for (final compositionType in PackComponentCompositionType.values) {
        expect(
          mapper.compositionTypeToEntity(
            mapper.compositionTypeToDto(compositionType),
          ),
          compositionType,
        );
      }
      for (final ruleType in AssortmentRuleType.values) {
        expect(
          mapper.assortmentRuleTypeToEntity(
            mapper.assortmentRuleTypeToDto(ruleType),
          ),
          ruleType,
        );
      }
    });

    test('an unknown status code throws ValidationException', () {
      expect(() => mapper.statusToEntity('unknown'), throwsException);
    });
  });
}
