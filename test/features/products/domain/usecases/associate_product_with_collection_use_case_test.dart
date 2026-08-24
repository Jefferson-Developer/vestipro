import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/products/products.dart';

class _InMemoryCollectionRepository implements CollectionRepository {
  final List<Collection> collections = <Collection>[];

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
    final index = collections.indexWhere((item) => item.id == id);
    final closed = collections[index].copyWith(status: CollectionStatus.closed);
    collections[index] = closed;
    return AppSuccess<Collection>(closed);
  }
}

class _InMemoryProductCollectionLinkRepository
    implements ProductCollectionLinkRepository {
  final List<ProductCollectionLink> links = <ProductCollectionLink>[];

  @override
  Future<AppResult<ProductCollectionLink>> create({
    required ProductCollectionLink link,
  }) async {
    links.add(link);
    return AppSuccess<ProductCollectionLink>(link);
  }

  @override
  Future<AppResult<List<ProductCollectionLink>>> listByProduct({
    required String organizationId,
    required String productId,
  }) async {
    return AppSuccess<List<ProductCollectionLink>>(
      links.where((link) => link.productId == productId).toList(),
    );
  }

  @override
  Future<AppResult<List<ProductCollectionLink>>> listByCollection({
    required String organizationId,
    required String collectionId,
  }) async {
    return AppSuccess<List<ProductCollectionLink>>(
      links.where((link) => link.collectionId == collectionId).toList(),
    );
  }

  @override
  Future<AppResult<bool>> deleteByProductAndCollection({
    required String organizationId,
    required String productId,
    required String collectionId,
  }) async {
    links.removeWhere(
      (link) =>
          link.productId == productId && link.collectionId == collectionId,
    );
    return const AppSuccess<bool>(true);
  }

  @override
  Future<AppResult<bool>> deleteAllByProduct({
    required String organizationId,
    required String productId,
  }) async {
    links.removeWhere((link) => link.productId == productId);
    return const AppSuccess<bool>(true);
  }
}

Collection _buildCollection({
  String id = 'collection-1',
  CollectionStatus status = CollectionStatus.active,
}) {
  return Collection(
    id: id,
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
  group('AssociateProductWithCollectionUseCase', () {
    late _InMemoryCollectionRepository collectionRepository;
    late _InMemoryProductCollectionLinkRepository linkRepository;
    late AssociateProductWithCollectionUseCase useCase;

    setUp(() {
      collectionRepository = _InMemoryCollectionRepository();
      linkRepository = _InMemoryProductCollectionLinkRepository();
      useCase = AssociateProductWithCollectionUseCase(
        linkRepository,
        collectionRepository,
      );
      collectionRepository.collections.add(_buildCollection());
      collectionRepository.collections.add(
        _buildCollection(id: 'collection-2'),
      );
    });

    test('single-collection mode (default): a second association replaces the '
        'first one instead of adding a second link', () async {
      final first = await useCase.call(
        id: 'link-1',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'collection-1',
        allowMultipleCollectionsPerProduct: false,
        createdBy: 'user-1',
      );
      expect(first, isA<AppSuccess<ProductCollectionLink>>());

      final second = await useCase.call(
        id: 'link-2',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'collection-2',
        allowMultipleCollectionsPerProduct: false,
        createdBy: 'user-1',
      );
      expect(second, isA<AppSuccess<ProductCollectionLink>>());

      expect(linkRepository.links, hasLength(1));
      expect(linkRepository.links.single.collectionId, 'collection-2');
    });

    test('multi-collection mode: a second association keeps the first link '
        'and adds a new one (N:N)', () async {
      await useCase.call(
        id: 'link-1',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'collection-1',
        allowMultipleCollectionsPerProduct: true,
        createdBy: 'user-1',
      );

      final second = await useCase.call(
        id: 'link-2',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'collection-2',
        allowMultipleCollectionsPerProduct: true,
        createdBy: 'user-1',
      );

      expect(second, isA<AppSuccess<ProductCollectionLink>>());
      expect(linkRepository.links, hasLength(2));
      expect(
        linkRepository.links.map((link) => link.collectionId),
        containsAll(<String>['collection-1', 'collection-2']),
      );
    });

    test('multi-collection mode: associating the same pair twice is rejected '
        'as a conflict instead of creating a duplicate link', () async {
      await useCase.call(
        id: 'link-1',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'collection-1',
        allowMultipleCollectionsPerProduct: true,
        createdBy: 'user-1',
      );

      final duplicate = await useCase.call(
        id: 'link-2',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'collection-1',
        allowMultipleCollectionsPerProduct: true,
        createdBy: 'user-1',
      );

      expect(duplicate, isA<AppFailure<ProductCollectionLink>>());
      expect(
        (duplicate as AppFailure<ProductCollectionLink>).failure,
        isA<ConflictFailure>(),
      );
      expect(linkRepository.links, hasLength(1));
    });

    test('rejects associating a product with a closed collection', () async {
      collectionRepository.collections[0] = _buildCollection(
        status: CollectionStatus.closed,
      );

      final result = await useCase.call(
        id: 'link-1',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'collection-1',
        allowMultipleCollectionsPerProduct: false,
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<ProductCollectionLink>>());
      expect(
        (result as AppFailure<ProductCollectionLink>).failure,
        isA<ConflictFailure>(),
      );
      expect(linkRepository.links, isEmpty);
    });

    test('fails for a collection that does not exist', () async {
      final result = await useCase.call(
        id: 'link-1',
        organizationId: 'org-1',
        productId: 'product-1',
        collectionId: 'missing-collection',
        allowMultipleCollectionsPerProduct: false,
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<ProductCollectionLink>>());
      expect(
        (result as AppFailure<ProductCollectionLink>).failure,
        isA<NotFoundFailure>(),
      );
    });
  });
}
