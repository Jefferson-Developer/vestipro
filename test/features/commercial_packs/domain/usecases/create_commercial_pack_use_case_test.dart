import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';

import '../../commercial_pack_test_fakes.dart';

void main() {
  group('CreateCommercialPackUseCase', () {
    late FakeCommercialPackRepository repository;
    late CreateCommercialPackUseCase useCase;

    setUp(() {
      repository = FakeCommercialPackRepository();
      useCase = CreateCommercialPackUseCase(
        repository,
        const ValidateCommercialPackCompositionUseCase(),
      );
    });

    Future<AppResult<CommercialPack>> create({
      String id = 'pack-1',
      DateTime? validFrom,
      DateTime? validTo,
    }) {
      return useCase(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Kit Verão',
        packType: CommercialPackType.kit,
        pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
        stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
        validFrom: validFrom ?? DateTime.utc(2026, 1, 1),
        validTo: validTo,
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-1',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
        createdBy: 'user-1',
      );
    }

    test(
      'creates a pack born draft, version 1, packCode defaulting to id',
      () async {
        final result = await create();

        expect(result, isA<AppSuccess<CommercialPack>>());
        final pack = (result as AppSuccess<CommercialPack>).value;
        expect(pack.status, CommercialPackStatus.draft);
        expect(pack.version, 1);
        expect(pack.packCode, 'pack-1');
        expect(pack.syncStatus, CommercialPackSyncStatus.pending);
      },
    );

    test('rejects an empty id', () async {
      final result = await create(id: '');

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('rejects a validTo before validFrom', () async {
      final result = await create(
        validFrom: DateTime.utc(2026, 6, 1),
        validTo: DateTime.utc(2026, 1, 1),
      );

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('rejects an invalid composition (e.g. no components)', () async {
      final result = await useCase(
        id: 'pack-1',
        organizationId: 'org-1',
        name: 'Kit Vazio',
        packType: CommercialPackType.kit,
        pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
        stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
        validFrom: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
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
