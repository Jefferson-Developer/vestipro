import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/catalog/data/repositories/shared_preferences_catalog_campaign_repository.dart';

void main() {
  group('SharedPreferencesCatalogCampaignRepository', () {
    test('returns an empty list when nothing was ever seeded', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogCampaignRepository();

      final result = await repository.listByOrganization('org-1');

      expect((result as AppSuccess<List<CatalogCampaign>>).value, isEmpty);
    });

    test('reads back a seeded campaign, excluding soft-deleted ones', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'catalog_campaigns_org-1': jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'camp-1',
            'organizationId': 'org-1',
            'title': 'Campanha Verão',
            'order': 0,
            'active': true,
            'createdAt': '2026-01-01T00:00:00.000Z',
            'createdBy': 'user-1',
            'updatedAt': '2026-01-01T00:00:00.000Z',
            'updatedBy': 'user-1',
          },
          <String, dynamic>{
            'id': 'camp-2',
            'organizationId': 'org-1',
            'title': 'Campanha Removida',
            'order': 1,
            'active': true,
            'deletedAt': '2026-02-01T00:00:00.000Z',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'createdBy': 'user-1',
            'updatedAt': '2026-01-01T00:00:00.000Z',
            'updatedBy': 'user-1',
          },
        ]),
      });
      const repository = SharedPreferencesCatalogCampaignRepository();

      final result = await repository.listByOrganization('org-1');

      final campaigns = (result as AppSuccess<List<CatalogCampaign>>).value;
      expect(campaigns.map((c) => c.id).toList(), <String>['camp-1']);
      expect(campaigns.single.title, 'Campanha Verão');
    });

    CatalogCampaign buildCampaign({String id = 'camp-1'}) {
      final now = DateTime.utc(2026, 1, 1);
      return CatalogCampaign(
        id: id,
        organizationId: 'org-1',
        title: 'Campanha Verão',
        description: 'Editorial de verão.',
        imageUrl: 'https://example.com/cover.jpg',
        editorialImageUrls: const <String>['https://example.com/a.jpg'],
        relatedProductIds: const <String>['product-1'],
        order: 0,
        active: true,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
      );
    }

    test('create then getById round-trips every field', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogCampaignRepository();

      await repository.create(campaign: buildCampaign());
      final result = await repository.getById(
        organizationId: 'org-1',
        id: 'camp-1',
      );

      final campaign = (result as AppSuccess<CatalogCampaign>).value;
      expect(campaign.description, 'Editorial de verão.');
      expect(campaign.editorialImageUrls, <String>[
        'https://example.com/a.jpg',
      ]);
      expect(campaign.relatedProductIds, <String>['product-1']);
    });

    test('getById fails with NotFoundFailure for an unknown id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogCampaignRepository();

      final result = await repository.getById(
        organizationId: 'org-1',
        id: 'missing',
      );

      expect(
        (result as AppFailure<CatalogCampaign>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('update persists the new values', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogCampaignRepository();
      await repository.create(campaign: buildCampaign());

      final updated = buildCampaign().copyWith(title: 'Novo título');
      final result = await repository.update(campaign: updated);

      expect(result, isA<AppSuccess<CatalogCampaign>>());
      final reloaded = await repository.getById(
        organizationId: 'org-1',
        id: 'camp-1',
      );
      expect(
        (reloaded as AppSuccess<CatalogCampaign>).value.title,
        'Novo título',
      );
    });

    test('update fails with NotFoundFailure for an unknown id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogCampaignRepository();

      final result = await repository.update(campaign: buildCampaign());

      expect(
        (result as AppFailure<CatalogCampaign>).failure,
        isA<NotFoundFailure>(),
      );
    });

    test(
      'delete soft-deletes so the campaign disappears from listing',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        const repository = SharedPreferencesCatalogCampaignRepository();
        await repository.create(campaign: buildCampaign());

        final result = await repository.delete(
          organizationId: 'org-1',
          id: 'camp-1',
          updatedBy: 'user-2',
        );

        expect(result, isA<AppSuccess<CatalogCampaign>>());
        expect(
          (result as AppSuccess<CatalogCampaign>).value.deletedAt,
          isNotNull,
        );
        final listResult = await repository.listByOrganization('org-1');
        expect(
          (listResult as AppSuccess<List<CatalogCampaign>>).value,
          isEmpty,
        );
      },
    );
  });
}
