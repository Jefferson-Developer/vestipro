import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../entities/catalog_home_item.dart';
import '../entities/catalog_home_section.dart';
import '../entities/catalog_home_section_config.dart';

/// Builds the catalog home's "lançamentos" section (TASK-076) from the most
/// recently launched active `Product`s of [organizationId]/[companyId],
/// via `ProductRepository.listRecentlyLaunched` — server/repository-side
/// ordering, never a client-side scan of every product (TASK-076 business
/// rule).
@injectable
final class GetNewArrivalsSectionUseCase {
  GetNewArrivalsSectionUseCase(this._productRepository);

  final ProductRepository _productRepository;

  Future<AppResult<CatalogHomeSection>> call({
    required String organizationId,
    String? companyId,
    required CatalogHomeSectionConfig config,
  }) async {
    final result = await _productRepository.listRecentlyLaunched(
      organizationId: organizationId.trim(),
      companyId: companyId,
      limit: config.itemLimit,
    );

    return result.fold(
      onSuccess: (products) => AppSuccess<CatalogHomeSection>(
        CatalogHomeSection(
          type: config.type,
          title: config.title,
          order: config.order,
          priority: config.priority,
          items: products.map(_toItem).toList(growable: false),
        ),
      ),
      onFailure: (failure) => AppFailure<CatalogHomeSection>(failure),
    );
  }

  CatalogHomeItem _toItem(Product product) {
    final principalPhoto = product.principalPhoto;
    return CatalogHomeItem(
      id: product.id,
      title: product.name,
      subtitle: product.brand,
      imageUrl: principalPhoto?.thumbnailUrl ?? principalPhoto?.url,
      badgeLabel: 'Lançamento',
    );
  }
}
