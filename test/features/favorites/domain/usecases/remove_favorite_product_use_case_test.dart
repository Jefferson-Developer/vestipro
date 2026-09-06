import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/favorites.dart';

class _InMemoryFavoriteRepository implements FavoriteRepository {
  final List<FavoriteProduct> favorites = <FavoriteProduct>[];
  int removeCallCount = 0;

  @override
  Stream<Set<String>> watchFavoriteProductIds({
    required String organizationId,
    required String userId,
  }) {
    return Stream<Set<String>>.value(
      favorites.map((favorite) => favorite.productId).toSet(),
    );
  }

  @override
  Future<AppResult<FavoriteProduct>> addFavorite({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  }) async {
    final favorite = FavoriteProduct(
      productId: productId,
      userId: userId,
      organizationId: organizationId,
      companyId: companyId,
      createdAt: DateTime.utc(2026, 1, 1),
      syncStatus: FavoriteSyncStatus.pending,
    );
    favorites.add(favorite);
    return AppSuccess<FavoriteProduct>(favorite);
  }

  @override
  Future<AppResult<void>> removeFavorite({
    required String organizationId,
    required String userId,
    required String productId,
  }) async {
    removeCallCount++;
    favorites.removeWhere((favorite) => favorite.productId == productId);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<FavoriteProductPage>> listFavorites({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  }) async {
    return AppSuccess<FavoriteProductPage>(
      FavoriteProductPage(items: favorites, hasMore: false),
    );
  }
}

void main() {
  group('RemoveFavoriteProductUseCase', () {
    late _InMemoryFavoriteRepository repository;
    late RemoveFavoriteProductUseCase useCase;

    setUp(() {
      repository = _InMemoryFavoriteRepository();
      useCase = RemoveFavoriteProductUseCase(repository);
    });

    test('unfavorites a product, trimming ids before delegating', () async {
      await repository.addFavorite(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: 'product-1',
      );

      final result = await useCase.call(
        organizationId: ' org-1 ',
        userId: ' user-1 ',
        productId: ' product-1 ',
      );

      expect(result, isA<AppSuccess<void>>());
      expect(repository.favorites, isEmpty);
    });

    test(
      'unfavoriting a product that was never favorited is a no-op, never '
      'a failure (a duplicated/late tap after unfavorite already landed)',
      () async {
        final result = await useCase.call(
          organizationId: 'org-1',
          userId: 'user-1',
          productId: 'product-never-favorited',
        );

        expect(result, isA<AppSuccess<void>>());
        expect(repository.removeCallCount, 1);
      },
    );

    test('rejects an empty organizationId with a ValidationFailure', () async {
      final result = await useCase.call(
        organizationId: '',
        userId: 'user-1',
        productId: 'product-1',
      );

      expect(result, isA<AppFailure<void>>());
      final failure = (result as AppFailure<void>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).code,
        'invalid_remove_favorite_payload',
      );
      expect(repository.removeCallCount, 0);
    });

    test('rejects an empty productId with a ValidationFailure', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: '   ',
      );

      expect(result, isA<AppFailure<void>>());
      expect(repository.removeCallCount, 0);
    });
  });
}
