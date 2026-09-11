import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';
import 'package:vestipro/features/commercial_packs/data/mappers/commercial_pack_local_mapper.dart';
import 'package:vestipro/features/commercial_packs/data/mappers/commercial_pack_mapper.dart';
import 'package:vestipro/features/commercial_packs/data/repositories/drift_commercial_pack_local_store_repository.dart';

void main() {
  group('DriftCommercialPackLocalStoreRepository', () {
    late AppDatabase database;
    late DriftCommercialPackLocalStoreRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftCommercialPackLocalStoreRepository(
        database,
        const CommercialPackLocalMapper(CommercialPackMapper()),
      );
    });

    tearDown(() async {
      await database.close();
    });

    CommercialPack pack(
      String id, {
      String organizationId = 'org-1',
      String? companyId = 'company-1',
      DateTime? deletedAt,
      List<PackComponent> components = const <PackComponent>[
        PackComponent(
          id: 'component-1',
          scopeType: PackComponentScopeType.variant,
          scopeReferenceId: 'variant-1',
          compositionType: PackComponentCompositionType.fixed,
          quantity: 1,
        ),
      ],
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return CommercialPack(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        packCode: 'PACK-$id',
        version: 1,
        name: 'Kit $id',
        packType: CommercialPackType.kit,
        status: CommercialPackStatus.active,
        pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
        stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
        validFrom: now,
        components: components,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        deletedAt: deletedAt,
        syncStatus: CommercialPackSyncStatus.synced,
      );
    }

    test('replaceInitialLoad stores every given pack', () async {
      final result = await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        packs: <CommercialPack>[pack('a'), pack('b')],
      );

      expect(result, isA<AppSuccess<void>>());
      final countResult = await repository.count(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect((countResult as AppSuccess<int>).value, 2);
    });

    test(
      'replaceInitialLoad fully replaces the previous local set (no leftovers)',
      () async {
        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          packs: <CommercialPack>[pack('a'), pack('b')],
        );

        await repository.replaceInitialLoad(
          organizationId: 'org-1',
          companyId: 'company-1',
          packs: <CommercialPack>[pack('c')],
        );

        final allResult = await repository.getAll(
          organizationId: 'org-1',
          companyId: 'company-1',
        );
        final all = (allResult as AppSuccess<List<CommercialPack>>).value;
        expect(all.map((p) => p.id).toList(), <String>['c']);
      },
    );

    test('replaceInitialLoad never touches another organization/company scope '
        '(multi-tenant isolation)', () async {
      await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        packs: <CommercialPack>[pack('a')],
      );
      await repository.replaceInitialLoad(
        organizationId: 'org-2',
        companyId: 'company-2',
        packs: <CommercialPack>[
          pack('b', organizationId: 'org-2', companyId: 'company-2'),
        ],
      );

      await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        packs: const <CommercialPack>[],
      );

      final org2Result = await repository.getAll(
        organizationId: 'org-2',
        companyId: 'company-2',
      );
      expect(
        (org2Result as AppSuccess<List<CommercialPack>>).value,
        hasLength(1),
      );
    });

    test('getAll never returns a pack belonging to a different organization, '
        'even when queried without a companyId narrowing', () async {
      await repository.upsert(pack: pack('a', organizationId: 'org-1'));
      await repository.upsert(pack: pack('b', organizationId: 'org-2'));

      final result = await repository.getAll(organizationId: 'org-1');

      expect(
        (result as AppSuccess<List<CommercialPack>>).value.map((p) => p.id),
        <String>['a'],
      );
    });

    test('a null companyId narrows to organization-wide packs plus that '
        'company (never a different company)', () async {
      await repository.upsert(pack: pack('org-wide', companyId: null));
      await repository.upsert(
        pack: pack('company-1-pack', companyId: 'company-1'),
      );
      await repository.upsert(
        pack: pack('company-2-pack', companyId: 'company-2'),
      );

      final result = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(
        (result as AppSuccess<List<CommercialPack>>).value
            .map((p) => p.id)
            .toSet(),
        <String>{'org-wide', 'company-1-pack'},
      );
    });

    test('upsert inserts a new pack and updates an existing one', () async {
      await repository.upsert(pack: pack('a'));
      await repository.upsert(pack: pack('a').copyWith(name: 'Renomeado'));

      final allResult = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final all = (allResult as AppSuccess<List<CommercialPack>>).value;
      expect(all, hasLength(1));
      expect(all.single.name, 'Renomeado');
    });

    test('upsert round-trips components/assortmentRules through the local '
        'JSON columns', () async {
      final withComponents =
          pack(
            'a',
            components: const <PackComponent>[
              PackComponent(
                id: 'component-1',
                scopeType: PackComponentScopeType.color,
                scopeReferenceId: 'color-blue',
                compositionType: PackComponentCompositionType.gridProportion,
                proportion: 0.5,
              ),
            ],
          ).copyWith(
            assortmentRules: const <AssortmentRule>[
              AssortmentRule(
                id: 'rule-1',
                type: AssortmentRuleType.minDistinctColors,
                minQuantity: 2,
              ),
            ],
          );

      await repository.upsert(pack: withComponents);

      final allResult = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final stored =
          (allResult as AppSuccess<List<CommercialPack>>).value.single;

      expect(stored.components.single.proportion, 0.5);
      expect(stored.assortmentRules.single.minQuantity, 2);
    });

    test('a soft-deleted pack does not appear in getAll/count', () async {
      await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        packs: <CommercialPack>[
          pack('a'),
          pack('b', deletedAt: DateTime.utc(2026, 2, 1)),
        ],
      );

      final allResult = await repository.getAll(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      final countResult = await repository.count(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(
        (allResult as AppSuccess<List<CommercialPack>>).value.map((p) => p.id),
        <String>['a'],
      );
      expect((countResult as AppSuccess<int>).value, 1);
    });
  });
}
