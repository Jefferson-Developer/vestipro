import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../entities/size_grid_template.dart';
import '../repositories/product_repository.dart';
import '../repositories/size_grid_template_repository.dart';
import '../value_objects/product_sync_status.dart';

@injectable
final class AssociateProductSizeGridTemplateUseCase {
  const AssociateProductSizeGridTemplateUseCase(
    this._productRepository,
    this._templateRepository,
  );

  final ProductRepository _productRepository;
  final SizeGridTemplateRepository _templateRepository;

  Future<AppResult<Product>> call({
    required String organizationId,
    required String productId,
    String? sizeGridTemplateId,
    required String updatedBy,
  }) async {
    final normalizedTemplateId = sizeGridTemplateId?.trim();
    if (normalizedTemplateId != null && normalizedTemplateId.isNotEmpty) {
      final templateResult = await _templateRepository.getById(
        organizationId: organizationId,
        id: normalizedTemplateId,
      );
      if (templateResult is AppFailure<SizeGridTemplate>) {
        return const AppFailure<Product>(
          ValidationFailure(
            'Invalid product size grid template association.',
            fieldErrors: <String, String>{
              'sizeGridTemplateId':
                  'Selecione apenas templates da organização ativa.',
            },
            code: 'invalid_product_size_grid_template_association',
          ),
        );
      }
    }

    final productResult = await _productRepository.getById(
      organizationId: organizationId,
      id: productId,
    );
    if (productResult is AppFailure<Product>) return productResult;
    final product = (productResult as AppSuccess<Product>).value;
    final updated = product.copyWith(
      sizeGridTemplateId:
          normalizedTemplateId == null || normalizedTemplateId.isEmpty
          ? null
          : normalizedTemplateId,
      updatedAt: DateTime.now().toUtc(),
      updatedBy: updatedBy.trim(),
      version: product.version + 1,
      syncStatus: ProductSyncStatus.pending,
    );
    return _productRepository.update(product: updated);
  }
}
