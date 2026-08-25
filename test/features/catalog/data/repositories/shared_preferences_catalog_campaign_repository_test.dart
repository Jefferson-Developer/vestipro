import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  });
}
