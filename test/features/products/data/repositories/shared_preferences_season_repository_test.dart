import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/data/repositories/shared_preferences_season_repository.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('SharedPreferencesSeasonRepository', () {
    late SharedPreferencesSeasonRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesSeasonRepository();
    });

    test('persists a created season and reads it back', () async {
      final season = _season();

      final createResult = await repository.create(season: season);
      final lookupResult = await repository.getById(
        organizationId: 'org-1',
        id: 'season-1',
      );

      expect(createResult, isA<AppSuccess<Season>>());
      expect((lookupResult as AppSuccess<Season>).value.name, 'Verão');
    });

    test('existsByName is case-insensitive and trimmed', () async {
      await repository.create(season: _season());

      final result = await repository.existsByName(
        organizationId: 'org-1',
        name: '  VERÃO  ',
      );

      expect((result as AppSuccess<bool>).value, isTrue);
    });

    test('existsByName excludes the season being edited', () async {
      await repository.create(season: _season());

      final result = await repository.existsByName(
        organizationId: 'org-1',
        name: 'Verão',
        excludingSeasonId: 'season-1',
      );

      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test('update fails for a season that was never created', () async {
      final result = await repository.update(season: _season());

      expect(result, isA<AppFailure<Season>>());
      expect((result as AppFailure<Season>).failure, isA<NotFoundFailure>());
    });

    test(
      'delete soft-deletes and excludes it from listByOrganization',
      () async {
        await repository.create(season: _season());

        final deleteResult = await repository.delete(
          organizationId: 'org-1',
          id: 'season-1',
          deletedBy: 'user-2',
        );
        final listResult = await repository.listByOrganization('org-1');

        expect(deleteResult, isA<AppSuccess<Season>>());
        expect((listResult as AppSuccess<List<Season>>).value, isEmpty);
      },
    );

    test('listByOrganization isolates by organization', () async {
      await repository.create(season: _season());
      await repository.create(season: _season(organizationId: 'org-2'));

      final result = await repository.listByOrganization('org-1');

      expect((result as AppSuccess<List<Season>>).value, hasLength(1));
    });
  });
}

Season _season({String organizationId = 'org-1'}) {
  final now = DateTime.utc(2026, 1, 1);
  return Season(
    id: 'season-1',
    organizationId: organizationId,
    name: 'Verão',
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}
