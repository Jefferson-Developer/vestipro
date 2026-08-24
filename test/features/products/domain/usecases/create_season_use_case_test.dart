import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemorySeasonRepository implements SeasonRepository {
  final List<Season> seasons = <Season>[];
  final Set<String> seasonsInUse = <String>{};

  void seed(Season season) => seasons.add(season);

  @override
  Future<AppResult<bool>> existsByName({
    required String organizationId,
    required String name,
    String? excludingSeasonId,
  }) async {
    final normalized = name.trim().toLowerCase();
    return AppSuccess<bool>(
      seasons.any(
        (season) =>
            season.deletedAt == null &&
            season.name.trim().toLowerCase() == normalized &&
            season.id != excludingSeasonId,
      ),
    );
  }

  @override
  Future<AppResult<Season>> create({required Season season}) async {
    seasons.add(season);
    return AppSuccess<Season>(season);
  }

  @override
  Future<AppResult<Season>> update({required Season season}) async {
    final index = seasons.indexWhere((item) => item.id == season.id);
    if (index == -1) {
      return const AppFailure<Season>(
        NotFoundFailure('Season not found.', code: 'season_not_found'),
      );
    }
    seasons[index] = season;
    return AppSuccess<Season>(season);
  }

  @override
  Future<AppResult<List<Season>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<Season>>(
      seasons.where((season) => season.deletedAt == null).toList(),
    );
  }

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
  }) async {
    return AppSuccess<bool>(seasonsInUse.contains(seasonId));
  }

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

void main() {
  group('CreateSeasonUseCase', () {
    late _InMemorySeasonRepository repository;
    late CreateSeasonUseCase useCase;

    setUp(() {
      repository = _InMemorySeasonRepository();
      useCase = CreateSeasonUseCase(repository);
    });

    test('creates a season with the trimmed name', () async {
      final result = await useCase.call(
        id: 'season-1',
        organizationId: 'org-1',
        name: '  Verão  ',
        createdBy: 'user-1',
      );

      expect(result, isA<AppSuccess<Season>>());
      final season = (result as AppSuccess<Season>).value;
      expect(season.name, 'Verão');
      expect(season.version, 1);
      expect(repository.seasons.single.id, 'season-1');
    });

    test('rejects a blank name without touching the repository', () async {
      final result = await useCase.call(
        id: 'season-1',
        organizationId: 'org-1',
        name: '   ',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Season>>());
      final failure = (result as AppFailure<Season>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('name', isNotEmpty),
      );
      expect(repository.seasons, isEmpty);
    });

    test(
      'blocks a duplicate season name (case-insensitive, trimmed)',
      () async {
        repository.seed(
          Season(
            id: 'existing',
            organizationId: 'org-1',
            name: 'Verão',
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'user-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'user-1',
          ),
        );

        final result = await useCase.call(
          id: 'season-2',
          organizationId: 'org-1',
          name: ' verão ',
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<Season>>());
        expect((result as AppFailure<Season>).failure, isA<ConflictFailure>());
        expect(repository.seasons, hasLength(1));
      },
    );
  });
}
