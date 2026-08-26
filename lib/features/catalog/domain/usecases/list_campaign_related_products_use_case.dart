import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';

/// Resolves a `CatalogCampaign.relatedProductIds` list into full `Product`s
/// (TASK-080), reused by both `CampaignFormBloc` (hydrating the admin
/// form's already-selected products) and `LookbookBloc` (the public
/// lookbook's related-products carousel) — a single source of truth for
/// "which of these ids still exist", so the two screens never disagree.
///
/// Delegates the "silently skip a stale/removed id" contract entirely to
/// `ProductRepository.getByIds` — a product deleted after being linked to a
/// campaign never blocks the rest of the carousel from loading.
@injectable
final class ListCampaignRelatedProductsUseCase {
  ListCampaignRelatedProductsUseCase(this._productRepository);

  final ProductRepository _productRepository;

  Future<AppResult<List<Product>>> call({
    required String organizationId,
    required List<String> productIds,
  }) {
    if (productIds.isEmpty) {
      return Future<AppResult<List<Product>>>.value(
        const AppSuccess<List<Product>>(<Product>[]),
      );
    }
    return _productRepository.getByIds(
      organizationId: organizationId.trim(),
      ids: productIds,
    );
  }
}
