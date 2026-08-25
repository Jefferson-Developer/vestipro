import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/catalog/data/repositories/shared_preferences_catalog_home_cache_repository.dart';

void main() {
  group('SharedPreferencesCatalogHomeCacheRepository', () {
    test('returns null when nothing was ever cached', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogHomeCacheRepository();

      final result = await repository.load(organizationId: 'org-1');

      expect((result as AppSuccess<CatalogHomeSnapshot?>).value, isNull);
    });

    test('round-trips a saved snapshot', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogHomeCacheRepository();
      final snapshot = CatalogHomeSnapshot(
        savedAt: DateTime.utc(2026, 8, 1, 12),
        sections: <CatalogHomeSection>[
          const CatalogHomeSection(
            type: CatalogHomeSectionType.newArrivals,
            title: 'Lançamentos',
            order: 1,
            priority: 1,
            items: <CatalogHomeItem>[
              CatalogHomeItem(
                id: 'product-1',
                title: 'Camisa',
                subtitle: 'VestiPro',
                imageUrl: 'https://cdn.vestipro.test/product-1.jpg',
                badgeLabel: 'Lançamento',
              ),
            ],
          ),
        ],
      );

      await repository.save(organizationId: 'org-1', snapshot: snapshot);
      final result = await repository.load(organizationId: 'org-1');

      final loaded = (result as AppSuccess<CatalogHomeSnapshot?>).value;
      expect(loaded, isNotNull);
      expect(loaded!.savedAt, snapshot.savedAt);
      expect(loaded.sections, snapshot.sections);
    });

    test('keeps caches for different companies isolated', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogHomeCacheRepository();
      final snapshotA = CatalogHomeSnapshot(
        savedAt: DateTime.utc(2026, 8, 1),
        sections: const <CatalogHomeSection>[],
      );

      await repository.save(
        organizationId: 'org-1',
        companyId: 'company-a',
        snapshot: snapshotA,
      );
      final companyBResult = await repository.load(
        organizationId: 'org-1',
        companyId: 'company-b',
      );

      expect(
        (companyBResult as AppSuccess<CatalogHomeSnapshot?>).value,
        isNull,
      );
    });
  });
}
