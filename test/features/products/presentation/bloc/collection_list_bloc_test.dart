import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

void main() {
  group('CollectionListBloc', () {
    late _InMemoryCollectionRepository repository;

    setUp(() {
      repository = _InMemoryCollectionRepository();
    });

    CollectionListBloc buildBloc() {
      return CollectionListBloc(
        listCollections: ListCollectionsUseCase(repository),
        closeCollection: CloseCollectionUseCase(repository),
      );
    }

    Collection buildCollection({
      String id = 'collection-1',
      CollectionStatus status = CollectionStatus.active,
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return Collection(
        id: id,
        organizationId: 'org-1',
        name: 'Verão 2026',
        status: status,
        version: 1,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
      );
    }

    test('loads the collections of the organization', () async {
      repository.collections.add(buildCollection());

      final bloc = buildBloc()
        ..add(
          const CollectionListStarted(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        );
      await _drainBloc();

      expect(bloc.state.loadStatus, CollectionListLoadStatus.ready);
      expect(bloc.state.collections, hasLength(1));
      await bloc.close();
    });

    test('closes an active collection and reflects the new status without a '
        'full reload', () async {
      final collection = buildCollection();
      repository.collections.add(collection);

      final bloc = buildBloc()
        ..add(
          const CollectionListStarted(
            organizationId: 'org-1',
            userId: 'user-2',
          ),
        );
      await _drainBloc();

      bloc.add(CollectionListCloseRequested(collection));
      await _drainBloc();

      expect(bloc.state.closeStatus, CollectionListCloseStatus.idle);
      expect(bloc.state.collections.single.status, CollectionStatus.closed);
      expect(repository.collections.single.status, CollectionStatus.closed);
      await bloc.close();
    });

    test('reports a failure loading the collections', () async {
      repository.shouldFail = true;

      final bloc = buildBloc()
        ..add(
          const CollectionListStarted(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        );
      await _drainBloc();

      expect(bloc.state.loadStatus, CollectionListLoadStatus.failure);
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
  bool shouldFail = false;

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
  ) async {
    if (shouldFail) {
      return const AppFailure<List<Collection>>(
        UnexpectedFailure('Boom.', code: 'boom'),
      );
    }
    return AppSuccess<List<Collection>>(collections);
  }

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
