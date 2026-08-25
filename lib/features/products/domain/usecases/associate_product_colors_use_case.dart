import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../repositories/product_color_repository.dart';
import '../repositories/product_repository.dart';
import '../value_objects/product_sync_status.dart';

@injectable
final class AssociateProductColorsUseCase {
  const AssociateProductColorsUseCase(
    this._productRepository,
    this._colorRepository,
  );

  final ProductRepository _productRepository;
  final ProductColorRepository _colorRepository;

  Future<AppResult<Product>> call({
    required String organizationId,
    required String productId,
    required List<String> colorIds,
    required String updatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final normalizedColorIds = colorIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    for (final colorId in normalizedColorIds) {
      final colorResult = await _colorRepository.getById(
        organizationId: trimmedOrganizationId,
        id: colorId,
      );
      if (colorResult is AppFailure) {
        return AppFailure<Product>(
          ValidationFailure(
            'Invalid product color association.',
            code: 'invalid_product_color_association',
            fieldErrors: const <String, String>{
              'colorIds': 'Selecione apenas cores da organização ativa.',
            },
            cause: colorId,
          ),
        );
      }
    }

    final productResult = await _productRepository.getById(
      organizationId: trimmedOrganizationId,
      id: productId.trim(),
    );
    if (productResult is AppFailure<Product>) return productResult;
    final product = (productResult as AppSuccess<Product>).value;
    final updated = product.copyWith(
      colorIds: normalizedColorIds,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: updatedBy.trim(),
      version: product.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );
    return _productRepository.update(product: updated);
  }
}
