import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';

import '../../commercial_pack_test_fakes.dart';

void main() {
  group('ReviseCommercialPackUseCase', () {
    late FakeCommercialPackRepository repository;
    late ReviseCommercialPackUseCase useCase;

    setUp(() {
      repository = FakeCommercialPackRepository();
      useCase = ReviseCommercialPackUseCase(
        repository,
        const ValidateCommercialPackCompositionUseCase(),
      );
    });

    CommercialPack activePack({
      String id = 'pack-1',
      String packCode = 'PACK-1',
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
        status: CommercialPackStatus.active,
        pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
        stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
        validFrom: now,
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-1',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        syncStatus: CommercialPackSyncStatus.synced,
      );
    }

    Future<AppResult<CommercialPack>> revise({
      required String currentPackId,
      required String newPackId,
      List<PackComponent> components = const <PackComponent>[
        PackComponent(
          id: 'component-1',
          scopeType: PackComponentScopeType.variant,
          scopeReferenceId: 'variant-2',
          compositionType: PackComponentCompositionType.fixed,
          quantity: 3,
        ),
      ],
    }) {
      return useCase(
        organizationId: 'org-1',
        currentPackId: currentPackId,
        newPackId: newPackId,
        name: 'Kit Verão v2',
        packType: CommercialPackType.kit,
        pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
        stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
        validFrom: DateTime.utc(2026, 1, 1),
        components: components,
        updatedBy: 'user-1',
      );
    }

    test('alteração em pacote ativo cria nova versão sem reescrever a versão '
        'anterior: the original id/document keeps its own original content, '
        'a brand-new document is created with the same packCode and version '
        '+ 1', () async {
      final original = activePack();
      repository.seed(original);

      final result = await revise(
        currentPackId: 'pack-1',
        newPackId: 'pack-1-v2',
      );

      expect(result, isA<AppSuccess<CommercialPack>>());
      final revised = (result as AppSuccess<CommercialPack>).value;
      expect(revised.id, 'pack-1-v2');
      expect(revised.packCode, 'PACK-1');
      expect(revised.version, 2);
      expect(revised.status, CommercialPackStatus.draft);
      expect(revised.name, 'Kit Verão v2');
      expect(revised.components.single.scopeReferenceId, 'variant-2');

      final originalResult = await repository.getById(
        organizationId: 'org-1',
        id: 'pack-1',
      );
      final originalNow =
          (originalResult as AppSuccess<CommercialPack?>).value!;

      // The old version's substantive content (name/components) is never
      // rewritten — an Order still referencing "pack-1" reads the exact
      // composition it had when placed.
      expect(originalNow.name, 'Kit Verão');
      expect(originalNow.components.single.scopeReferenceId, 'variant-1');
      expect(originalNow.status, CommercialPackStatus.superseded);
      expect(originalNow.supersededByPackId, 'pack-1-v2');
    });

    test('rejects revising a pack that is still draft (must be edited '
        'directly via UpdateCommercialPackUseCase instead)', () async {
      repository.seed(
        activePack().copyWith(status: CommercialPackStatus.draft),
      );

      final result = await revise(
        currentPackId: 'pack-1',
        newPackId: 'pack-1-v2',
      );

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('rejects revising a pack that does not exist', () async {
      final result = await revise(
        currentPackId: 'missing',
        newPackId: 'pack-1-v2',
      );

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('rejects reusing the current pack id as the new version id', () async {
      repository.seed(activePack());

      final result = await revise(currentPackId: 'pack-1', newPackId: 'pack-1');

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('rejects a revision whose new composition would introduce a '
        'circular pack reference', () async {
      final original = activePack();
      repository.seed(original);
      repository.seed(
        activePack(id: 'pack-b', packCode: 'PACK-B').copyWith(
          components: const <PackComponent>[
            PackComponent(
              id: 'component-1',
              scopeType: PackComponentScopeType.commercialPack,
              scopeReferenceId: 'pack-1-v2',
              compositionType: PackComponentCompositionType.fixed,
              quantity: 1,
            ),
          ],
        ),
      );

      final result = await revise(
        currentPackId: 'pack-1',
        newPackId: 'pack-1-v2',
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

      expect(result, isA<AppFailure<CommercialPack>>());
      final failure = (result as AppFailure<CommercialPack>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors,
        contains('components'),
      );
    });
  });
}
