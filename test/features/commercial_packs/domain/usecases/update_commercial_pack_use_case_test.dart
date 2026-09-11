import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';

import '../../commercial_pack_test_fakes.dart';

void main() {
  group('UpdateCommercialPackUseCase', () {
    late FakeCommercialPackRepository repository;
    late UpdateCommercialPackUseCase useCase;

    setUp(() {
      repository = FakeCommercialPackRepository();
      useCase = UpdateCommercialPackUseCase(
        repository,
        const ValidateCommercialPackCompositionUseCase(),
      );
    });

    CommercialPack draftPack({String id = 'pack-1'}) {
      final now = DateTime.utc(2026, 1, 1);
      return CommercialPack(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        packCode: id,
        version: 1,
        name: 'Kit Verão',
        packType: CommercialPackType.kit,
        status: CommercialPackStatus.draft,
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
        syncStatus: CommercialPackSyncStatus.pending,
      );
    }

    Future<AppResult<CommercialPack>> update({
      required String id,
      CommercialPackStatus status = CommercialPackStatus.active,
    }) {
      return useCase(
        organizationId: 'org-1',
        id: id,
        name: 'Kit Verão Renomeado',
        packType: CommercialPackType.kit,
        status: status,
        pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
        stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
        validFrom: DateTime.utc(2026, 1, 1),
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-1',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
        updatedBy: 'user-1',
      );
    }

    test(
      'edits a draft pack directly, including publishing it to active',
      () async {
        repository.seed(draftPack());

        final result = await update(
          id: 'pack-1',
          status: CommercialPackStatus.active,
        );

        expect(result, isA<AppSuccess<CommercialPack>>());
        final pack = (result as AppSuccess<CommercialPack>).value;
        expect(pack.name, 'Kit Verão Renomeado');
        expect(pack.status, CommercialPackStatus.active);
      },
    );

    test('rejects editing a pack that does not exist', () async {
      final result = await update(id: 'missing');

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('rejects editing a pack that is already active — must be revised '
        'instead (ReviseCommercialPackUseCase)', () async {
      repository.seed(
        draftPack().copyWith(status: CommercialPackStatus.active),
      );

      final result = await update(id: 'pack-1');

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('rejects setting status to superseded directly', () async {
      repository.seed(draftPack());

      final result = await update(
        id: 'pack-1',
        status: CommercialPackStatus.superseded,
      );

      expect(result, isA<AppFailure<CommercialPack>>());
    });
  });
}
