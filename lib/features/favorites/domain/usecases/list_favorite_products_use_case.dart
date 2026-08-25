import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/entities/variant_availability.dart';
import '../../../products/domain/entities/variant_availability_snapshot.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../products/domain/usecases/get_variant_availability_use_case.dart';
import '../entities/favorite_catalog_page.dart';
import '../entities/favorite_product_page.dart';
import '../repositories/favorite_repository.dart';

/// Loads one page of the signed-in user's favorited products, already
/// hydrated and availability-resolved (TASK-079) — the single call
/// `FavoritesBloc` needs to render the favorites screen through the same
/// `AppProductGrid`/`AppProductCardData` the catalog grid (TASK-077) uses.
///
/// Composes [FavoriteRepository.listFavorites] (which id`s are favorited,
/// local-first) with [ProductRepository.getByIds] (what those products
/// currently are) exactly like `ListProductsByCollectionUseCase` composes
/// `ProductCollectionLinkRepository` with the same [ProductRepository] — a
/// favorited id that no longer resolves to an existing Product is silently
/// dropped by `getByIds` (never a broken card), and counted into
/// [FavoriteCatalogPage.unavailableCount] so the screen can say so
/// explicitly instead of pretending nothing happened.
@injectable
final class ListFavoriteProductsUseCase {
  const ListFavoriteProductsUseCase(
    this._favoriteRepository,
    this._productRepository,
    this._getVariantAvailability,
  );

  final FavoriteRepository _favoriteRepository;
  final ProductRepository _productRepository;
  final GetVariantAvailabilityUseCase _getVariantAvailability;

  Future<AppResult<FavoriteCatalogPage>> call({
    required String organizationId,
    required String userId,
    int offset = 0,
    int limit = 20,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    if (trimmedOrganizationId.isEmpty || trimmedUserId.isEmpty) {
      return const AppFailure<FavoriteCatalogPage>(
        ValidationFailure(
          'Invalid list-favorite-products payload.',
          code: 'invalid_list_favorite_products_payload',
        ),
      );
    }

    final pageResult = await _favoriteRepository.listFavorites(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      offset: offset,
      limit: limit,
    );
    if (pageResult is AppFailure<FavoriteProductPage>) {
      return AppFailure<FavoriteCatalogPage>(pageResult.failure);
    }
    final page = (pageResult as AppSuccess<FavoriteProductPage>).value;
    final favoriteIds = page.items
        .map((favorite) => favorite.productId)
        .toList(growable: false);

    if (favoriteIds.isEmpty) {
      return AppSuccess<FavoriteCatalogPage>(
        FavoriteCatalogPage(
          products: const <Product>[],
          availabilityByProductId: const <String, VariantAvailability>{},
          hasMore: page.hasMore,
          nextOffset: offset + limit,
          unavailableCount: 0,
        ),
      );
    }

    final productsResult = await _productRepository.getByIds(
      organizationId: trimmedOrganizationId,
      ids: favoriteIds,
    );
    if (productsResult is AppFailure<List<Product>>) {
      return AppFailure<FavoriteCatalogPage>(productsResult.failure);
    }
    final productsById = {
      for (final product in (productsResult as AppSuccess<List<Product>>).value)
        product.id: product,
    };

    // Preserves the favorited (newest-first) order and drops any id that no
    // longer resolves to an existing Product instead of ever rendering a
    // broken card for it.
    final orderedProducts = favoriteIds
        .map((id) => productsById[id])
        .whereType<Product>()
        .toList(growable: false);

    final availability = await _fetchAvailability(
      trimmedOrganizationId,
      orderedProducts,
    );

    return AppSuccess<FavoriteCatalogPage>(
      FavoriteCatalogPage(
        products: orderedProducts,
        availabilityByProductId: availability,
        hasMore: page.hasMore,
        nextOffset: offset + limit,
        unavailableCount: favoriteIds.length - orderedProducts.length,
      ),
    );
  }

  Future<Map<String, VariantAvailability>> _fetchAvailability(
    String organizationId,
    List<Product> products,
  ) async {
    if (products.isEmpty) return const <String, VariantAvailability>{};
    final result = await _getVariantAvailability(
      organizationId: organizationId,
      productIds: products.map((product) => product.id),
    );
    return switch (result) {
      AppSuccess<VariantAvailabilitySnapshot>(value: final snapshot) =>
        <String, VariantAvailability>{
          for (final product in products)
            product.id: ?snapshot.primaryForProduct(product.id),
        },
      // Availability failing to load never fails the whole favorites screen
      // — same precedent `ProductGridBloc._fetchAvailability` already set.
      AppFailure<VariantAvailabilitySnapshot>() =>
        const <String, VariantAvailability>{},
    };
  }
}
