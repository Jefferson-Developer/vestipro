import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';

void main() {
  group('ValidateCommercialPackCompositionUseCase', () {
    final now = DateTime.utc(2026, 6, 1);
    const validator = ValidateCommercialPackCompositionUseCase();

    CommercialPack pack({
      List<PackComponent> components = const <PackComponent>[
        PackComponent(
          id: 'component-1',
          scopeType: PackComponentScopeType.variant,
          scopeReferenceId: 'variant-1',
          compositionType: PackComponentCompositionType.fixed,
          quantity: 1,
        ),
      ],
      List<AssortmentRule> assortmentRules = const <AssortmentRule>[],
      CommercialPackPricingPolicyType pricingPolicyType =
          CommercialPackPricingPolicyType.componentSum,
      double? fixedPrice,
      double? discountPercentage,
      String? bonusComponentId,
      CommercialPackStockPolicyType stockPolicyType =
          CommercialPackStockPolicyType.consumeComponentBalances,
      String? dedicatedWarehouseId,
      DateTime? validTo,
      String id = 'pack-1',
    }) {
      return CommercialPack(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        packCode: 'PACK-1',
        version: 1,
        name: 'Kit Verão',
        packType: CommercialPackType.kit,
        status: CommercialPackStatus.draft,
        pricingPolicyType: pricingPolicyType,
        fixedPrice: fixedPrice,
        discountPercentage: discountPercentage,
        bonusComponentId: bonusComponentId,
        stockPolicyType: stockPolicyType,
        dedicatedWarehouseId: dedicatedWarehouseId,
        validFrom: DateTime.utc(2026, 1, 1),
        validTo: validTo,
        components: components,
        assortmentRules: assortmentRules,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        syncStatus: CommercialPackSyncStatus.pending,
      );
    }

    test('a well-formed pack with a single fixed component is valid', () {
      final result = validator(pack: pack(), now: now);

      expect(result.isValid, isTrue);
      expect(result.fieldErrors, isEmpty);
    });

    test('a pack with no components at all is invalid', () {
      final result = validator(
        pack: pack(components: const <PackComponent>[]),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('components'));
    });

    test('componente inválido: an empty scopeReferenceId is rejected', () {
      final result = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: '  ',
              compositionType: PackComponentCompositionType.fixed,
              quantity: 1,
            ),
          ],
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('components[0].scopeReferenceId'));
    });

    test('componente inválido: isComponentReferenceValid rejecting a '
        'reference (e.g. inactive variant/deleted product/cross-org '
        'collection) fails validation', () {
      final result = validator(
        pack: pack(),
        now: now,
        isComponentReferenceValid: (component) => false,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('components[0].scopeReferenceId'));
    });

    test('componente válido: isComponentReferenceValid accepting every '
        'reference does not fail validation', () {
      final result = validator(
        pack: pack(),
        now: now,
        isComponentReferenceValid: (component) => true,
      );

      expect(result.isValid, isTrue);
    });

    test('quantidade zero: a fixed component with quantity 0 is invalid', () {
      final result = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: 'variant-1',
              compositionType: PackComponentCompositionType.fixed,
              quantity: 0,
            ),
          ],
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('components[0].quantity'));
    });

    test('quantidade zero: a fixed component with a negative quantity is '
        'invalid', () {
      final result = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: 'variant-1',
              compositionType: PackComponentCompositionType.fixed,
              quantity: -1,
            ),
          ],
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('components[0].quantity'));
    });

    test('a flexible component requires both minQuantity and maxQuantity '
        'greater than zero, with minQuantity <= maxQuantity', () {
      final missingBounds = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: 'variant-1',
              compositionType: PackComponentCompositionType.flexible,
            ),
          ],
        ),
        now: now,
      );
      expect(missingBounds.isValid, isFalse);
      expect(missingBounds.fieldErrors, contains('components[0].minQuantity'));
      expect(missingBounds.fieldErrors, contains('components[0].maxQuantity'));

      final invertedBounds = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: 'variant-1',
              compositionType: PackComponentCompositionType.flexible,
              minQuantity: 5,
              maxQuantity: 2,
            ),
          ],
        ),
        now: now,
      );
      expect(invertedBounds.isValid, isFalse);
      expect(invertedBounds.fieldErrors, contains('components[0].maxQuantity'));

      final valid = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.variant,
              scopeReferenceId: 'variant-1',
              compositionType: PackComponentCompositionType.flexible,
              minQuantity: 2,
              maxQuantity: 5,
            ),
          ],
        ),
        now: now,
      );
      expect(valid.isValid, isTrue);
    });

    test('proporção inválida: a gridProportion component requires a '
        'proportion strictly greater than 0 and at most 1', () {
      final zero = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.color,
              scopeReferenceId: 'color-blue',
              compositionType: PackComponentCompositionType.gridProportion,
              proportion: 0,
            ),
          ],
        ),
        now: now,
      );
      expect(zero.isValid, isFalse);
      expect(zero.fieldErrors, contains('components[0].proportion'));

      final aboveOne = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.color,
              scopeReferenceId: 'color-blue',
              compositionType: PackComponentCompositionType.gridProportion,
              proportion: 1.5,
            ),
          ],
        ),
        now: now,
      );
      expect(aboveOne.isValid, isFalse);
      expect(aboveOne.fieldErrors, contains('components[0].proportion'));

      final valid = validator(
        pack: pack(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.color,
              scopeReferenceId: 'color-blue',
              compositionType: PackComponentCompositionType.gridProportion,
              proportion: 0.3,
            ),
          ],
        ),
        now: now,
      );
      expect(valid.isValid, isTrue);
    });

    test('an assortment rule of type minPercentagePerColor requires colorId '
        'and a minPercentage between 0 (exclusive) and 1 (inclusive)', () {
      final result = validator(
        pack: pack(
          assortmentRules: const <AssortmentRule>[
            AssortmentRule(
              id: 'rule-1',
              type: AssortmentRuleType.minPercentagePerColor,
            ),
          ],
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('assortmentRules[0].colorId'));
      expect(result.fieldErrors, contains('assortmentRules[0].minPercentage'));
    });

    test('an assortment rule of type minQuantityPerSize requires sizeId and '
        'a positive minQuantity', () {
      final result = validator(
        pack: pack(
          assortmentRules: const <AssortmentRule>[
            AssortmentRule(
              id: 'rule-1',
              type: AssortmentRuleType.minQuantityPerSize,
            ),
          ],
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('assortmentRules[0].sizeId'));
      expect(result.fieldErrors, contains('assortmentRules[0].minQuantity'));
    });

    test('fixedPrice pricing policy requires a positive fixedPrice', () {
      final result = validator(
        pack: pack(
          pricingPolicyType: CommercialPackPricingPolicyType.fixedPrice,
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('fixedPrice'));
    });

    test('packDiscount pricing policy requires a discountPercentage between '
        '0 (exclusive) and 1 (inclusive)', () {
      final result = validator(
        pack: pack(
          pricingPolicyType: CommercialPackPricingPolicyType.packDiscount,
          discountPercentage: 1.5,
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('discountPercentage'));
    });

    test('bonusItem pricing policy requires bonusComponentId to reference an '
        'existing component', () {
      final missing = validator(
        pack: pack(
          pricingPolicyType: CommercialPackPricingPolicyType.bonusItem,
        ),
        now: now,
      );
      expect(missing.isValid, isFalse);
      expect(missing.fieldErrors, contains('bonusComponentId'));

      final danglingReference = validator(
        pack: pack(
          pricingPolicyType: CommercialPackPricingPolicyType.bonusItem,
          bonusComponentId: 'does-not-exist',
        ),
        now: now,
      );
      expect(danglingReference.isValid, isFalse);
      expect(danglingReference.fieldErrors, contains('bonusComponentId'));

      final valid = validator(
        pack: pack(
          pricingPolicyType: CommercialPackPricingPolicyType.bonusItem,
          bonusComponentId: 'component-1',
        ),
        now: now,
      );
      expect(valid.isValid, isTrue);
    });

    test('dedicatedStock stock policy requires a dedicatedWarehouseId', () {
      final result = validator(
        pack: pack(
          stockPolicyType: CommercialPackStockPolicyType.dedicatedStock,
        ),
        now: now,
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('dedicatedWarehouseId'));
    });

    test('vigência expirada: a validTo in the past is invalid', () {
      final result = validator(
        pack: pack(validTo: DateTime.utc(2026, 1, 2)),
        now: DateTime.utc(2026, 6, 1),
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('validTo'));
    });

    test('a validTo in the future is valid', () {
      final result = validator(
        pack: pack(validTo: DateTime.utc(2027, 1, 1)),
        now: DateTime.utc(2026, 6, 1),
      );

      expect(result.isValid, isTrue);
    });

    test('circularidade: a direct self-reference (pack A contains a '
        'component pointing back at pack A) is rejected', () {
      final packA = pack(
        id: 'pack-a',
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.commercialPack,
            scopeReferenceId: 'pack-a',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );

      final result = validator(
        pack: packA,
        now: now,
        componentsOfPack: (packId) =>
            packId == 'pack-a' ? packA.components : const <PackComponent>[],
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('components'));
    });

    test('circularidade: an indirect cycle (A contains B, B contains A) is '
        'rejected', () {
      final packA = pack(
        id: 'pack-a',
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.commercialPack,
            scopeReferenceId: 'pack-b',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );
      const packBComponents = <PackComponent>[
        PackComponent(
          id: 'component-1',
          scopeType: PackComponentScopeType.commercialPack,
          scopeReferenceId: 'pack-a',
          compositionType: PackComponentCompositionType.fixed,
          quantity: 1,
        ),
      ];

      final result = validator(
        pack: packA,
        now: now,
        componentsOfPack: (packId) => switch (packId) {
          'pack-a' => packA.components,
          'pack-b' => packBComponents,
          _ => const <PackComponent>[],
        },
      );

      expect(result.isValid, isFalse);
      expect(result.fieldErrors, contains('components'));
    });

    test('an acyclic (diamond-shaped) nested composition through '
        'commercialPack components is valid', () {
      final packA = pack(
        id: 'pack-a',
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.commercialPack,
            scopeReferenceId: 'pack-b',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
          PackComponent(
            id: 'component-2',
            scopeType: PackComponentScopeType.commercialPack,
            scopeReferenceId: 'pack-c',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );
      const packBComponents = <PackComponent>[
        PackComponent(
          id: 'component-1',
          scopeType: PackComponentScopeType.commercialPack,
          scopeReferenceId: 'pack-d',
          compositionType: PackComponentCompositionType.fixed,
          quantity: 1,
        ),
      ];
      const packCComponents = <PackComponent>[
        PackComponent(
          id: 'component-1',
          scopeType: PackComponentScopeType.commercialPack,
          scopeReferenceId: 'pack-d',
          compositionType: PackComponentCompositionType.fixed,
          quantity: 1,
        ),
      ];
      const packDComponents = <PackComponent>[
        PackComponent(
          id: 'component-1',
          scopeType: PackComponentScopeType.variant,
          scopeReferenceId: 'variant-1',
          compositionType: PackComponentCompositionType.fixed,
          quantity: 1,
        ),
      ];

      final result = validator(
        pack: packA,
        now: now,
        componentsOfPack: (packId) => switch (packId) {
          'pack-a' => packA.components,
          'pack-b' => packBComponents,
          'pack-c' => packCComponents,
          'pack-d' => packDComponents,
          _ => const <PackComponent>[],
        },
      );

      expect(result.isValid, isTrue);
    });

    test('omitting componentsOfPack skips the circularity check entirely', () {
      final packA = pack(
        id: 'pack-a',
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.commercialPack,
            scopeReferenceId: 'pack-a',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
      );

      final result = validator(pack: packA, now: now);

      expect(result.isValid, isTrue);
    });
  });
}
