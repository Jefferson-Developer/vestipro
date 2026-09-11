import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';
import 'package:vestipro/features/commercial_packs/data/mappers/commercial_pack_mapper.dart';
import 'package:vestipro/features/commercial_packs/data/repositories/shared_preferences_commercial_pack_repository.dart';

void main() {
  group('SharedPreferencesCommercialPackRepository', () {
    late SharedPreferencesCommercialPackRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = SharedPreferencesCommercialPackRepository(
        const CommercialPackMapper(),
      );
    });

    CommercialPack pack({
      String id = 'pack-1',
      String organizationId = 'org-1',
      String? companyId = 'company-1',
      String packCode = 'PACK-1',
      CommercialPackStatus status = CommercialPackStatus.draft,
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return CommercialPack(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        packCode: packCode,
        version: 1,
        name: 'Kit Verão',
        packType: CommercialPackType.kit,
        status: status,
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

    test('creates and retrieves a commercial pack by id', () async {
      final createResult = await repository.create(pack: pack());
      final getResult = await repository.getById(
        organizationId: 'org-1',
        id: 'pack-1',
      );

      expect(createResult, isA<AppSuccess<CommercialPack>>());
      expect((getResult as AppSuccess<CommercialPack?>).value?.id, 'pack-1');
      expect(getResult.value?.components.single.scopeReferenceId, 'variant-1');
    });

    test('rejects creating two commercial packs with the same id', () async {
      await repository.create(pack: pack());

      final result = await repository.create(pack: pack());

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<ConflictFailure>(),
      );
    });

    test('listByOrganization never returns a pack of a different organization '
        '(multi-tenant isolation)', () async {
      await repository.create(
        pack: pack(id: 'a', organizationId: 'org-1'),
      );
      await repository.create(
        pack: pack(id: 'b', organizationId: 'org-2'),
      );

      final result = await repository.listByOrganization(
        organizationId: 'org-1',
      );

      final list = (result as AppSuccess<List<CommercialPack>>).value;
      expect(list.map((p) => p.id), <String>['a']);
    });

    test(
      'listByOrganization narrowed to a companyId includes organization-wide '
      'packs (companyId null) but excludes a different company',
      () async {
        await repository.create(pack: pack(id: 'org-wide', companyId: null));
        await repository.create(
          pack: pack(id: 'company-1-pack', companyId: 'company-1'),
        );
        await repository.create(
          pack: pack(id: 'company-2-pack', companyId: 'company-2'),
        );

        final result = await repository.listByOrganization(
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        final list = (result as AppSuccess<List<CommercialPack>>).value;
        expect(list.map((p) => p.id).toSet(), <String>{
          'org-wide',
          'company-1-pack',
        });
      },
    );

    test('update succeeds when the packCode stays the same', () async {
      final created = await repository.create(pack: pack());
      final toUpdate = (created as AppSuccess<CommercialPack>).value.copyWith(
        name: 'Kit Renomeado',
      );

      final result = await repository.update(pack: toUpdate);

      expect(result, isA<AppSuccess<CommercialPack>>());
    });

    test('update rejects a packCode change (immutability rule — a version '
        'change must create a new document instead)', () async {
      await repository.create(pack: pack(packCode: 'PACK-1'));

      final result = await repository.update(pack: pack(packCode: 'PACK-2'));

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<ValidationFailure>(),
      );
    });

    test('update fails for a commercial pack that does not exist', () async {
      final result = await repository.update(pack: pack());

      expect(result, isA<AppFailure<CommercialPack>>());
      expect(
        (result as AppFailure<CommercialPack>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('versioning: revising a pack creates a second document under the '
        'same packCode with a new id/version, while the original id keeps its '
        'own content untouched', () async {
      final active = pack(
        id: 'pack-1',
        packCode: 'PACK-1',
        status: CommercialPackStatus.active,
      );
      await repository.create(pack: active);

      final revised = active.copyWith(
        id: 'pack-1-v2',
        version: 2,
        name: 'Kit Verão v2',
      );
      await repository.create(pack: revised);

      final supersededOriginal = active.copyWith(
        status: CommercialPackStatus.superseded,
        supersededByPackId: 'pack-1-v2',
      );
      await repository.update(pack: supersededOriginal);

      final originalResult = await repository.getById(
        organizationId: 'org-1',
        id: 'pack-1',
      );
      final revisedResult = await repository.getById(
        organizationId: 'org-1',
        id: 'pack-1-v2',
      );

      final original = (originalResult as AppSuccess<CommercialPack?>).value!;
      final newVersion = (revisedResult as AppSuccess<CommercialPack?>).value!;

      expect(original.status, CommercialPackStatus.superseded);
      expect(original.supersededByPackId, 'pack-1-v2');
      expect(original.name, 'Kit Verão');
      expect(newVersion.version, 2);
      expect(newVersion.packCode, 'PACK-1');
    });
  });
}
