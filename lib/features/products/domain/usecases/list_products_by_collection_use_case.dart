import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../entities/product_collection_link.dart';
import '../repositories/product_collection_link_repository.dart';
import '../repositories/product_repository.dart';

/// Lists every Product associated with a `Collection` (TASK-066), via
/// `ProductCollectionLink` — the same join data a future catalog filter
/// (EPIC-10) reuses, so cadastro and vitrine never keep two separate
/// sources of truth for "which products belong to this collection".
@injectable
final class ListProductsByCollectionUseCase {
  ListProductsByCollectionUseCase(
    this._linkRepository,
    this._productRepository,
  );

  final ProductCollectionLinkRepository _linkRepository;
  final ProductRepository _productRepository;

  Future<AppResult<List<Product>>> call({
    required String organizationId,
    required String collectionId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCollectionId = collectionId.trim();

    if (trimmedOrganizationId.isEmpty || trimmedCollectionId.isEmpty) {
      return const AppFailure<List<Product>>(
        ValidationFailure(
          'Invalid list-products-by-collection payload.',
          code: 'invalid_list_products_by_collection_payload',
        ),
      );
    }

    final linksResult = await _linkRepository.listByCollection(
      organizationId: trimmedOrganizationId,
      collectionId: trimmedCollectionId,
    );
    if (linksResult is AppFailure<List<ProductCollectionLink>>) {
      return AppFailure<List<Product>>(linksResult.failure);
    }
    final productIds = (linksResult as AppSuccess<List<ProductCollectionLink>>)
        .value
        .map((link) => link.productId)
        .toSet()
        .toList(growable: false);

    if (productIds.isEmpty) {
      return const AppSuccess<List<Product>>(<Product>[]);
    }

    return _productRepository.getByIds(
      organizationId: trimmedOrganizationId,
      ids: productIds,
    );
  }
}
