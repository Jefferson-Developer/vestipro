import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product_catalog_page.dart';
import '../../../products/domain/repositories/product_repository.dart';

/// Default page size `ProductGridBloc` requests, and every other caller of
/// [ListCatalogProductsUseCase] that does not need a different one.
const int kProductGridPageSize = 20;

/// Fetches one cursor-paginated page of the full product catalog (TASK-077)
/// via `ProductRepository.listCatalog` — the query behind the catalog's
/// visual grid, reusable by any screen that browses the whole catalog
/// (home's "ver tudo", busca, coleção, campanha, favoritos), never a
/// client-side scan of every Product.
@injectable
final class ListCatalogProductsUseCase {
  const ListCatalogProductsUseCase(this._productRepository);

  final ProductRepository _productRepository;

  Future<AppResult<ProductCatalogPage>> call({
    required String organizationId,
    String? companyId,
    String? cursor,
    int limit = kProductGridPageSize,
  }) {
    return _productRepository.listCatalog(
      organizationId: organizationId.trim(),
      companyId: companyId,
      cursor: cursor,
      limit: limit,
    );
  }
}
