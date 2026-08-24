import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_collection_repository.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_season_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SharedPreferencesCollectionRepository', () {
    late SharedPreferencesCollectionRepository collectionRepository;
    late SharedPreferencesSeasonRepository seasonRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      collectionRepository = const SharedPreferencesCollectionRepository();
      seasonRepository = const SharedPreferencesSeasonRepository();
    });

    test('persists a created collection as active and reads it back', () async {
      final collection = _collection();

      await collectionRepository.create(collection: collection);
      final lookupResult = await collectionRepository.getById(
        organizationId: 'org-1',
        id: 'collection-1',
      );

      final loaded = (lookupResult as AppSuccess<Collection>).value;
      expect(loaded.status, CollectionStatus.active);
      expect(loaded.seasonId, 'season-1');
      expect(loaded.year, 2026);
    });

    test('close transitions the collection to closed', () async {
      await collectionRepository.create(collection: _collection());

      final result = await collectionRepository.close(
        organizationId: 'org-1',
        id: 'collection-1',
        updatedBy: 'user-2',
      );

      expect(
        (result as AppSuccess<Collection>).value.status,
        CollectionStatus.closed,
      );
    });

    test('creating a collection with a seasonId marks that season as in use, '
        'so SeasonRepository.hasCollections reflects it', () async {
      await collectionRepository.create(collection: _collection());

      final hasCollectionsResult = await seasonRepository.hasCollections(
        organizationId: 'org-1',
        seasonId: 'season-1',
      );

      expect((hasCollectionsResult as AppSuccess<bool>).value, isTrue);
    });

    test('listByOrganization isolates by organization', () async {
      await collectionRepository.create(collection: _collection());
      await collectionRepository.create(
        collection: _collection(organizationId: 'org-2'),
      );

      final result = await collectionRepository.listByOrganization('org-1');

      expect((result as AppSuccess<List<Collection>>).value, hasLength(1));
    });
  });
}

Collection _collection({String organizationId = 'org-1'}) {
  final now = DateTime.utc(2026, 1, 1);
  return Collection(
    id: 'collection-1',
    organizationId: organizationId,
    name: 'Verão 2026',
    seasonId: 'season-1',
    year: 2026,
    status: CollectionStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}
