import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('CollectionFormBloc', () {
    late _InMemoryCollectionRepository collectionRepository;
    late _InMemorySeasonRepository seasonRepository;

    setUp(() {
      collectionRepository = _InMemoryCollectionRepository();
      seasonRepository = _InMemorySeasonRepository();
      seasonRepository.seasons.add(
        Season(
          id: 'season-1',
          organizationId: 'org-1',
          name: 'Verão',
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
        ),
      );
    });

    CollectionFormBloc buildBloc() {
      return CollectionFormBloc(
        listSeasons: ListSeasonsUseCase(seasonRepository),
        createCollection: CreateCollectionUseCase(collectionRepository),
        updateCollection: UpdateCollectionUseCase(collectionRepository),
      );
    }

    test('creates a new collection with the selected season', () async {
      final bloc = buildBloc()
        ..add(
          const CollectionFormStarted(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        );
      await _drainBloc();

      bloc
        ..add(const CollectionFormNameChanged('Verão 2026'))
        ..add(const CollectionFormSeasonSelected('season-1'))
        ..add(const CollectionFormYearChanged(2026))
        ..add(const CollectionFormSubmitted());
      await _drainBloc();

      expect(
        bloc.state.submissionStatus,
        CollectionFormSubmissionStatus.success,
      );
      expect(bloc.state.savedCollection?.name, 'Verão 2026');
      expect(bloc.state.savedCollection?.status, CollectionStatus.active);
      expect(collectionRepository.collections, hasLength(1));
      await bloc.close();
    });

    test('rejects submitting without a name', () async {
      final bloc = buildBloc()
        ..add(
          const CollectionFormStarted(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        );
      await _drainBloc();

      bloc.add(const CollectionFormSubmitted());
      await _drainBloc();

      expect(
        bloc.state.submissionStatus,
        CollectionFormSubmissionStatus.failure,
      );
      expect(bloc.state.fieldErrors, containsPair('name', isNotEmpty));
      expect(collectionRepository.collections, isEmpty);
      await bloc.close();
    });

    test('edits an existing collection, preserving its status', () async {
      final existing = Collection(
        id: 'collection-1',
        organizationId: 'org-1',
        name: 'Verão 2026',
        status: CollectionStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
      collectionRepository.collections.add(existing);

      final bloc = buildBloc()
        ..add(
          CollectionFormStarted(
            organizationId: 'org-1',
            userId: 'user-2',
            initialCollection: existing,
          ),
        );
      await _drainBloc();

      bloc
        ..add(const CollectionFormNameChanged('Verão 2026 - Renomeada'))
        ..add(const CollectionFormSubmitted());
      await _drainBloc();

      expect(
        bloc.state.submissionStatus,
        CollectionFormSubmissionStatus.success,
      );
      expect(bloc.state.savedCollection?.name, 'Verão 2026 - Renomeada');
      expect(bloc.state.savedCollection?.status, CollectionStatus.active);
      expect(bloc.state.savedCollection?.version, 2);
      await bloc.close();
    });
  });
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _InMemoryCollectionRepository implements CollectionRepository {
  final List<Collection> collections = <Collection>[];

  @override
  Future<AppResult<Collection>> create({required Collection collection}) async {
    collections.add(collection);
    return AppSuccess<Collection>(collection);
  }

  @override
  Future<AppResult<Collection>> update({required Collection collection}) async {
    final index = collections.indexWhere((item) => item.id == collection.id);
    if (index == -1) {
      return const AppFailure<Collection>(
        NotFoundFailure('Collection not found.', code: 'collection_not_found'),
      );
    }
    collections[index] = collection;
    return AppSuccess<Collection>(collection);
  }

  @override
  Future<AppResult<List<Collection>>> listByOrganization(
    String organizationId,
  ) async => AppSuccess<List<Collection>>(collections);

  @override
  Future<AppResult<Collection>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final collection in collections) {
      if (collection.id == id) return AppSuccess<Collection>(collection);
    }
    return const AppFailure<Collection>(
      NotFoundFailure('Collection not found.', code: 'collection_not_found'),
    );
  }

  @override
  Future<AppResult<Collection>> close({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    final index = collections.indexWhere((item) => item.id == id);
    final closed = collections[index].copyWith(status: CollectionStatus.closed);
    collections[index] = closed;
    return AppSuccess<Collection>(closed);
  }
}

final class _InMemorySeasonRepository implements SeasonRepository {
  final List<Season> seasons = <Season>[];

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
  }) async => const AppSuccess<bool>(false);

  @override
  Future<AppResult<Season>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) async {
    final index = seasons.indexWhere((item) => item.id == id);
    final deleted = seasons[index].copyWith(
      deletedAt: DateTime.utc(2026, 1, 2),
    );
    seasons[index] = deleted;
    return AppSuccess<Season>(deleted);
  }
}
