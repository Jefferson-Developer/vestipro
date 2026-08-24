import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryCollectionRepository implements CollectionRepository {
  final List<Collection> collections = <Collection>[];

  void seed(Collection collection) => collections.add(collection);

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
    final closed = collections[index].copyWith(
      status: CollectionStatus.closed,
      updatedBy: updatedBy,
    );
    collections[index] = closed;
    return AppSuccess<Collection>(closed);
  }
}

void main() {
  group('CreateCollectionUseCase', () {
    late _InMemoryCollectionRepository repository;
    late CreateCollectionUseCase useCase;

    setUp(() {
      repository = _InMemoryCollectionRepository();
      useCase = CreateCollectionUseCase(repository);
    });

    test('creates a collection always as active', () async {
      final result = await useCase.call(
        id: 'collection-1',
        organizationId: 'org-1',
        name: 'Verão 2026',
        seasonId: 'season-1',
        year: 2026,
        createdBy: 'user-1',
      );

      expect(result, isA<AppSuccess<Collection>>());
      final collection = (result as AppSuccess<Collection>).value;
      expect(collection.status, CollectionStatus.active);
      expect(collection.isActive, isTrue);
      expect(collection.version, 1);
      expect(repository.collections.single.id, 'collection-1');
    });

    test('rejects a blank name without touching the repository', () async {
      final result = await useCase.call(
        id: 'collection-1',
        organizationId: 'org-1',
        name: '   ',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Collection>>());
      expect(
        (result as AppFailure<Collection>).failure,
        isA<ValidationFailure>(),
      );
      expect(repository.collections, isEmpty);
    });

    test('rejects an end date before the start date', () async {
      final result = await useCase.call(
        id: 'collection-1',
        organizationId: 'org-1',
        name: 'Verão 2026',
        startDate: DateTime.utc(2026, 6, 1),
        endDate: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Collection>>());
      final failure =
          (result as AppFailure<Collection>).failure as ValidationFailure;
      expect(failure.fieldErrors, containsPair('endDate', isNotEmpty));
    });

    test('rejects an out-of-range year', () async {
      final result = await useCase.call(
        id: 'collection-1',
        organizationId: 'org-1',
        name: 'Verão 2026',
        year: 1800,
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Collection>>());
      final failure =
          (result as AppFailure<Collection>).failure as ValidationFailure;
      expect(failure.fieldErrors, containsPair('year', isNotEmpty));
    });
  });
}
