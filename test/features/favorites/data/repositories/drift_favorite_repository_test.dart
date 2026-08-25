import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/data/datasources/favorite_remote_data_source.dart';
import 'package:vestipro/features/favorites/data/mappers/favorite_local_mapper.dart';
import 'package:vestipro/features/favorites/data/repositories/drift_favorite_repository.dart';
import 'package:vestipro/features/favorites/favorites.dart';

void main() {
  group('DriftFavoriteRepository', () {
    late AppDatabase database;
    late _FakeFavoriteRemoteDataSource remote;
    late DriftFavoriteRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      remote = _FakeFavoriteRemoteDataSource();
      repository = DriftFavoriteRepository(
        database,
        const FavoriteLocalMapper(),
        remote,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('favorites a product and it shows up in listFavorites', () async {
      final addResult = await repository.addFavorite(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: 'product-1',
      );
      expect(addResult, isA<AppSuccess<FavoriteProduct>>());

      final page = await _favoritesPage(repository, userId: 'user-1');
      expect(page.items.map((favorite) => favorite.productId), <String>[
        'product-1',
      ]);
      expect(page.hasMore, isFalse);
    });

    test(
      'favoriting an already-favorited product is idempotent — no duplicate '
      'row even with repeated taps before a previous write "lands"',
      () async {
        await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );

        final page = await _favoritesPage(repository, userId: 'user-1');
        expect(page.items, hasLength(1));
      },
    );

    test(
      'unfavoriting removes it from listFavorites, and unfavoriting again is '
      'a no-op success (not a failure)',
      () async {
        await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );

        final removeResult = await repository.removeFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        expect(removeResult, isA<AppSuccess<void>>());
        expect((await _favoritesPage(repository, userId: 'user-1')).items, isEmpty);

        final secondRemove = await repository.removeFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        expect(secondRemove, isA<AppSuccess<void>>());
      },
    );

    test('listFavorites returns an empty page when nothing is favorited', () async {
      final page = await _favoritesPage(repository, userId: 'user-1');
      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('listFavorites paginates without losing or duplicating a product', () async {
      for (var index = 1; index <= 5; index++) {
        await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-$index',
        );
      }

      final firstPage = await _favoritesPage(
        repository,
        userId: 'user-1',
        limit: 2,
      );
      expect(firstPage.items, hasLength(2));
      expect(firstPage.hasMore, isTrue);

      final secondPage = await _favoritesPage(
        repository,
        userId: 'user-1',
        offset: 2,
        limit: 2,
      );
      expect(secondPage.items, hasLength(2));
      expect(secondPage.hasMore, isTrue);

      final thirdPage = await _favoritesPage(
        repository,
        userId: 'user-1',
        offset: 4,
        limit: 2,
      );
      expect(thirdPage.items, hasLength(1));
      expect(thirdPage.hasMore, isFalse);

      final everyIdSeen = <String>{
        for (final page in [firstPage, secondPage, thirdPage])
          for (final favorite in page.items) favorite.productId,
      };
      expect(everyIdSeen, hasLength(5));
    });

    test(
      'favoriting while the remote push fails ("offline") still favorites '
      'locally right away, independent of the remote call',
      () async {
        remote.failUpserts = true;

        final result = await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        expect(result, isA<AppSuccess<FavoriteProduct>>());
        expect((await _favoritesPage(repository, userId: 'user-1')).items, hasLength(1));

        await Future<void>.delayed(Duration.zero);
        expect(remote.upsertAttempts, greaterThanOrEqualTo(1));
      },
    );

    test(
      'a favorite created offline syncs to the remote store once it stops '
      'failing (simulating reconnection)',
      () async {
        remote.failUpserts = true;
        await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        await Future<void>.delayed(Duration.zero);
        expect(remote.upserted, isEmpty);

        remote.failUpserts = false;
        // Every read (watchFavoriteProductIds) opportunistically drains
        // whatever is still locally pending — this is the "sync when back
        // online" trigger this feature uses instead of a dedicated
        // connectivity listener.
        final subscription = repository
            .watchFavoriteProductIds(organizationId: 'org-1', userId: 'user-1')
            .listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await subscription.cancel();

        expect(
          remote.upserted.map((favorite) => favorite.productId),
          contains('product-1'),
        );
      },
    );

    test(
      'a failed remote sync never loses the local favorite — it stays '
      'favorited locally regardless of how many sync attempts fail',
      () async {
        remote.failUpserts = true;
        final result = await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        expect(result, isA<AppSuccess<FavoriteProduct>>());
        await Future<void>.delayed(Duration.zero);

        // Draining pending sync again (still failing) must not remove the
        // local row.
        final subscription = repository
            .watchFavoriteProductIds(organizationId: 'org-1', userId: 'user-1')
            .listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await subscription.cancel();

        final page = await _favoritesPage(repository, userId: 'user-1');
        expect(page.items.map((favorite) => favorite.productId), <String>[
          'product-1',
        ]);
      },
    );

    test(
      'an unfavorite made while the remote delete fails keeps the product '
      'out of listFavorites locally (never resurrects it)',
      () async {
        await repository.addFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        remote.failDeletes = true;

        final removeResult = await repository.removeFavorite(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-1',
        );
        expect(removeResult, isA<AppSuccess<void>>());
        await Future<void>.delayed(Duration.zero);

        expect((await _favoritesPage(repository, userId: 'user-1')).items, isEmpty);
      },
    );

    test('favorites never leak between organizations (multi-tenant isolation)', () async {
      await repository.addFavorite(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: 'product-1',
      );
      await repository.addFavorite(
        organizationId: 'org-2',
        userId: 'user-1',
        productId: 'product-1',
      );

      final org1Page = await _favoritesPage(
        repository,
        organizationId: 'org-1',
        userId: 'user-1',
      );
      final org2Page = await _favoritesPage(
        repository,
        organizationId: 'org-2',
        userId: 'user-1',
      );
      expect(org1Page.items, hasLength(1));
      expect(org2Page.items, hasLength(1));

      await repository.removeFavorite(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: 'product-1',
      );
      // Removing from org-1 must never touch org-2's favorite of the same
      // product id.
      expect(
        (await _favoritesPage(repository, organizationId: 'org-2', userId: 'user-1'))
            .items,
        hasLength(1),
      );
    });

    test('favorites never leak between users of the same organization', () async {
      await repository.addFavorite(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: 'product-1',
      );

      final otherUserPage = await _favoritesPage(
        repository,
        userId: 'user-2',
      );
      expect(otherUserPage.items, isEmpty);
    });
  });
}

Future<FavoriteProductPage> _favoritesPage(
  DriftFavoriteRepository repository, {
  String organizationId = 'org-1',
  required String userId,
  int offset = 0,
  int limit = 20,
}) async {
  final result = await repository.listFavorites(
    organizationId: organizationId,
    userId: userId,
    offset: offset,
    limit: limit,
  );
  return (result as AppSuccess<FavoriteProductPage>).value;
}

final class _FakeFavoriteRemoteDataSource implements FavoriteRemoteDataSource {
  bool failUpserts = false;
  bool failDeletes = false;
  int upsertAttempts = 0;
  final List<FavoriteProduct> upserted = <FavoriteProduct>[];
  final List<String> deletedProductIds = <String>[];

  @override
  Future<void> upsert(FavoriteProduct favorite) async {
    upsertAttempts++;
    if (failUpserts) {
      throw Exception('Simulated offline/remote failure.');
    }
    upserted.add(favorite);
  }

  @override
  Future<void> delete({
    required String organizationId,
    required String userId,
    required String productId,
  }) async {
    if (failDeletes) {
      throw Exception('Simulated offline/remote failure.');
    }
    deletedProductIds.add(productId);
  }
}
