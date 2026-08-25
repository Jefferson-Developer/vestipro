import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_variant.dart';
import '../repositories/product_variant_repository.dart';

/// Lists every [ProductVariant] generated for one Product (TASK-072),
/// scoped to [organizationId] — the read path `ProductDetailBloc` (TASK-078)
/// uses to build the color/size grid of a product's detail screen, on top
/// of the same `ProductVariantRepository.listByProduct` contract
/// `GenerateProductVariantsUseCase` already relies on internally.
@injectable
final class ListProductVariantsByProductUseCase {
  const ListProductVariantsByProductUseCase(this._repository);

  final ProductVariantRepository _repository;

  Future<AppResult<List<ProductVariant>>> call({
    required String organizationId,
    required String productId,
  }) {
    return _repository.listByProduct(
      organizationId: organizationId.trim(),
      productId: productId.trim(),
    );
  }
}
