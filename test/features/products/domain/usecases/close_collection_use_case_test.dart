import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryCollectionRepository implements CollectionRepository {
  final List<Collection> collections = <Collection>[];
  int closeCallCount = 0;

  @override
  Future<AppResult<Collection>> create({required Collection collection}) async {
    collections.add(collection);
    return AppSuccess<Collection>(collection);
  }

  @override
  Future<AppResult<Collection>> update({required Collection collection}) async {
    final index = collections.indexWhere((item) => item.id == collection.id);
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
    closeCallCount++;
    final index = collections.indexWhere((item) => item.id == id);
    final closed = collections[index].copyWith(
      status: CollectionStatus.closed,
      updatedBy: updatedBy,
    );
    collections[index] = closed;
    return AppSuccess<Collection>(closed);
  }
}

Collection _buildCollection({
  CollectionStatus status = CollectionStatus.active,
}) {
  return Collection(
    id: 'collection-1',
    organizationId: 'org-1',
    name: 'Verão 2026',
    status: status,
    version: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'user-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'user-1',
  );
}

void main() {
  group('CloseCollectionUseCase', () {
    late _InMemoryCollectionRepository repository;
    late CloseCollectionUseCase useCase;

    setUp(() {
      repository = _InMemoryCollectionRepository();
      useCase = CloseCollectionUseCase(repository);
    });

    test('closes an active collection', () async {
      repository.collections.add(_buildCollection());

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'collection-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Collection>>());
      expect(
        (result as AppSuccess<Collection>).value.status,
        CollectionStatus.closed,
      );
      expect(repository.closeCallCount, 1);
    });

    test('is idempotent for an already-closed collection', () async {
      repository.collections.add(
        _buildCollection(status: CollectionStatus.closed),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'collection-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Collection>>());
      expect(repository.closeCallCount, 0);
    });

    test('fails for a collection that does not exist', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'missing',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Collection>>());
      expect(
        (result as AppFailure<Collection>).failure,
        isA<NotFoundFailure>(),
      );
    });
  });
}
