import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/catalog/catalog.dart';
import 'package:vestipro/features/catalog/data/repositories/shared_preferences_catalog_preferences_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SharedPreferencesCatalogPreferencesRepository', () {
    test('returns null when nothing was ever saved', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogPreferencesRepository();

      final result = await repository.load(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect((result as AppSuccess<CatalogPreferences?>).value, isNull);
    });

    test('round-trips the view mode and every filter dimension', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogPreferencesRepository();
      const preferences = CatalogPreferences(
        viewMode: CatalogViewMode.list,
        filter: CatalogFilter(
          collectionId: 'col-1',
          colorIds: <String>{'red', 'blue'},
          availability: VariantAvailabilityStatus.readyStock,
          launchOnly: true,
        ),
      );

      await repository.save(
        organizationId: 'org-1',
        userId: 'user-1',
        preferences: preferences,
      );
      final result = await repository.load(
        organizationId: 'org-1',
        userId: 'user-1',
      );

      expect((result as AppSuccess<CatalogPreferences?>).value, preferences);
    });

    test('never leaks one organization'
        's preference into another', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogPreferencesRepository();

      await repository.save(
        organizationId: 'org-1',
        userId: 'user-1',
        preferences: const CatalogPreferences(
          filter: CatalogFilter(brand: 'Malwee'),
        ),
      );
      final otherOrg = await repository.load(
        organizationId: 'org-2',
        userId: 'user-1',
      );

      expect((otherOrg as AppSuccess<CatalogPreferences?>).value, isNull);
    });

    test('never leaks one user'
        's preference into another, same org', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const repository = SharedPreferencesCatalogPreferencesRepository();

      await repository.save(
        organizationId: 'org-1',
        userId: 'user-1',
        preferences: const CatalogPreferences(
          filter: CatalogFilter(brand: 'Malwee'),
        ),
      );
      final otherUser = await repository.load(
        organizationId: 'org-1',
        userId: 'user-2',
      );

      expect((otherUser as AppSuccess<CatalogPreferences?>).value, isNull);
    });
  });
}
