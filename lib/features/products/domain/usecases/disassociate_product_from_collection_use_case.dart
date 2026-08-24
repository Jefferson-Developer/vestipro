import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/product_collection_link_repository.dart';

/// Removes the association between a Product and a `Collection` (TASK-066).
/// Never touches the Product or the Collection themselves.
@injectable
final class DisassociateProductFromCollectionUseCase {
  DisassociateProductFromCollectionUseCase(this._repository);

  final ProductCollectionLinkRepository _repository;

  Future<AppResult<bool>> call({
    required String organizationId,
    required String productId,
    required String collectionId,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedProductId = productId.trim();
    final trimmedCollectionId = collectionId.trim();

    if (trimmedOrganizationId.isEmpty ||
        trimmedProductId.isEmpty ||
        trimmedCollectionId.isEmpty) {
      return Future<AppResult<bool>>.value(
        const AppFailure<bool>(
          ValidationFailure(
            'Invalid product-collection disassociation payload.',
            code: 'invalid_product_collection_unlink_payload',
          ),
        ),
      );
    }

    return _repository.deleteByProductAndCollection(
      organizationId: trimmedOrganizationId,
      productId: trimmedProductId,
      collectionId: trimmedCollectionId,
    );
  }
}
