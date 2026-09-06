import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/favorites/favorites.dart';

class _InMemoryFavoriteRepository implements FavoriteRepository {
  final List<FavoriteProduct> favorites = <FavoriteProduct>[];
  int addCallCount = 0;

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
    addCallCount++;
    final existing = favorites.where(
      (favorite) =>
          favorite.organizationId == organizationId &&
          favorite.userId == userId &&
          favorite.productId == productId,
    );
    if (existing.isNotEmpty) {
      return AppSuccess<FavoriteProduct>(existing.first);
    }
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
  group('AddFavoriteProductUseCase', () {
    late _InMemoryFavoriteRepository repository;
    late AddFavoriteProductUseCase useCase;

    setUp(() {
      repository = _InMemoryFavoriteRepository();
      useCase = AddFavoriteProductUseCase(repository);
    });

    test('favorites a product, trimming ids before delegating', () async {
      final result = await useCase.call(
        organizationId: ' org-1 ',
        userId: ' user-1 ',
        productId: ' product-1 ',
        companyId: 'company-1',
      );

      expect(result, isA<AppSuccess<FavoriteProduct>>());
      final favorite = (result as AppSuccess<FavoriteProduct>).value;
      expect(favorite.organizationId, 'org-1');
      expect(favorite.userId, 'user-1');
      expect(favorite.productId, 'product-1');
      expect(favorite.companyId, 'company-1');
    });

    test('is idempotent: favoriting the same product twice never creates a '
        'duplicate row', () async {
      await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: 'product-1',
      );
      final second = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: 'product-1',
      );

      expect(second, isA<AppSuccess<FavoriteProduct>>());
      expect(repository.favorites, hasLength(1));
      expect(repository.addCallCount, 2);
    });

    test('rejects an empty organizationId with a ValidationFailure', () async {
      final result = await useCase.call(
        organizationId: '   ',
        userId: 'user-1',
        productId: 'product-1',
      );

      expect(result, isA<AppFailure<FavoriteProduct>>());
      final failure = (result as AppFailure<FavoriteProduct>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).code,
        'invalid_add_favorite_payload',
      );
      expect(repository.addCallCount, 0);
    });

    test('rejects an empty userId with a ValidationFailure', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        userId: '',
        productId: 'product-1',
      );

      expect(result, isA<AppFailure<FavoriteProduct>>());
      expect(repository.addCallCount, 0);
    });

    test('rejects an empty productId with a ValidationFailure', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        userId: 'user-1',
        productId: '   ',
      );

      expect(result, isA<AppFailure<FavoriteProduct>>());
      expect(repository.addCallCount, 0);
    });
  });
}
