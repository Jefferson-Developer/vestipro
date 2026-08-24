import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemorySeasonRepository implements SeasonRepository {
  final List<Season> seasons = <Season>[];
  final Set<String> seasonsInUse = <String>{};

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? excludingSeasonId,
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<Season>> create({required Season season}) async {
    seasons.add(season);
    return AppSuccess<Season>(season);
  }

  @override
  Future<AppResult<Season>> update({required Season season}) async {
    final index = seasons.indexWhere((item) => item.id == season.id);
    seasons[index] = season;
    return AppSuccess<Season>(season);
  }

  @override
  Future<AppResult<List<Season>>> listByOrganization(
    String organizationId,
  ) async => AppSuccess<List<Season>>(seasons);

  @override
  Future<AppResult<Season>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final season in seasons) {
      if (season.id == id) return AppSuccess<Season>(season);
    }
    return const AppFailure<Season>(
      NotFoundFailure('Season not found.', code: 'season_not_found'),
    );
  }

  @override
  Future<AppResult<bool>> hasCollections({
    required String organizationId,
    required String seasonId,
  }) async => AppSuccess<bool>(seasonsInUse.contains(seasonId));

  @override
  Future<AppResult<Season>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final index = seasons.indexWhere((item) => item.id == id);
    if (index == -1) {
      return const AppFailure<Season>(
        NotFoundFailure('Season not found.', code: 'season_not_found'),
      );
    }
    final deleted = seasons[index].copyWith(
      deletedAt: DateTime.utc(2026, 1, 2),
      updatedBy: deletedBy,
    );
    seasons[index] = deleted;
    return AppSuccess<Season>(deleted);
  }
}

Season _buildSeason({String id = 'season-1'}) {
  return Season(
    id: id,
    organizationId: 'org-1',
    name: 'Verão',
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
  );
}

void main() {
  group('DeleteSeasonUseCase', () {
    late _InMemorySeasonRepository repository;
    late DeleteSeasonUseCase useCase;

    setUp(() {
      repository = _InMemorySeasonRepository();
      useCase = DeleteSeasonUseCase(repository);
      repository.seasons.add(_buildSeason());
    });

    test('soft-deletes a season with no collection referencing it', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'season-1',
        deletedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Season>>());
      expect((result as AppSuccess<Season>).value.deletedAt, isNotNull);
    });

    test(
      'blocks deletion when a collection still references the season',
      () async {
        repository.seasonsInUse.add('season-1');

        final result = await useCase.call(
          organizationId: 'org-1',
          id: 'season-1',
          deletedBy: 'user-2',
        );

        expect(result, isA<AppFailure<Season>>());
        expect((result as AppFailure<Season>).failure, isA<ConflictFailure>());
        expect(repository.seasons.single.deletedAt, isNull);
      },
    );
  });
}
